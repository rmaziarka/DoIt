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

function Get-DoItBuildNumber {
    <#
    .SYNOPSIS
    Gets build number.

    .DESCRIPTION
    Gets build number of DoIt library, basing on 'build.x' file placed in the root directory of the library.

    .PARAMETER Path
    Path to the DoIt directory. If not specified, $PSScriptRoot will be used.

    .EXAMPLE
    Get-DoItBuildNumber
    #>    

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$false)]
        [string] 
        $Path
    )

    if (!$Path) {
        $Path = Get-DoItModulePath
    }
    $buildFile = Get-ChildItem -Path $Path -Filter "build.*" -File | Select-Object -ExpandProperty Name
    if (!$buildFile) {
        throw "No build version file at '$Path'. DoIt library has not been packaged properly."
    }
    if (@($buildFile).Length -ne 1) {
        throw "More than one DoIt build version file found at '$Path'. DoIt library has not been packaged properly. If this is TeamCity run, please ensure you're clearing all files in the checkout directory before the build (in 'Version Control Settings' / advanced options)."
    }
    if (!($buildFile -match "build.(\w+)$")) {
        throw "Invalid build version filename: '$buildFile' - should match 'build.local' or 'build.<number>'. DoIt library has not been packaged properly."
    }
    return $Matches[1]
}