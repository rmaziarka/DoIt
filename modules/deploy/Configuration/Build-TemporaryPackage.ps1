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

function Build-TemporaryPackage {
    <#
    .SYNOPSIS
    Creates a temporary package with 'DeployScripts' and 'PSCI'.

    .EXAMPLE
    Build-TemporaryPackage
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()

    $configPaths = Get-ConfigurationPaths
    if (!(Test-Path -Path (Join-Path -Path $configPaths.PackagesPath -ChildPath 'DeployScripts')) -and `
        !(Test-Path -Path (Join-Path -Path $configPaths.PackagesPath -ChildPath 'PSCI'))) {
        $packageTempDir = New-TempDirectory -DirName 'PSCI.tempPackage'
                                
        Write-Log -Info "'DeployScripts' and 'PSCI' directories have not been found in the package - creating temporary package."
        # When 'configuration' directory is present at PackagesPath, it means we don't have any package at all
        if (!(Test-Path -Path (Join-Path -Path $configPaths.PackagesPath -ChildPath 'configuration'))) {
            Copy-Item -Path "$($configPaths.PackagesPath)\*" -Recurse -Destination $packageTempDir
        }
        $configPaths.PackagesPath = $packageTempDir
        Build-DeploymentScriptsPackage -DeployScriptsPath '.'
    }

}