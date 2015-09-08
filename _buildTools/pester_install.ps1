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

$currentDir = Split-Path -parent $MyInvocation.MyCommand.Path
$pesterModuleDir = "$($env:USERPROFILE)\Documents\WindowsPowerShell\Modules\Pester"
$profileFile = "$($env:USERPROFILE)\Documents\WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1"

$copyToModules = Read-Host 'Install Pester to your Modules directory [y/n]?'
if ($copyToModules -ieq 'y') {
    if (!(Test-Path $pesterModuleDir)) {
        Write-Host "Creating directory '$pesterModuleDir'..." -NoNewline
        New-Item -Path $pesterModuleDir -ItemType Directory | Out-Null
        Write-Host "OK"
    }
    Write-Host "Unblocking Pester files..." -NoNewLine
    Get-ChildItem (Join-Path $currentDir "Pester") | Unblock-File
    Write-Host "OK"

    Write-Host "Copying Pester files to '$pesterModuleDir'..." -NoNewline
    Copy-Item -Path (Join-Path $currentDir "Pester\*") -Destination $pesterModuleDir -Recurse -Force
    Write-Host "OK"
}

Write-Host ""

$installToProfile = Read-Host 'Install Pester to ISE Profile (will start when ISE starts) [y/n]?'

if ($installToProfile -ieq 'y') {
    if (!(Test-Path $profileFile)) {
        Write-Host "Creating file '$profileFile'..." -NoNewline
        New-Item -Path $profileFile -ItemType file | Out-Null
        Write-Host "OK"
        $contents = ""
    } else {
        Write-Host "Reading file '$profileFile'..." -NoNewLine
        $contents = Get-Content -Path $profileFile | Out-String
        Write-Host "OK"
    }

    $importModule = "Import-Module Pester"

    if ($contents -inotmatch $importModule) {
        Write-Host "Adding '$importModule'..." -NoNewLine
        Add-Content -Path $profileFile -Value $importModule | Out-Null
        Write-Host "OK"
    } else {
        Write-Host "Import command for Pester already exists in profile file."
    }
}
