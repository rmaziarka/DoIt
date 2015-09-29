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

function PSCI-Upload-Directories {

    <#
    .SYNOPSIS
    Uploads specific directories to remote host using WinRM.

    .DESCRIPTION
    It uses following tokens:
    - **$Tokens.Directories** - hashtable in form @{ '<source_directory relative to packagesPath>' = '<destination_directory>' }
    - **$Tokens.CheckHashMode** (optional) - type of hash check (optimization) - see [[Copy-FilesToRemoteServer].

    .PARAMETER NodeName
    [automatic parameter] Name of node where the directories will be uploaded to.

    .PARAMETER ServerRole
    [automatic parameter] Name of current server role.

    .PARAMETER Tokens
    [automatic parameter] Tokens hashtable - see description for details.

    .PARAMETER ConnectionParams
    [automatic parameter] Connection parameters taken from current ServerConnection (see [[New-ConnectionParameters]]).

    .EXAMPLE
    ```
    PSCIWindowsFeatures -OutputPath 'test' -ConfigurationData @{ AllNodes = @( @{ 
        NodeName = 'localhost'; 
        Tokens = @{ 
            IsClientWindows = $true
            WindowsFeatures = 'IIS-WebServerRole', 'IIS-ASPNET45', 'IIS-WindowsAuthentication'
        }
    } ) }

    Start-DscConfiguration -Path 'test' -ComputerName localhost -Wait -Force -Verbose
    ```
    #>

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $NodeName,

        [Parameter(Mandatory=$true)]
        [string]
        $ServerRole,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $Tokens,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $ConnectionParams
    )

    $directories = Get-TokenValue -Name 'UploadDirectories'
    $checkHashMode = Get-TokenValue -Name 'UploadDirectoriesCheckHashMode'

    if (!$directories) {
        return
    }

    if ($directories -isnot [hashtable]) {
        throw "UploadDirectories token must be a hashtable (e.g. @{ '<source_directory relative to packagesPath>' = '<destination_directory>' })."
    }

    if (!$checkHashMode) {
        $checkHashMode = 'UseHashFile'
    }

    Write-Log -Info ("Starting PSCI-Upload-Directories, node ${NodeName}: {0}" -f (Convert-HashtableToString -Hashtable $directories))

    $srcList = @()
    $dstList = @()
    $packagesPath = (Get-ConfigurationPaths).PackagesPath

    foreach ($dirInfo in $directories.GetEnumerator()) {
        if ([System.IO.Path]::IsPathRooted($dirInfo.Key)) { 
            $srcList += $dirInfo.Key
        } else {
            $srcList += (Join-Path -Path $packagesPath -ChildPath $dirInfo.Key)
        }
        $dstList += $dirInfo.Value
    }
    
    $params = @{
        Path = $srcList 
        ConnectionParams = $ConnectionParams
        Destination = $dstList
        ClearDestination = $true
        CheckHashMode = $checkHashMode
    }

    Copy-FilesToRemoteServer @params
}
