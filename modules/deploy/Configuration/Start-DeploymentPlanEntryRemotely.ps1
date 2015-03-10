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

function Start-DeploymentPlanEntryRemotely {
    <#
    .SYNOPSIS
    Runs the actual deployment basing on the deployment plan on a remote server.

    .PARAMETER DeploymentPlanGroupedEntry
    Deployment plan entry to deploy (grouped).

    .PARAMETER DeployType
    Deployment type:
    All       - deploy everything according to configuration files (= Provision + Deploy)
    DSC       - deploy only DSC configurations
    Functions - deploy only non-DSC configurations
    Adhoc     - override configurations and nodes with $ConfigurationsFilter and $NodesFilter (they don't have to be defined in ServerRoles - useful for adhoc deployments)

    .EXAMPLE
    Start-DeploymentPlanEntryRemotely -DeploymentPlan $Global:DeploymentPlan -Environment $Environment -CopyPackage
    
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $DeploymentPlanGroupedEntry,

        [Parameter(Mandatory=$false)]
        [ValidateSet('All', 'DSC', 'Functions', 'Adhoc')]
	    [string]
	    $DeployType = 'All'
    )    
 
    $configInfo = $DeploymentPlanGroupedEntry.GroupedConfigurationInfo
    $runOnConnectionParams = $configInfo[0].RunOnConnectionParams
    $packageDirectory = $configInfo[0].PackageDirectory
    $remotingMode = $runOnConnectionParams.RemotingMode

    # need to do it here (not in New-DeploymentPlanEntry), because we don't want to affect grouping
    if ($packageDirectory -ieq 'auto') {
        $packageDirectory = 'c:\PSCIPackage_{0}_{1}' -f (Get-Date -Format 'yyyyMMdd_HHmmss'), (([guid]::NewGuid()).Guid -split '-')[0]
        $packageDirectoryAutoRemove = $true
    }
    
    $params = 
        @{ 
            Environment = $configInfo.Environment | Select-Object -Unique
            ServerRole = $configInfo.ServerRole | Select-Object -Unique
            RunOnConnectionParams = $runOnConnectionParams
            PackageDirectory = $packageDirectory
            PackageDirectoryAutoRemove = $packageDirectoryAutoRemove
            RequiredPackages = $DeploymentPlanGroupedEntry.RequiredPackages
            DeployType = $DeployType
            ConfigurationsFilter = $configInfo.Name
            NodesFilter = $configInfo.ConnectionParams.Nodes | Select-Object -Unique
            TokensOverride = $DeploymentPlanGroupedEntry.TokensOverride
            CopyPackages = $true
        }
        
    $runOnNode = $runOnConnectionParams.Nodes[0]

    if ($runOnConnectionParams.Credential) {
        $userName = $runOnConnectionParams.Credential.UserName
    } else {
        $userName = ''
    }
    
    Write-Log -Info ("[START] RUN REMOTE CONFIGURATION(s) '{0}' / RUNON '{1}' / REMOTING '{2}' / AUTH '{3}' / CRED '{4}' / PROTOCOL '{5}'" -f `
        ($configInfo.Name -join "','"),
        $runOnNode, `
        $runOnConnectionParams.RemotingMode, `
        $runOnConnectionParams.Authentication, `
        $userName, `
        $runOnConnectionParams.Protocol) -Emphasize
    Write-ProgressExternal -Message ("Deploying remotely {0} to {1}" -f ($configInfo.Name -join ","), $runOnNode) `
        -ErrorMessage ('Deploy error - node {0}, conf {1}' -f $runOnNode, ($configInfo.Name -join ","))

    if ($remotingMode -eq 'WebDeployHandler' -or $remotingMode -eq 'WebDeployAgentService') {
        Start-DeploymentByMSDeploy @params
    } elseif ($remotingMode -eq 'PSRemoting') {
        Start-DeploymentByPSRemoting @params
    } else {
        Write-Log -Critical "Remoting Mode '$remotingMode' is not supported."
    }
    Write-Log -Info ("[END] RUN REMOTE CONFIGURATION '{0}' / RUNON '{1}'" -f ($configInfo.Name -join ","), $runOnNode) -Emphasize
    
}
