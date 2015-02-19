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

    .PARAMETER DeploymentPlanEntry
    Deployment plan entry to deploy.

    .PARAMETER PackageCopiedToNodes
    Defines array with node names where the package was already copied to.

    .PARAMETER DeployType
    Deployment type:
    All       - deploy everything according to configuration files (= Provision + Deploy)
    Provision - deploy only DSC configurations
    Deploy    - deploy only non-DSC configurations
    Adhoc     - override configurations and nodes with $ConfigurationsFilter and $NodesFilter (they don't have to be defined in ServerRoles - useful for adhoc deployments)

    .EXAMPLE
    Start-DeploymentPlanEntryRemotely -DeploymentPlan $Global:DeploymentPlan -Environment $Environment -CopyPackage
    
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $DeploymentPlanEntry,

        [Parameter(Mandatory=$true)]
        [ref]
        $PackageCopiedToNodes,

        [Parameter(Mandatory=$false)]
        [ValidateSet('All', 'Provision', 'Deploy', 'Adhoc')]
	    [string]
	    $DeployType = 'All'
    )    
 
    $params = 
        @{ 
            Environment = $deploymentPlanEntry.Environment;
            ServerRole = $deploymentPlanEntry.ServerRole;
            ConnectionParams = $deploymentPlanEntry.RunOnConnectionParams;
            CopyTo = $deploymentPlanEntry.PackageDirectory;
            DeployType = $DeployType;
            ConfigurationsFilter = $deploymentPlanEntry.ConfigurationName;
            NodesFilter = $deploymentPlanEntry.ConnectionParams.Nodes
            TokensOverride = $deploymentPlanEntry.TokensOverride
        }
        
    $node = $deploymentPlanEntry.RunOnConnectionParams.Nodes[0]
    if ($PackageCopiedToNodes.Value -notcontains $node) {
        $PackageCopiedToNodes.Value += @($node)
        $params.Add("CopyPackage", $true)
    }

    if (($deploymentPlanEntry.RunOnConnectionParams.RemotingMode -eq "WebDeployHandler") -or ($deploymentPlanEntry.RunOnConnectionParams.RemotingMode -eq "WebDeployAgentService")) {
        Start-DeploymentByMSDeploy @params
    } elseif ($deploymentPlanEntry.RunOnConnectionParams.RemotingMode -eq "PSRemoting") {
        Start-DeploymentByPSRemoting @params
    } else {
        Write-Log -Critical "Remoting Mode '$($deploymentPlanEntry.RunOnConnectionParams.RemotingMode)' is not supported."
    }
    
}
