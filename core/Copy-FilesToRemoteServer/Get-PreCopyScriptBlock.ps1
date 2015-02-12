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

function Get-PreCopyScriptBlock {

    <#
	.SYNOPSIS
		Returns a scriptblock that prepares destination directory for Copy-FilesToRemoteServer.

    .DESCRIPTION
        If $BlueGreenEnvVariableName is passed, it selects destination directory basing on environment variable.
        Then, it deletes $Destination if $ClearDestination = $true, and creates new directory at $Destination.

    .EXAMPLE
        $preCopyScriptBlock = Get-PreCopyScriptBlock 
    #>
    [CmdletBinding()]
	[OutputType([scriptblock])]
    param()

    return {
        param($FileName, $Destination, $BlueGreenEnvVariableName, $Destinations, $ClearDestination)

        if ($BlueGreenEnvVariableName) {
            $currentDest = [Environment]::GetEnvironmentVariable($BlueGreenEnvVariableName, 'Machine')
            $destPath = $Destinations[0]
            if ($currentDest -ieq $destPath) {
                $destPath = $Destinations[1]
            }
        } elseif ($Destination) {
            $destPath = $Destination
        }

        $destFile = Join-Path -Path $destPath -ChildPath $FileName
        if (Test-Path -Path $destPath -PathType Leaf) {
            [void](Remove-Item -Path $destPath)
        } 
            
        if (!(Test-Path -Path $destPath -PathType Container)) {
            [void](New-Item -Path $destPath -ItemType Directory)
        } elseif ($clearDestination) {
            $filesToRemove = Join-Path -Path $destPath -ChildPath "*"
            [void](Remove-Item -Path $filesToRemove -Recurse -Force)
        } elseif (Test-Path -Path $destFile) {
            # Delete the previously-existing file if it exists
            [void](Remove-Item -Path $destFile)
        }
        return $destFile
    }
}