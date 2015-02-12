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

function Sync-MsDeployDirectory {
    <#
    .SYNOPSIS
    Syncs a local directory to a target host using msdeploy.

    .PARAMETER SourceDir
    Local directory to sync.

    .PARAMETER DestinationDir
    Destination directory that will be created on target computer.

    .PARAMETER DestString
    Destination string to pass to msdeploy.

    .PARAMETER AddParameters
    Additional parameters to pass to msdeploy.

    .EXAMPLE
    Sync-MsDeployDirectory -SourceDir $tempDir -DestinationDir $destinationPath -DestString $msDeployDestString -AddParameters $msDeployAddParameters
    #>

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string] 
        $SourceDir, 

        [Parameter(Mandatory=$true)]
        [string] 
        $DestinationDir, 

        [Parameter(Mandatory=$true)]
        [string] 
        $DestString, 

        [Parameter(Mandatory=$false)]
        [string[]] 
        $AddParameters
    )

    $params = @(
        "-verb:sync",
        "-source:dirPath='$SourceDir'",
        "-dest:dirPath='$DestinationDir',$DestString",
        "-useCheckSum"
    )
    if ($AddParameters) {
        # SuppressScriptCop - adding small arrays is ok
        $params += $AddParameters
    }
    Start-MsDeploy -Params $params
}
