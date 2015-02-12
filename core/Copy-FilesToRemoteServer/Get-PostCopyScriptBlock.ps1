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
    param($DestFile, $BlueGreenEnvVariableName, $HashPath)
            
    $destPath = Split-Path -Parent $DestFile
    #Write-Host ("[{0}] Uncompressing file '{1}'" -f (hostname), $using:tempZipDst)       
    $shell = New-Object -ComObject Shell.Application
    $zip = $shell.NameSpace($DestFile)
        
    $dst = $shell.namespace($destPath)
    # 0x14 = overwrite and don't show dialogs
    $dst.Copyhere($zip.items(), 0x14)

    Remove-Item -Path $DestFile -Force

    if ($BlueGreenEnvVariableName) {
        $oldPath = [Environment]::GetEnvironmentVariable($BlueGreenEnvVariableName, 'Machine')
        if ($oldPath) {
            [void](Remove-Item -Path (Join-Path -Path $oldPath -ChildPath '.currentLive') -Force -ErrorAction SilentlyContinue)
        }
        [Environment]::SetEnvironmentVariable($BlueGreenEnvVariableName, $destPath, 'Machine')
        [void](New-Item -Path (Join-Path -Path $destPath -ChildPath '.currentLive') -Force -ItemType File)
    }

    if ($HashPath) {
        $hashRemoteFilePath = Join-Path -Path $destPath -ChildPath "syncHash_$HashPath"
        [void](New-Item -Path $hashRemoteFilePath -ItemType File -Force)
    }
}
