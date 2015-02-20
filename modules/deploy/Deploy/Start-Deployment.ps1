<#
The MIT License (MIT)

Copyright (c) 2015 Objectivity Bespoke Software Specialists

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

function Start-Deployment {
    <#
    .SYNOPSIS
    Starts the actual deployment basing on the configuration files. This is an entry point for the project-specific deployment script.

    .DESCRIPTION
    It does the following steps:
    1. Loads configuration files containing environments and tokens to global variable $Environments.
    2. Creates a deployment plan basing on $Environments and parameters passed to this function. 
       Each node gets its own resolved tokens. The deployment plan can be accessed by querying $Global:DeploymentPlan variable.
    3. Runs the deployment plan by deploying configurations node by node.

    .PARAMETER Environment
    Name of the environment where the packages will be deployed.

    .PARAMETER DeployConfigurationPath
    Path to the configuration files which contain the tokens and server roles. 
    If not set, path '$PackagesPath\DeployScripts\configuration' will be used as a convention.

    .PARAMETER ServerRolesToDeploy
    List of ServerRoles to deploy - can be used if you don't want to deploy all server roles defined in the configuration files.
    If not set, all server roles will be deployed.

    .PARAMETER ConfigurationsFilter
    List of Configurations to deploy - can be used if you don't want to deploy all configurations defined in the configuration files.
    If not set, configurations will be deployed according to the ServerRoles defined in the configuration files.

    .PARAMETER NodesFilter
    List of Nodes where configurations have to be deployed - can be used if you don't want to deploy to all nodes defined in the configuration files.
    If not set, configurations will be deployed to all nodes according to the ServerRoles defined in the configuration files.

    .PARAMETER ValidateOnly
    If set, configuration files will be loaded and deployment plan created, but no actual deployment will run.
    You can use it to validate global hashtables $Tokens, $ServerRoles and $DeploymentPlan.

    .PARAMETER AutoInstallDscResources
    If true (default), custom DSC resources included in PSCI will be automatically copied to localhost (required for parsing DSC configurations)
    and to the destination servers (required for running DSC configurations).

    .PARAMETER DscForce
    If true (default), '-Force' parameter will be passed to 'Start-DscConfiguration'. It is required e.g. when last attempt failed and is still running.

    .PARAMETER TokensOverride
    A list of tokens to override. Token defined in the configuration files will be overrided with values specified in this array 
    (tokens will be matched by name, ignoring categories).

    .PARAMETER DeployType
    Deployment type:
    All       - deploy everything according to configuration files (= Provision + Deploy)
    Provision - deploy only DSC configurations
    Deploy    - deploy only non-DSC configurations
    Adhoc     - override configurations and nodes with $ConfigurationsFilter and $NodesFilter (they don't have to be defined in ServerRoles - useful for adhoc deployments)

    .EXAMPLE
    Start-Deployment -Environment $Environment -TokensOverride $TokensOverride

    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]
        $Environment,

        [Parameter(Mandatory=$false)]
        [string]
        $DeployConfigurationPath,

        [Parameter(Mandatory=$false)]
        [string[]]
        $ServerRolesToDeploy,

        [Parameter(Mandatory=$false)]
        [string[]]
        $ConfigurationsFilter,

        [Parameter(Mandatory=$false)]
        [string[]]
        $NodesFilter,

        [Parameter(Mandatory=$false)]
        [switch]
        $ValidateOnly,

        [Parameter(Mandatory=$false)]
        [switch]
        $AutoInstallDscResources = $true,

        [Parameter(Mandatory=$false)]
        [switch]
        $DscForce = $true,

        [Parameter(Mandatory=$false)]
        [hashtable]
        $TokensOverride,

        [Parameter(Mandatory=$false)]
        [ValidateSet('All', 'Provision', 'Deploy', 'Adhoc')]
        [string]
        $DeployType = 'All'
     )  

    if (!$PSCIGlobalConfiguration.RemotingMode) {
        Write-ProgressExternal -Message ("Starting deployment to env {0}" -f ($Environment -join ',')) -ErrorMessage "Deployment init error"
    }
    $configPaths = Get-ConfigurationPaths
    $packagesPath = $configPaths.PackagesPath

    $DeployConfigurationPath = Resolve-PathRelativeToProjectRoot `
                             -Path $DeployConfigurationPath `
                             -DefaultPath (Join-Path -Path $packagesPath -ChildPath "DeployScripts\configuration"), (Join-Path -Path $packagesPath -ChildPath "configuration")

    Write-Log -Info ("Starting deployment to environment '{0}' using package at '$packagesPath' and configuration at '$DeployConfigurationPath'" -f ($Environment -join ',')) -Emphasize

    Write-Log -Info "[START] PARSE CONFIG FILES" -Emphasize
    $configInfo = Read-ConfigurationFiles -Path $DeployConfigurationPath

    # need to install DSC resources locally in order to be able to parse configurations
    if ($AutoInstallDscResources) {
        Install-DscResources -ModuleNames $configInfo.RequiredDSCModules
    }

    # Clear global variables before including configuration files
    Initialize-Deployment
    
    # We need to include the configuration files in this function. We can't do it in separate Import-Configuration cmdlet, due to scoping issues (see http://stackoverflow.com/questions/15187510/dot-sourcing-functions-from-file-to-global-scope-inside-of-function)... 
    foreach ($configScript in $configInfo.Files) {
        Write-Log -Info "Including file $configScript"
        . $configScript 
    }
    # here $Global:Environments should be populated
    
    Write-Log -Info "[END] PARSE CONFIG FILES" -Emphasize
    Write-Log -Info "[START] BUILD DEPLOYMENT PLAN" -Emphasize

    $dscOutputPath = Join-Path -Path $packagesPath -ChildPath "_DscOutput"
    $Global:DeploymentPlan = New-DeploymentPlan -AllEnvironments $Global:Environments -Environment $Environment -ServerRolesFilter $ServerRolesToDeploy `
                                                -ConfigurationsFilter $ConfigurationsFilter -NodesFilter $NodesFilter -TokensOverride $TokensOverride `
                                                -DscOutputPath $dscOutputPath -DeployType $DeployType

    Write-Log -Info 'Variable $Global:DeploymentPlan has been created.' -Emphasize
    Write-Log -Info "[END] BUILD DEPLOYMENT PLAN" -Emphasize
    if (!$Global:DeploymentPlan) {
        Write-Log -Warn "No configurations to deploy anywhere. Please ensure your ServerRoles are properly defined and the ServerRoles / Configurations / Nodes filters are correct."
        return
    }

    if (!$ValidateOnly) {
        # When 'DeployScripts' and 'PSCI' directories are not found in the package, and there is at least one RunOn/RunRemotely in deployment plan,
        # we need to create a temporary package and copy configuration files to 'DeployScripts' and PSCI to PSCI.
        if (!$PSCIGlobalConfiguration.RemotingMode -and ($DeploymentPlan | Where { $_.RunOnConnectionParams })) {
            Build-TemporaryPackage
        }
        Start-DeploymentPlan -DeploymentPlan $Global:DeploymentPlan -DscForce:$DscForce -DeployType $DeployType -AutoInstallDscResources:$AutoInstallDscResources -DscModuleNames $configInfo.RequiredDSCModules
    }

    # if running remotely, return a string to let know that everything went ok (checked in Start-DeploymentByPSRemoting)
    if ($PSCIGlobalConfiguration.RemotingMode) {
        return "success"
    } else {
        Write-ProgressExternal -Message 'Deployment successful' -ErrorMessage ''
    }
}
