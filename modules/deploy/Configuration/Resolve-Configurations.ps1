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

function Resolve-Configurations {
    <#
    .SYNOPSIS
    Resolves Configurations inside ServerRole.

    .PARAMETER Environment
    Name of the environment where the packages will be deployed.

    .PARAMETER Configurations
    List of configuration names to resolve.

    .PARAMETER ConfigurationsFilter
    List of Configurations to deploy - can be used if you don't want to deploy all configurations defined in the configuration files.
    If not set, configurations will be deployed according to the ServerRoles defined in the configuration files.

    .PARAMETER ConfigurationsSettings
    Hashtable containing all ConfigurationsSettings.

    .PARAMETER DeployType
    Deployment type:
    All       - deploy everything according to configuration files (= Provision + Deploy)
    DSC       - deploy only DSC configurations
    Functions - deploy only non-DSC configurations
    Adhoc     - override configurations and nodes with $ConfigurationsFilter and $NodesFilter (they don't have to be defined in ServerRoles - useful for adhoc deployments)

    .PARAMETER ServerRole
    ServerRole containing the configurations to resolve.

    .PARAMETER ResolvedTokens
    Resolved tokens.

    .EXAMPLE
    Resolve-Configurations -Environment $Environment -Configurations $serverRole.Configurations -ConfigurationsFilter $ConfigurationsFilter `
                                        -DeployType $DeployType -ServerRoleName $serverRole.Name
    #>

    [CmdletBinding()]
    [OutputType([object[]])]
    param(

        [Parameter(Mandatory=$true)]
        [string]
        $Environment,

        [Parameter(Mandatory=$false)]
        [object]
        $Configurations,

        [Parameter(Mandatory=$false)]
        [string[]]
        $ConfigurationsFilter,

        [Parameter(Mandatory=$false)]
        [hashtable]
        $ConfigurationsSettings,

        [Parameter(Mandatory=$false)]
        [ValidateSet('All', 'DSC', 'Functions', 'Adhoc')]
	    [string]
	    $DeployType = 'All',

        [Parameter(Mandatory=$false)]
        [hashtable]
        $ServerRole,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $ResolvedTokens
    )

    if ($DeployType -eq 'Adhoc') {
        # in adhoc deployment Configurations are overriden directly from filters
        $Configurations = $ConfigurationsFilter
    } else {
        $Configurations = Resolve-ScriptedToken -ScriptedToken $Configurations -ResolvedTokens $ResolvedTokens -Environment $Environment
        # remove configurations not matching ConfigurationsFilter
        if ($ConfigurationsFilter) {
            $Configurations = $Configurations | Where-Object { $ConfigurationsFilter -icontains $_ }
        }
    }    

    $result = @()
    foreach ($configName in $Configurations) {
        $cmd = Get-Command -Name $configName -ErrorAction SilentlyContinue
        if (!$cmd) {
            Write-Log -Critical "Invalid Configuration reference ('$configName') - Environment '$Environment' / ServerRole '$($ServerRole.Name)'."
        }
        if ($cmd.CommandType -eq 'Configuration') {
            if ($DeployType -eq 'Functions') {
                continue
            }
        } elseif ($cmd.CommandType -eq 'Function') {
            if ($DeployType -eq 'DSC') {
                continue
            }
        } else {
            Write-Log -Critical "Command '$configName' is of unrecognized type ('$($cmd.CommandType)') - neither 'Configuration' nor 'Function'."
        }

        $configSettings = $ConfigurationsSettings[$configName]

        $configObject = [PSCustomObject]@{
            Name = $configName
            Type = $cmd.CommandType
            RequiredPackages = if ($configSettings -and $configSettings.ContainsKey('RequiredPackages')) { $configSettings.RequiredPackages } else { $ServerRole.RequiredPackages }
            RunRemotely = if ($configSettings -and $configSettings.ContainsKey('RunRemotely')) { $configSettings.RunRemotely } else { $ServerRole.RunRemotely }
            RunOn = if ($configSettings -and $configSettings.ContainsKey('RunOn')) { $configSettings.RunOn } else { $ServerRole.RunOn }
            RebootHandlingMode = if ($configSettings -and $configSettings.ContainsKey('RebootHandlingMode')) { $configSettings.RebootHandlingMode } else { $ServerRole.RebootHandlingMode }
        }

        $result += $configObject

    }

    return ,($result)

}