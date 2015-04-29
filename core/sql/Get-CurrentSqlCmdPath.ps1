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

function Get-CurrentSqlCmdPath {
    <# 
    .SYNOPSIS 
    Returns sqlcmd.exe folder path

    .DESCRIPTION 
    Search for sqlcmd bin path in system registry. First found version will be returned.

    .EXAMPLE
    Get-CurrentSqlCmdPath
    #> 

    [CmdletBinding()] 
    [OutputType([string])]
    param()

    $sqlServerVersions = @('120', '110', '100', '90')
    foreach ($version in $sqlServerVersions) {
        $regKey = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$version\Tools\ClientSetup"
        if (Test-Path -LiteralPath $regKey) {
            $path = (Get-ItemProperty -Path $regKey).Path
            if ($path) {
                $path = Join-Path -Path $path -ChildPath 'sqlcmd.exe'
                if (Test-Path -LiteralPath $path) {
                    return $path
                }
            }
            $path = (Get-ItemProperty -Path $regKey).ODBCToolsPath
            if ($path) {
                $path = Join-Path -Path $path -ChildPath 'sqlcmd.exe'
                if (Test-Path -LiteralPath $path) {
                    return $path
                }
            }
        }
        # registry not found - try directory instead
        $path = "$($env:ProgramFiles)\Microsoft SQL Server\$version\Tools\Binn\sqlcmd.exe"
        if (Test-Path -LiteralPath $path) {
            return $path
        }
    }

    return $null
}



