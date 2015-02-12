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

function Resolve-ServerRoles {
    <#
    .SYNOPSIS
    Resolves a hashtable containing ServerRoles for given environment.

    .DESCRIPTION
    It reads global Environments hashtable, e.g.:

    $Environments = @{ 
        Default = @{
            ServerRoles = @{
               Name1 = @{
                    Configurations = @('WebServerProvision', 'WebServerDeploy')
                    Nodes = $null
               }
               Name2 = ...
            }
        }
        Dev = @{
            ServerRoles = @{
                Name1 = @{
                    Configurations = @('WebServerProvision', 'WebServerDeploy')
                    Nodes = 'node1'
               }
            }
        }
	}

    And creates following structure:

    $ServerRoles = @{ 
        Name1 = @{ 
            Configurations = @('WebServerProvision', 'WebServerDeploy') 
            Nodes = 'node1' 
        }
		Name2 = ...
    }
   
    .PARAMETER AllEnvironments
    Hashtable containing all environment definitions.

    .PARAMETER Environment
    Name of the environment which the ServerRoles should be resolved for.

    .PARAMETER ServerRolesFilter
    Filter for server roles - can be used if you don't want to deploy all server roles defined in the configuration files.

    .EXAMPLE
    $serverRoles = Resolve-ServerRoles -AllEnvironments $AllEnvironments -Environment $Environment

    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]
        $AllEnvironments,

        [Parameter(Mandatory=$true)]
        [string]
        $Environment,

        [Parameter(Mandatory=$false)]
        [string[]]
        $ServerRolesFilter
    )

    $envHierarchy = @(Resolve-EnvironmentHierarchy -AllEnvironments $AllEnvironments -Environment $Environment)

    $result = [ordered]@{}

    # traverse environments from top to bottom to set / override their properties
    foreach ($env in $envHierarchy) {
        $serverRoles = $AllEnvironments[$env].ServerRoles.Values | Where-Object { !$ServerRolesFilter -or $ServerRolesFilter -icontains $_.Name }
        foreach ($serverRole in $serverRoles) {
            if (!$result.Contains($serverRole.Name)) {
                $result[$serverRole.Name] = @{}
            }
            foreach ($entry in $serverRole.GetEnumerator()) {
                $result[$serverRole.Name][$entry.Key] = $entry.Value
            }
        }
    }

    # fix default values of ServerRoles
    foreach ($serverRole in $result.Values) {
        if (!$serverRole.RemotingMode) {
            $serverRole.RemotingMode = 'PSRemoting'
        }
    }

    return $result
}