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

function Start-DeploymentPlan {
    <#
    .SYNOPSIS
    Runs the actual deployment basing on the deployment plan.

    .DESCRIPTION
    It iterates through the deployment plan and it either runs 'Start-DscConfiguration' or the specified function for each entry.

    .PARAMETER DeploymentPlan
    Deployment plan which defines the deployment.

    .PARAMETER DscForce
    If true, '-Force' parameter will be passed to 'Start-DscConfiguration'. It is required e.g. when last attempt failed and is still running.

    .PARAMETER DeployType
    Deployment type:
    All       - deploy everything according to configuration files (= Provision + Deploy)
    Provision - deploy only DSC configurations
    Deploy    - deploy only non-DSC configurations
    Adhoc     - override configurations and nodes with $ConfigurationsFilter and $NodesFilter (they don't have to be defined in ServerRoles - useful for adhoc deployments)

    .PARAMETER AutoInstallDscResources
    If true, custom DSC resources included in PSCI will be automatically copied to localhost (required for parsing DSC configurations)
    and to the destination servers (required for running DSC configurations).

    .PARAMETER DscModuleNames
    Dsc modules to install if AutoInstallDscResources is $true.

    .EXAMPLE
    Start-DeploymentPlan -DeploymentPlan $Global:DeploymentPlan -DeploymentMethod $DeployMethod -Environment $Environment -DscForce:$DscForce
    
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject[]]
        $DeploymentPlan,

        [Parameter(Mandatory=$true)]
        [switch]
        $DscForce,

        [Parameter(Mandatory=$false)]
        [ValidateSet('All', 'Provision', 'Deploy', 'Adhoc')]
	    [string]
	    $DeployType = 'All',

        [Parameter(Mandatory=$false)]
        [switch]
        $AutoInstallDscResources = $true,

        [Parameter(Mandatory=$false)]
        [string[]]
        $DscModuleNames

    )

    if (!$PSCIGlobalConfiguration.RemotingMode) {
        Write-Log -Info '[START] ACTUAL DEPLOYMENT' -Emphasize
    }

    Write-Log -Info "Running following deployment plan with DeployType = ${DeployType}:"
    
    # Log information to console
    foreach ($entry in $DeploymentPlan) {
        if (!$entry.RunOnConnectionParams) {
            $remotingMode = ''
            $runOnNodes = 'localhost'
        } else {
            $remotingMode = '(' + $entry.RunOnConnectionParams.RemotingMode + ')'
            $runOnNodes = $entry.RunOnConnectionParams.NodesAsString
        }
        Write-Log -Info ('{0} -> {1}, RunOn = {2} {3}' -f $entry.ConfigurationName, $entry.ConnectionParams.NodesAsString, $runOnNodes, $remotingMode) -Emphasize
    }
    Write-Log -Info ' '
   
    # Install DSC resources where required - on nodes where DSC will be applied to different nodes (remotely)

    if (!$PSCIGlobalConfiguration.RemotingMode) { 

        if ($AutoInstallDSCResources) {
            $entriesToInstallDSC = $DeploymentPlan | Where-Object { $_.ConfigurationType -eq 'Configuration' -and !$_.IsLocalRun }
            if ($entriesToInstallDSC) {
                $dscInstalledNodes = @()
                Write-ProgressExternal -Message 'Installing DSC resources' -ErrorMessage 'DSC resources install error'
                Write-Log -Info '[START] INSTALL DSC RESOURCES' -Emphasize
                foreach ($entry in $entriesToInstallDSC) {
                    if ($dscInstalledNodes -notcontains $entry.ConnectionParams.Nodes[0]) {
                        # TODO: install only modules required for given configurations
                        Install-DscResources -ConnectionParams $entry[0].ConnectionParams -ModuleNames $DscModuleNames
                        $dscInstalledNodes += @($entry.ConnectionParams.Nodes[0])
                    }
                }
                Write-Log -Info '[END] INSTALL DSC RESOURCES' -Emphasize
            }
        }
        $planByRunOn = Group-DeploymentPlan -DeploymentPlan $DeploymentPlan -GroupByRunOnConnectionParamsAndPackage -PreserveOrder
    } else {
        # if RemotingMode, every entry is run locally and we ignore RunOnConnectionsParams
        $planByRunOn = Group-DeploymentPlan -DeploymentPlan $DeploymentPlan -PreserveOrder
    }  

    $packageCopiedToNodes = @()
    foreach ($entry in $planByRunOn) {
        if ($entry.RunOnConnectionParams -and !$PSCIGlobalConfiguration.RemotingMode) {   
            if ($entry.RunOnConnectionParams.Credential) {
                $userName = $entry.RunOnConnectionParams.Credential.UserName
            } else {
                $userName = ''
            }
            $nodes = $entry.RunOnConnectionParams.NodesAsString
            Write-Log -Info ("[START] RUN REMOTE CONFIGURATION '{0}' / RUNON '{1}' / REMOTING '{2}' / AUTH '{3}' / CRED '{4}' / PROTOCOL '{5}'" -f $entry.ConfigurationName, $nodes, $entry.RunOnConnectionParams.RemotingMode, $entry.RunOnConnectionParams.Authentication, $userName, $entry.RunOnConnectionParams.Protocol) -Emphasize
            Write-ProgressExternal -Message ('Deploying {0} to {1}' -f $entry.ConfigurationName, $nodes) -ErrorMessage ('Deploy error - node {0}, conf {1}' -f $nodes, $entry.ConfigurationName)
            Start-DeploymentPlanEntryRemotely -DeploymentPlanGroupedEntry $entry -DeployType $DeployType -PackageCopiedToNodes ([ref]$packageCopiedToNodes)
            Write-Log -Info ("[END] RUN REMOTE CONFIGURATION '{0}' / RUNON '{1}'" -f $entry.ConfigurationName, $nodes) -Emphasize
        } else {
            $nodes = $entry.ConnectionParams.NodesAsString
            Write-Log -Info ("[START] RUN LOCAL CONFIGURATION '{0}' / NODE '{1}'" -f $entry.ConfigurationName, $nodes) -Emphasize
            Write-ProgressExternal -Message ('Deploying {0} to {1}' -f $entry.ConfigurationName, $nodes) -ErrorMessage ('Deploy error - node {0}, conf {1}' -f $nodes, $entry.ConfigurationName)
            Start-DeploymentPlanEntryLocally -DeploymentPlanGroupedEntry $entry -DscForce:$DscForce
            Write-Log -Info ("[END] RUN LOCAL CONFIGURATION '{0}' / NODE '{1}'" -f $entry.ConfigurationName, $nodes) -Emphasize
        }
    }
    if (!$PSCIGlobalConfiguration.RemotingMode) {
        Write-Log -Info "[END] ACTUAL DEPLOYMENT" -Emphasize
    }
}
