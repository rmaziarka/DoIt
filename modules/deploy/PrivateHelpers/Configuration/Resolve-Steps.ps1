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

function Resolve-Steps {
    <#
    .SYNOPSIS
    Resolves Steps inside ServerRole.

    .PARAMETER Environment
    Name of the environment where the packages will be deployed.

    .PARAMETER Steps
    List of steps to resolve.

    .PARAMETER StepsFilter
    List of Steps to deploy - can be used if you don't want to deploy all configurations defined in the configuration files.
    If not set, steps will be deployed according to the ServerRoles defined in the configuration files.

    .PARAMETER StepsSettings
    Hashtable containing all StepsSettings.

    .PARAMETER DeployType
    Deployment type:
    All       - deploy everything according to configuration files (= Provision + Deploy)
    DSC       - deploy only DSC configurations
    Functions - deploy only Powershell functions
    Adhoc     - override steps and nodes with $StepsFilter and $NodesFilter (they don't have to be defined in ServerRoles - useful for adhoc deployments)

    .PARAMETER ServerRole
    ServerRole containing the steps to resolve.

    .PARAMETER ResolvedTokens
    Resolved tokens.

    .EXAMPLE
    Resolve-Steps -Environment $Environment -Steps $serverRole.Steps -StepsFilter $StepsFilter `
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
        $Steps,

        [Parameter(Mandatory=$false)]
        [string[]]
        $StepsFilter,

        [Parameter(Mandatory=$false)]
        [hashtable]
        $StepsSettings,

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
        # in adhoc deployment steps are overriden directly from filters
        $Steps = $StepsFilter
    } else {
        $Steps = Resolve-ScriptedToken -ScriptedToken $Steps -ResolvedTokens $ResolvedTokens -Environment $Environment
        # remove steps not matching StepsFilter
        if ($StepsFilter) {
            $Steps = $Steps | Where-Object { $StepsFilter -icontains $_ }
        }
    }    

    $result = @()
    foreach ($stepName in $Steps) {
        

        $stepSettings = $StepsSettings[$stepName]

        $stepObject = [PSCustomObject]@{
            Name = $stepName
            RequiredPackages = if ($stepSettings -and $stepSettings.ContainsKey('RequiredPackages')) { $stepSettings.RequiredPackages } else { $ServerRole.RequiredPackages }
            RunRemotely = if ($stepSettings -and $stepSettings.ContainsKey('RunRemotely')) { $stepSettings.RunRemotely } else { $ServerRole.RunRemotely }
            RunOn = if ($stepSettings -and $stepSettings.ContainsKey('RunOn')) { $stepSettings.RunOn } else { $ServerRole.RunOn }
            RebootHandlingMode = if ($stepSettings -and $stepSettings.ContainsKey('RebootHandlingMode')) { $stepSettings.RebootHandlingMode } else { $ServerRole.RebootHandlingMode }
        }

        $result += $stepObject

    }

    return ,($result)

}