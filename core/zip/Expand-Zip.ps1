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

    Write-Log -Info "Decompressing file '$ArchiveFile' to '$OutputDirectory'"
    $shell = New-Object -ComObject Shell.Application
    $zip = $shell.NameSpace($ArchiveFile)
    foreach ($item in $zip.items()) {
        # 0x14 = overwrite and don't show dialogs
        $shell.Namespace($OutputDirectory).CopyHere($item, 0x14)
    }
}