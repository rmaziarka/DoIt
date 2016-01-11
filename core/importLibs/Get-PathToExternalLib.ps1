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

function Get-PathToExternalLib {
    <#
    .SYNOPSIS
    Gets path to an external library from externalLibs folder.
    
    .PARAMETER ModulePath
    Path to the module to import. This is relative to 'externalLibs' directory.

    .EXAMPLE
    Get-PathToExternalLib -ModulePath "Carbon"
    #>

    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory=$false)]
        [string]
        $ModulePath
    ) 

    $DoItPath = Get-DoItModulePath
    $result = Join-Path -Path $DoItPath -ChildPath "externalLibs"
    if ($ModulePath) {
        $result = Join-Path -Path $result -ChildPath $ModulePath
    }
    if (!(Test-Path -LiteralPath $result)) {
        throw "Cannot find external library at '$result'. It is required for this part of DoIt to run."
    }
    return ((Resolve-Path -LiteralPath $result).ProviderPath)
}
