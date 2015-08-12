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

function Copy-FilesFromRemoteServer {
	<#
	.SYNOPSIS
		Downloads files or whole directories from a remote server using 1mb chunks.

	.PARAMETER RemotePath
		The file or directory path that should be downloaded from remote server.

    .PARAMETER ConnectionParams
        Connection parameters created by New-ConnectionParameters function.

	.PARAMETER Destination
		The local path where the file will be saved to (must be a directory - existing or non-existing).

    .PARAMETER Include
        List of file / directory to include.

    .PARAMETER IncludeRecurse
        Recurse type for Include rules (if set, wildcards will be matched recursively).

    .PARAMETER Exclude
        List of file / directory to exclude.

    .PARAMETER ExcludeRecurse
        Recurse type for Include rules (if set, wildcards will be matched recursively).

    .PARAMETER ClearDestination
        If $true then all content at $Destination will be deleted.

	.EXAMPLE			
        Copy-FilesFromRemoteServer -ConnectionParams (New-ConnectionParameters -Nodes server) -RemotePath 'c:\temp\test.exe' -Destination 'c:\temp'
	#>
	[CmdletBinding()]
	[OutputType([void])]
	param(
        
        [Parameter(Mandatory = $true)]
        [string[]]
        $RemotePath,

        [Parameter(Mandatory = $true)]
        [object]
        $ConnectionParams,
        
        [Parameter(Mandatory = $true)]
        [string]
        $Destination,

        [Parameter(Mandatory=$false)]
        [string[]] 
        $Include,

        [Parameter(Mandatory=$false)]
        [switch] 
        $IncludeRecurse,
         
        [Parameter(Mandatory=$false)]
        [string[]] 
        $Exclude,

        [Parameter(Mandatory=$false)]
        [switch] 
        $ExcludeRecurse,

        [Parameter(Mandatory = $false)]
        [switch]
        $ClearDestination
    )

    if ($ConnectionParams.RemotingMode -ne 'PSRemoting') {
        Write-Log -Critical "ConnectionParams.RemotingMode = $($ConnectionParams.RemotingMode) is not supported by this function (only PSRemoting is)."
    }
    if (!$ConnectionParams.Nodes) {
        Write-Log -Critical "ConnectionParams.Nodes is empty. It must be specified for this function."
    }

    if ($ConnectionParams.Nodes.Count -ne 1) {
        Write-Log -Critical "ConnectionParams.Nodes has more than 1 node. Only one node must be specified.."
    }

    Write-Log -Info "Copying '$RemotePath' from '$($ConnectionParams.NodesAsString)' to local path '$Destination'" -Emphasize
    
    if (Test-Path -LiteralPath $Destination -PathType Leaf) {
        Write-Log -Critical "Destination path '$Destination' already exists and is a file. Destination must be a directory."
    }
    if ((Test-Path -LiteralPath $Destination -PathType Container) -and $ClearDestination) {
        $resolvedPath = (Resolve-Path -LiteralPath $Destination).ProviderPath
        if ($resolvedPath.Length -le 3) {
            Write-Log -Critical "Cannot delete root directory '$resolvedPath'. Please specify ClearDestination = false or different Destination"
        }
        Write-Log -Info "Deleting destination directory '$Destination'"
        Remove-Item -LiteralPath $Destination -Force -Recurse
    }
    if (!(Test-Path -LiteralPath $Destination)) {
        [void](New-Item -Path $Destination -ItemType Directory -Force)
    }
    $Destination = (Resolve-Path -LiteralPath $Destination).ProviderPath
   
    $preCopyScriptBlock = Get-PreCopyFromScriptBlock 
    $postCopyScriptBlock = Get-PostCopyFromScriptBlock

    $sessions = New-CopySessions -ConnectionParams $ConnectionParams
                                 
    if (!$sessions) {
        Write-Progress -Activity "Finished" -Completed -Id 1
        return @()
    }

    $servers = $sessions | Select-Object -ExpandProperty ComputerName

    try { 
        foreach ($session in $sessions) { 
           Invoke-Command -Session $session -ScriptBlock (Convert-FunctionToScriptBlock -FunctionName Get-FlatFileList)
           Invoke-Command -Session $session -ScriptBlock (Convert-FunctionToScriptBlock -FunctionName New-Zip)

           ($srcZipFilePath, $srcZipFileSize) = Invoke-Command -Session $session -ScriptBlock $preCopyScriptBlock -ArgumentList $RemotePath, $Destination, $Include, $IncludeRecurse, $Exclude, $ExcludeRecurse

           $destZipFilePath = '{0}{1}.zip' -f [System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName()
           Get-RemoteFileUsingStream -Session $session -SourcePath $srcZipFilePath -DestinationPath $destZipFilePath -SourceFileSize $srcZipFileSize

           Write-Progress -Activity "Uncompressing $destZipFilePath" -Id 1
           $dest = $Destination.Substring(0, 3)
           Expand-Zip -ArchiveFile $destZipFilePath -OutputDirectory $dest
        }
    } finally {
        if ($srcZipFilePath) {
            Invoke-Command -Session $session -ScriptBlock $postCopyScriptBlock -ArgumentList $srcZipFilePath
        }
        foreach ($session in ($sessions | Where-Object { $_.State -ne 'Closed' })) {
            Remove-PSSession -Session $session
        }
        if ($destZipFilePath -and (Test-Path -LiteralPath $destZipFilePath)) {
            [void](Remove-Item -LiteralPath $destZipFilePath -Force)
        }
        Write-Progress -Activity "Finished" -Completed -Id 1
    }
}