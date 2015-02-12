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

function Initialize-ConfigurationPaths {
    <#
    .SYNOPSIS
    Validates, converts configuration paths to canonical form and saves them in a global variable $PSCIConfigurationPaths.

    .PARAMETER ProjectRootPath
    Path to the root project directory. This is used as a base directory, all other paths are relative to this path.

    .PARAMETER PackagesPath
    Base directory where packages reside.

    .PARAMETER PackagesPathMustExist
    If true and $PackagesPath does not exist, an error will be thrown.

    .PARAMETER PSCILibraryPath
    Root path of PSCI library.


    .EXAMPLE
    $configPaths = Initialize-ConfigurationPaths -ProjectRootPath $ProjectRootPath -PackagesPath $PackagesPath
    #>

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string] 
        $ProjectRootPath,
       
        [Parameter(Mandatory=$false)]
        [string] 
        $PackagesPath,

        [Parameter(Mandatory=$false)]
        [switch] 
        $PackagesPathMustExist,

        [Parameter(Mandatory=$true)]
	    [string]
	    $PSCILibraryPath
    )

    $configPaths = [PSCustomObject]@{
        ProjectRootPath = $null;
        PackagesPath = $null;
        ModulePath = $PSScriptRoot;
        PSCILibraryPath = $null;
    }
    if (!(Test-Path -Path $ProjectRootPath -PathType Container)) {
        Write-Log -Critical "Project root directory '$ProjectRootPath' does not exist. Please ensure you have passed valid 'ProjectRootPath' argument to Initialize-ConfigurationPaths."
    }
    $configPaths.ProjectRootPath = Resolve-Path -Path $ProjectRootPath

    $configPaths.PSCILibraryPath = Resolve-Path -Path $PSCILibraryPath

    if (!$PackagesPath) {
        $PackagesPath = $configPaths.ProjectRootPath
    } elseif (![System.IO.Path]::IsPathRooted($PackagesPath)) {
        $PackagesPath = Join-Path -Path ($configPaths.ProjectRootPath) -ChildPath $PackagesPath
    }
    

    if ((Test-Path -Path $PackagesPath -PathType Container)) {
        $configPaths.PackagesPath = Resolve-Path -Path $PackagesPath
    } else {
        if ($PackagesPathMustExist) {
            Write-Log -Critical "Packages directory '$PackagesPath' does not exist. Please ensure you have packages available in this location (possibly you need to run the build?)."
        }
        $configPaths.PackagesPath = $PackagesPath
    }

    $global:PSCIConfigurationPaths = $configPaths
}
