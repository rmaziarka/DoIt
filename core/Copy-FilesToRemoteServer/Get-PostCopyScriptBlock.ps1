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

function Get-PostCopyScriptBlock {
    <#
    .SYNOPSIS
	    Returns a scriptblock that uncompresses zip file and creates syncHash_* file for Copy-FilesToRemoteServer.

    .DESCRIPTION
        If $BlueGreenEnvVariableName is passed, it also creates '.currentLive' file in current destination directory.

    .EXAMPLE
        $postCopyScriptBlock = Get-PostCopyScriptBlock
    #>
    [CmdletBinding()]
    [OutputType([scriptblock])]
    param()

    return {

        [CmdletBinding()]
	    [OutputType([string])]
	    param(
            [Parameter(Mandatory = $true)]
            [string]
            $ZipFilePath,

            [Parameter(Mandatory = $false)]
            [string]
            $Destination,

            [Parameter(Mandatory = $false)]
            [string]
            $BlueGreenEnvVariableName,

            [Parameter(Mandatory = $false)]
            [string]
            $HashPath,

            [Parameter(Mandatory = $false)]
            [boolean]
            $ZipDestinationIsClear
        )

        $Global:ErrorActionPreference = 'Stop'
        $Global:VerbosePreference = 'Continue'
        $success = $false

        # try decompressing with .NET first (only if destination does not exist - otherwise it fails)
        if ($ZipDestinationIsClear) {
           try { 
                Add-Type -AssemblyName System.IO.Compression.FileSystem
                [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFilePath, $Destination) 
                $success = $true
            } catch {
                Write-Verbose -Message ".Net decompression failed: $_ - falling back to 7-zip / shell."
            }
        }

        if (!$success) { 
            # then 7-zip
            try { 
                $regEntry = 'Registry::HKLM\SOFTWARE\7-Zip'
                # note - registry check will fail if running Powershell x86 on x64 machine
                if (Test-Path -Path $regEntry) {
                    $7zipPath = (Get-ItemProperty -Path $regEntry).Path + '7z.exe'
                } else {
                    $7zipPath = 'C:\Program Files\7-Zip\7z.exe'
                }
                if (Test-Path -Path $7zipPath) {
                    & $7zipPath " x $ZipFilePath -o$Destination -y"
                    if (!$LASTEXITCODE) {
                        $success = $true
                    }
                }
            } catch {
                Write-Verbose -Message "7zip decompression failed: $_ - falling back to shell."
            }
        }

        # then shell - which can be slow when running remotely for unknown reasons
        if (!$success) {
            $shell = New-Object -ComObject Shell.Application
            $zip = $shell.Namespace($ZipFilePath)
        
            $dst = $shell.namespace($Destination)
            # 0x14 = overwrite and don't show dialogs
            $dst.Copyhere($zip.Items(), 0x14)
        }

        Remove-Item -Path $ZipFilePath -Force

        if ($BlueGreenEnvVariableName) {
            $oldPath = [Environment]::GetEnvironmentVariable($BlueGreenEnvVariableName, 'Machine')
            if ($oldPath) {
                [void](Remove-Item -Path (Join-Path -Path $oldPath -ChildPath '.currentLive') -Force -ErrorAction SilentlyContinue)
            }
            
            [Environment]::SetEnvironmentVariable($BlueGreenEnvVariableName, $destPath, 'Machine')
            [void](New-Item -Path (Join-Path -Path $Destination -ChildPath '.currentLive') -Force -ItemType File)
        }
        if ($HashPath) {
            $zipDir = Split-Path -Parent $ZipFilePath
            Get-ChildItem -Path $zipDir -Filter "syncHash_*" | Remove-Item
            $hashRemoteFilePath = Join-Path -Path $zipDir -ChildPath "syncHash_$HashPath"
            [void](New-Item -Path $hashRemoteFilePath -ItemType File -Force)
        }
    }
}
