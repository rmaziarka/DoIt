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

<#
.SYNOPSIS
Starts the build process. 

.DESCRIPTION
It imports PSCI library and packages projects according to the commands in the 'try' block. The packages will be stored at $PackagesPath.

.PARAMETER ProjectRootPath
Base directory of the project, relative to the directory where this script resides. It is used as a base directory for other directories.
  
.PARAMETER PSCILibraryPath
Base directory where PSCI library resides, relative to $ProjectRootPath.

.PARAMETER PackagesPath
Path to the directory where packages will be created, relative to $ProjectRootPath.

.PARAMETER Version
Version number of the current build.
#>

param(
	[Parameter(Mandatory=$false)]
	[string]
	$ProjectRootPath = "..", # Modify this pa4th according to your project structure. This is relative to the directory where build.ps1 resides ($PSScriptRoot).
	
	[Parameter(Mandatory=$false)]
	[string]
	$PSCILibraryPath = "..\..", # Modify this path according to your project structure. This is absolute or relative to $ProjectRootPath.

	[Parameter(Mandatory=$false)]
	[string]
	$PackagesPath = "bin", # Modify this path according to your project structure. This is absolute or relative to $ProjectRootPath.

    [Parameter(Mandatory=$false)]
	[string]
	$Version = '1.0.0'
)

$global:ErrorActionPreference = "Stop"

if (![System.IO.Path]::IsPathRooted($ProjectRootPath)) {
    $ProjectRootPath = Join-Path -Path $PSScriptRoot -ChildPath $ProjectRootPath
}
if (![System.IO.Path]::IsPathRooted($PSCILibraryPath)) {
	$PSCILibraryPath = Join-Path -Path $ProjectRootPath -ChildPath $PSCILibraryPath
}

if (!(Test-Path "$PSCILibraryPath\PSCI.psm1")) {
    Write-Output -InputObject "Cannot find PSCI library at '$PSCILibraryPath'. Please ensure your ProjectRootPath and PSCILibraryPath parameters are correct."
	exit 1
}

Import-Module "$PSCILibraryPath\PSCI.psm1" -Force 

$PSCIGlobalConfiguration.LogFile = "$PSScriptRoot\build.log.txt"
Remove-Item -Path $PSCIGlobalConfiguration.LogFile -ErrorAction SilentlyContinue

try {
    # This will set paths that will be used in all Build-* cmdlets
    Initialize-ConfigurationPaths -ProjectRootPath $ProjectRootPath -PackagesPath $PackagesPath -PSCILibraryPath $PSCILibraryPath
	
    Remove-PackagesDir

    Build-DeploymentScriptsPackage -DeployScriptsPath $PSScriptRoot

    Build-DBDeployPackage -PackageName 'DBDeploy' -DBDeployPath 'database\dbdeploy'

    Build-SqlScriptsPackage -PackageName 'DatabaseCleanup' -ScriptsPath 'database\cleanup'
    Build-SqlScriptsPackage -PackageName 'DatabaseUpdate' -ScriptsPath 'database\changes'
	
    Write-Log -Info "Build finished successfully." -Emphasize
} catch {
    Write-ErrorRecord -ErrorRecord $_
}
