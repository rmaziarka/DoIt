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

.PARAMETER DeployConfigurationPath
Path to the directory where configuration files reside, relative to $ProjectRootPath. By default '<script directory>\configuration'.

.PARAMETER Version
Version number of the current build.
#>

param(
	[Parameter(Mandatory=$false)]
	[string]
	$ProjectRootPath = '..', # Modify this path according to your project structure. This is relative to the directory where build.ps1 resides ($PSScriptRoot).
	
	[Parameter(Mandatory=$false)]
	[string]
	$PSCILibraryPath = '..\..', # Modify this path according to your project structure. This is absolute or relative to $ProjectRootPath.

	[Parameter(Mandatory=$false)]
	[string]
	$PackagesPath = 'bin', # Modify this path according to your project structure. This is absolute or relative to $ProjectRootPath.

    [Parameter(Mandatory=$false)]
	[string]
	$DeployConfigurationPath = '', # Modify this path according to your project structure. This is absolute or relative to $ProjectRootPath (by default '<script directory>\configuration').

    [Parameter(Mandatory=$false)]
	[string]
	$Version = '1.0.0' # This should be passed from your CI server
)

$global:ErrorActionPreference = 'Stop'

try { 
    ############# Initialization
    Push-Location -Path $PSScriptRoot
    if (![System.IO.Path]::IsPathRooted($PSCILibraryPath)) {
    	$PSCILibraryPath = Join-Path -Path $ProjectRootPath -ChildPath $PSCILibraryPath
    }
    if (!(Test-Path "$PSCILibraryPath\PSCI.psm1")) {
        Write-Output -InputObject "Cannot find PSCI library at '$PSCILibraryPath'. Please ensure your ProjectRootPath and PSCILibraryPath parameters are correct."
    	exit 1
    }
    Import-Module "$PSCILibraryPath\PSCI.psm1" -Force 

    $PSCIGlobalConfiguration.LogFile = 'build.log.txt'
    Remove-Item -Path $PSCIGlobalConfiguration.LogFile -ErrorAction SilentlyContinue

    Initialize-ConfigurationPaths -ProjectRootPath $ProjectRootPath -PackagesPath $PackagesPath -DeployConfigurationPath $DeployConfigurationPath
    Remove-PackagesDir

    ############# Actual build steps are in build\buildPackage.ps1.
    ############# Feel free to add additional parameters to build.ps1 and buildPackage.ps1.

    $buildPackageScript = Resolve-Path -Path 'build\buildPackage.ps1'
    Write-Log -Info "Running $buildPackageScript" -Emphasize
    . $buildPackageScript -Version $Version
    Write-Log -Info 'Build finished successfully.' -Emphasize
} catch {
    Write-ErrorRecord -ErrorRecord $_
} finally {
    Pop-Location
}
