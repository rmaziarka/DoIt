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

function Resolve-ConfigurationsSettings {
    <#
    .SYNOPSIS
    Resolves ConfigurationSettings inside Environment.
            
    .PARAMETER AllEnvironments
    Hashtable containing all environment definitions.

    .PARAMETER Environment
    Name of the environment which the ServerRoles should be resolved for.

    .PARAMETER ConfigurationsFilter
    List of Configurations to deploy - can be used if you don't want to deploy all configurations defined in the configuration files.
    If not set, configurations will be deployed according to the ServerRoles defined in the configuration files.

    .EXAMPLE
    $configurationsSettings = Resolve-ConfigurationsSettings -AllEnvironments $AllEnvironments -Environment $Environment -ConfigurationsFilter $ConfigurationsFilter
    
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
        $ConfigurationsFilter
    )

    $envHierarchy = @(Resolve-BasedOnHierarchy -AllElements $AllEnvironments -SelectedElement $Environment -ConfigElementName 'Environment')

    $result = @{}

    # traverse environments from top to bottom to set / override ConfigurationSettings properties
    foreach ($env in $envHierarchy) {
        $configSettings = $AllEnvironments[$env].ConfigurationSettings.Values | Where-Object { !$ConfigurationsFilter -or $ConfigurationsFilter -icontains $_.Name }
        foreach ($configSetting in $configSettings) {
            if (!$result.Contains($configSetting.Name)) {
                $result[$configSetting.Name] = @{}
            }
            foreach ($entry in $configSetting.GetEnumerator()) {
                $result[$configSetting.Name][$entry.Key] = $entry.Value
            }
        }
    }

    return $result
}