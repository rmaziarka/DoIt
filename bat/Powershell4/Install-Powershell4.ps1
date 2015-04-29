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

function Install-Powershell4 {
    <#
    .SYNOPSIS
    Installs Powershell 4.0 locally (or 3.0 if on Windows Server 2008 R2).

    .DESCRIPTION
    Based on script for Ansible:
    https://github.com/ansible/ansible/blob/devel/examples/scripts/upgrade_to_ps3.ps1
   
    .EXAMPLE
    Install-Powershell4   
    #>

    [CmdletBinding()]
    [OutputType([void])]
    param()

    if ($PSVersionTable.psversion.Major -ge 4) {
        Write-Output 'Powershell 4 is already installed'
        return
    }

    # 6.0 is 2008
    # 6.1 is 2008 R2
    # 6.2 is 2012
    # 6.3 is 2012 R2

    if ([Environment]::OSVersion.Version.Major -gt 6) {
        Write-Output 'Windows version is above Windows Server 2012 R2 - upgrade not needed'
        return
    }

    if ([Environment]::OSVersion.Version.Major -lt 6) {
        Write-Output 'Windows version is below Windows Server 2008 - upgrade not possible'
        return
    }

    if ([Environment]::OSVersion.Version.Minor -eq 0) {
        # 2008 - need Powershell 3
        $downloadUrl = 'http://download.microsoft.com/download/E/7/6/E76850B8-DA6E-4FF5-8CCE-A24FC513FD16/Windows6.0-KB2506146-x64.msu'
    } else {
        # >= 2008 R2 - Powershell 4
        $downloadUrl = 'http://download.microsoft.com/download/E/7/6/E76850B8-DA6E-4FF5-8CCE-A24FC513FD16/Windows6.1-KB2506143-x64.msu'
    }

    $powershellPath =  'C:\powershell'
    if (!(Test-Path -LiteralPath $powershellpath)) {
        New-Item -ItemType Directory -Path $powershellpath
    
    }
    $localFilePath = Join-Path -Path $powershellPath -ChildPath (Split-Path -Leaf $downloadUrl)

    Write-Output "Downloading '$downloadUrl' to '$localFilePath'"
    $client = New-Object System.Net.WebClient
    $client.Headers.Add("user-agent", "PowerShell")
    $client.DownloadFile($downloadUrl, $localFilePath)
    
    Write-Output "Running '$localFilePath"
    Start-Process -FilePath $localFilePath -ArgumentList /quiet

    Write-Output 'Done. Please reboot.'
}