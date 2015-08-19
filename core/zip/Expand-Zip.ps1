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

function Expand-Zip {
    <#
    .SYNOPSIS
    Decompresses an archive file without using any external libraries.
    
    .PARAMETER ArchiveFile
    File to uncompress.
    
    .PARAMETER OutputDirectory
    Output directory.

    .EXAMPLE
    Expand-Zip -ArchiveFile "d:\test.zip" -OutputDirectory "d:\test"
    #>

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string] 
        $ArchiveFile, 
        
        [Parameter(Mandatory=$true)]
        [string] 
        $OutputDirectory
    )
    
    # this function can be run remotely without PSCI available
    

    # try decompressing with .NET first (only if destination does not exist - otherwise it fails)
    if (!(Test-Path -Path $OutputDirectory)) { 
        try { 
            $msg = "Decompressing file '$ArchiveFile' to '$OutputDirectory' using .NET"
            if (Get-Command -Name Write-Log -ErrorAction SilentlyContinue) {
               Write-Log -Info $msg 
            } else {
               Write-Verbose -Message $msg
            }
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($ArchiveFile, $OutputDirectory) 
            return
        } catch {
            Write-Host -Object ".Net decompression failed: $_ - falling back to 7-zip / shell."
        }
    }
    
    # then 7-zip
    try { 
        $msg = "Decompressing file '$ArchiveFile' to '$OutputDirectory' using 7-zip"
        if (Get-Command -Name Write-Log -ErrorAction SilentlyContinue) {
            Write-Log -Info $msg 
        } else {
            Write-Verbose -Message $msg
        }

        $regEntry = 'Registry::HKLM\SOFTWARE\7-Zip'
        # note - registry check will fail if running Powershell x86 on x64 machine
        if (Test-Path -LiteralPath $regEntry) {
            $7zipPath = (Get-ItemProperty -Path $regEntry).Path + '7z.exe'
        } else {
            $7zipPath = 'C:\Program Files\7-Zip\7z.exe'
        }
        if (Test-Path -LiteralPath $7zipPath) {
            $7zipPath = '"{0}"' -f $7zipPath
            $cmdLine =  " x `"$ArchiveFile`" -o`"$OutputDirectory`" -y"
            . $env:ComSpec /C """$7zipPath $cmdLine"""
            if (!$LASTEXITCODE) {
                return
            } else {
                Write-Host -Object "7zip decompression failed with exitcode $LASTEXITCODE - falling back to shell."
            }
                
        }
    } catch {
        Write-Host -Object "7zip decompression failed: $_ - falling back to shell."
    }

    $msg = "Decompressing file '$ArchiveFile' to '$OutputDirectory' using Shell.Application"
    if (Get-Command -Name Write-Log -ErrorAction SilentlyContinue) {
        Write-Log -Info $msg 
    } else {
        Write-Verbose -Message $msg
    }
    
    # then shell - which can be slow when running remotely for unknown reasons
    $shell = New-Object -ComObject Shell.Application
    $zip = $shell.Namespace($ArchiveFile)
    $dst = $shell.Namespace($OutputDirectory)
    # 0x14 = overwrite and don't show dialogs
    $dst.Copyhere($zip.Items(), 0x14)
    
}