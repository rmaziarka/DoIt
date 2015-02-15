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

function New-DeploymentPlan {
    <#
    .SYNOPSIS
    Creates a deployment plan basing on global variables $Tokens, $ServerRoles and parameters passed to this function.

    .DESCRIPTION
    It iterates through resolved ServerRoles (created for given environment with Resolve-ServerRoles) and Configurations defined in each ServerRole,
    and creates a deployment plan entry for each of such configuration.
    If the configuration is a DSC configuration (as opposed to function), it will be run and MOF files will be created for each node.
    The deployment plan has a form of array of hashtables @( $hashTableForNode1, $hashTableForNode2, ...) where each hashTable has the following structure:

    Node = <name of the node>
    Tokens = <hashtable containing resolved tokens which will be used during the deployment> 
    RemotingCredential = <PSCredential object which will be passed to Start-DscConfiguration>
    Configurations = <list of hashtables containing information required to run DSC configurations or custom functions>

    Each of Configuration hashtable has the following structure:
        Type = (Configuration|Function)
        Name = <name of the Configuration or Function>
        MofDir = <path to the directory containing MOF files - used only when Type = Configuration>

    .PARAMETER AllEnvironments
    Hashtable containing all environment definitions.

    .PARAMETER Environment
    Name of the environment where the packages will be deployed.

    .PARAMETER ServerRolesFilter
    List of ServerRole names that should be included in the deployment plan.

    .PARAMETER ConfigurationsFilter
    List of Configurations to deploy - can be used if you don't want to deploy all configurations defined in the configuration files.
    If not set, configurations will be deployed according to the ServerRoles defined in the configuration files.

    .PARAMETER NodesFilter
    List of Nodes where configurations have to be deployed - can be used if you don't want to deploy to all nodes defined in the configuration files.
    If not set, configurations will be deployed to all nodes according to the ServerRoles defined in the configuration files.

    .PARAMETER TokensOverride
    A list of tokens to override. Token defined in the configuration files will be overrided with values specified in this array 
    (tokens will be matched by name, ignoring categories).

    .PARAMETER DscOutputPath
    Path where the .MOF files will be generated.

    .PARAMETER DeployType
    Deployment type:
    All       - deploy everything according to configuration files (= Provision + Deploy)
    Provision - deploy only DSC configurations
    Deploy    - deploy only non-DSC configurations
    Adhoc     - override configurations and nodes with $ConfigurationsFilter and $NodesFilter (they don't have to be defined in ServerRoles - useful for adhoc deployments)

    .LINK
    Resolve-ServerRoles

    .EXAMPLE
    $Global:DeploymentPlan = New-DeploymentPlan -AllEnvironments $AllEnvironments -Environment $Environment -ConfigurationsFilter $ConfigurationsFilter

    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]
        $AllEnvironments,

        [Parameter(Mandatory=$true)]
        [string[]]
        $Environment,

        [Parameter(Mandatory=$false)]
        [string[]]
        $ServerRolesFilter,

        [Parameter(Mandatory=$false)]
        [string[]]
        $ConfigurationsFilter,

        [Parameter(Mandatory=$false)]
        [string[]]
        $NodesFilter,

        [Parameter(Mandatory=$false)]
        [hashtable]
        $TokensOverride,

        [Parameter(Mandatory=$true)]
        [string]
        $DscOutputPath,

        [Parameter(Mandatory=$false)]
        [ValidateSet('All', 'Provision', 'Deploy', 'Adhoc')]
	    [string]
	    $DeployType = 'All'
    )

    $deploymentPlan = New-Object -TypeName System.Collections.ArrayList
    if ($TokensOverride) {
        $log = ($TokensOverride.GetEnumerator() | Foreach-Object { "$($_.Key)=$($_.Value)" }) -join ','
        Write-Log -Info "TokensOverride: $log"
    }

    if (Test-Path -Path $dscOutputPath) {
        [void](Remove-Item -Path $dscOutputPath -Force -Recurse)
    }

    foreach ($env in $Environment) {
        Write-Log -Info ("Processing environment '{0}', server roles filter '{1}', server connections filter '{2}', configurations filter '{3}', deploy type '{4}'" -f `
            $env, ($ServerRolesFilter -join ','), ($ServerConnectionsFilter -join ','), ($ConfigurationsFilter -join ','), $DeployType) -Emphasize

        $resolvedTokens = Resolve-Tokens -AllEnvironments $AllEnvironments -Environment $env -TokensOverride $TokensOverride
        
        $serverRoles = Resolve-ServerRoles `
            -AllEnvironments $AllEnvironments `
            -Environment $env `
            -ResolvedTokens $resolvedTokens `
            -ServerRolesFilter $ServerRolesFilter `
            -NodesFilter $NodesFilter `
            -ConfigurationsFilter $ConfigurationsFilter `
            -DeployType $deployType
                
        foreach ($serverRoleName in $serverRoles.Keys) {
            $serverRole = $serverRoles[$serverRoleName]
            foreach ($config in $serverRole.Configurations) {
                foreach ($serverConnection in $serverRole.ServerConnections) {
                    foreach ($node in $serverConnection.Nodes) {

                        $resolvedTokens = Resolve-Tokens -AllEnvironments $AllEnvironments -Environment $env -Node $node -TokensOverride $TokensOverride
                        $createDeploymentPlanEntryParams = @{ 
                            Environment = $env
                            ServerRole = $serverRole
                            ServerConnection = $serverConnection
                            Node = $node
                            Configuration = $config
                            DscOutputPath = $DscOutputPath
                            DeployType = $DeployType
                            ResolvedTokens = $resolvedTokens
                            TokensOverride = $TokensOverride
                        }
                
                        $planEntry = New-DeploymentPlanEntry @createDeploymentPlanEntryParams
                        if ($planEntry) {
                            [void]($deploymentPlan.Add($planEntry))
                        }
                    }
                }
            }
        }
    }
    return ,($deploymentPlan.ToArray())
}