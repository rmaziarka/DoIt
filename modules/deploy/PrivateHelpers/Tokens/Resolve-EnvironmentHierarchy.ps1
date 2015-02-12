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

function Resolve-EnvironmentHierarchy { 
    <#
    .SYNOPSIS
    Returns an array of environments from which given environment inherits

    .PARAMETER AllEnvironments
    Hashtable containing all environments.

    .PARAMETER Environment
    Environment to resolve.

    .EXAMPLE
    Resolve-EnvironmentHierarchy -AllEnvironments $AllEnvironments -Environment Local
    #>

    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]
        $AllEnvironments,

        [Parameter(Mandatory=$true)]
        [string]
        $Environment
    )   

    if (!$AllEnvironments.ContainsKey($environment)) {
        Write-Log -Critical "Environment '$Environment' is not defined."
    }

    # given environment is the top of hierarchy
    $result = @($Environment)

    # add all parents
    $curEnv = $AllEnvironments[$Environment]
    while ($curEnv.BasedOn) {
        $basedOn = $curEnv.BasedOn
        if (!$AllEnvironments.ContainsKey($basedOn)) {
            if ($basedOn -eq 'Default') {
                $curEnv.BasedOn = ''
                break
            } else {
                Write-Log -Critical "Environment '$Environment' has invalid 'BasedOn' argument ('$basedOn'). Environment '$basedOn' does not exist."
            }
        } else {
            if ($result.Contains($basedOn)) {
                Write-Log -Critical "Inheritance cycle found - environment '$Environment'."
            }
            # SuppressScriptCop - adding small arrays is ok
            $result += $basedOn

        }
        $curEnv = $AllEnvironments[$basedOn]
    }

    # reverse to let iterate from Default to given
    [array]::Reverse($result)

    return $result
}