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

function Copy-FilesToRemoteServer {
	<#
	.SYNOPSIS
		Sends files or whole directories to remote server using 1mb chunks.

	.PARAMETER Path
		The file or directory path that should be sent to remote server.

    .PARAMETER ConnectionParams
        Connection parameters created by New-ConnectionParameters function.

	.PARAMETER Destination
		The remote path where the file will be saved to.

    .PARAMETER BlueGreenEnvVariableName
        If specified, this environment variable name will be used for blue-green deployment 
        (destination directories will be changing between those specified in $Destinations).

    .PARAMETER Destinations
        Only if BlueGreenEnvVariableName is specified - list of destination directories to use for blue-green deployment.

    .PARAMETER Exclude
        The files to be excluded from copying to remote server.

    .PARAMETER CheckHashMode
        There are three modes for checking whether the destination path needs to be updated:
        DontCheckHash - files are always uploaded to the servers
        AlwaysCalculateHash - files are uploaded to the servers if their hashes calculated in local path and in remote path are different
        UseHashFile - files are uploaded to the servers if there doesn't exist a syncHash_<hash> file, where hash is hash calculated in local path

    .PARAMETER ClearDestination
        If $true then all content from $Destination will be deleted.

	.EXAMPLE			
        PS C:\> Copy-FilesToRemoteServer c:\temp\test.exe c:\temp\ (New-ConnectionParameters -Nodes server)
        PS C:\> Copy-FilesToRemoteServer c:\temp\*.* c:\temp\ (New-ConnectionParameters -Nodes @('server1', 'server2'))
        PS C:\> Copy-FilesToRemoteServer c:\temp\ c:\temp\ (New-ConnectionParameters -Nodes server1)

	#>
	[CmdletBinding(DefaultParametersetName='JustCopy')]
	[OutputType([string[]])]
	param(
        
        [Parameter(Mandatory = $true)]
        [string[]]
        $Path,

        [Parameter(Mandatory = $true)]
        [object]
        $ConnectionParams,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'JustCopy')]
        [string]
        $Destination,

        [Parameter(Mandatory = $true, ParameterSetName = 'BlueGreen')]
        [string]
        $BlueGreenEnvVariableName,

        [Parameter(Mandatory = $true, ParameterSetName = 'BlueGreen')]
        [string[]]
        $Destinations,

        [Parameter(Mandatory = $false)]
        [string[]]
        $Exclude,

        [Parameter(Mandatory = $false, ParameterSetName = 'JustCopy')]
        [string]
        [ValidateSet('DontCheckHash','AlwaysCalculateHash','UseHashFile')]
        $CheckHashMode = 'DontCheckHash',

        [Parameter(Mandatory = $false)]
        [switch]
        $ClearDestination = $false
    )

    if ($ConnectionParams.RemotingMode -ne 'PSRemoting') {
        Write-Log -Critical "ConnectionParams.RemotingMode = $($ConnectionParams.RemotingMode) is not supported by this function (only PSRemoting is)."
    }
    if ($Destinations -and $Destinations.Count -ne 2) {
        Write-Log -Critical "'Destinations' parameter must be two-element array (two paths for blue-green copy)."
    }
    if ($Destinations -and $Destinations[0] -ieq $Destinations[1]) {
        Write-Log -Critical "'Destinations' parameter must contain two different paths (currently are the same - $($Destinations[0])."
    }

    $preCopyScriptBlock = Get-PreCopyScriptBlock 
    $writeBytesRemoteScript = Get-WriteBytesScriptBlock
    $postCopyScriptBlock = Get-PostCopyScriptBlock

    # calculate hash for local files if required
    if ($Destination -and $CheckHashMode -ne 'DontCheckHash') {
       Write-Progress -Activity "Checking whether '$Destination' needs updating" -Id 1
       $hashPath = Get-Hash -Path $Path -Exclude $Exclude
    }

    $sessions = New-CopySessions -Path $Path -ConnectionParams $ConnectionParams -Exclude $Exclude -Destination $Destination -CheckHashMode $CheckHashMode -HashPath $hashPath
    if (!$sessions) {
        Write-Progress -Activity "Finished" -Completed -Id 1
        return @()
    }

    if ($CheckHashMode -ne 'UseHashFile') {
        $hashPath = $null
    }

    $serversToUpdate = $sessions | Select-Object -ExpandProperty ComputerName

    try { 
        if ($Path.Count -eq 1 -and $Path.ToLower().EndsWith('zip')) {
            $tempZip = $null
            $zipToCopy = $Path
        } else {
            $tempZip = ([IO.Path]::GetTempFileName()) + ".zip"
            $zipToCopy = $tempZip
            if (Test-Path -Path $tempZip) {
                [void](Remove-Item -Path $tempZip -Force)
            }
            New-Zip -Path $Path -OutputFile $tempZip -Exclude $Exclude
        }
        $items = Get-Item -Path $zipToCopy
        foreach ($session in $sessions) { 
           foreach ($item in $items) {
                Write-Progress -Activity "Sending '$item'" -Status "Preparing file" -Id 1
                $destFile = Invoke-Command -Session $session -ScriptBlock $preCopyScriptBlock -ArgumentList $item.Name, $Destination, $BlueGreenEnvVariableName, $Destinations, $ClearDestination
                Write-Log -Info "Copying '$item' to remote node '$($session.ComputerName)' / '$destFile'"
    
                # Now break it into chunks [1MB] to stream
                $streamSize = 1MB
                $position = 0
                $rawBytes = New-Object -TypeName byte[] -ArgumentList $streamSize
                $file = [IO.File]::OpenRead($item.FullName)

                while(($read = $file.Read($rawBytes, 0, $streamSize)) -gt 0) {
                    Write-Progress -Activity "Writing $destFile" -Status "Sending file" -PercentComplete ($position / $item.Length * 100) -Id 1
        
                    # Ensure that our array is the same size as what we read from disk
                    if($read -ne $rawBytes.Length) {
                        [Array]::Resize( [ref] $rawBytes, $read)
                    }
        
                    # And send that array to the remote system
                    Invoke-Command -Session $session -ScriptBlock $writeBytesRemoteScript -ArgumentList $destFile, $rawBytes
        
                    # Ensure that our array is the same size as what we read from disk
                    if($rawBytes.Length -ne $streamSize) {
                        [Array]::Resize( [ref] $rawBytes, $streamSize)
                    }
        
                    $position += $read
                }
                $file.Close()
            }

            Write-Progress -Activity "Uncompressing $destFile" -Id 1
            Invoke-Command -Session $session -ScriptBlock $postCopyScriptBlock -ArgumentList $destFile, $BlueGreenEnvVariableName, $hashPath

            Remove-PSSession -Session $session
            Write-Progress -Activity "Finished" -Completed -Id 1
        }
    } finally {
        foreach ($session in ($sessions | Where-Object { $_.State -ne 'Closed' })) {
            Remove-PSSession -Session $session
        }
        if ($tempZip -and (Test-Path -Path $tempZip)) {
            [void](Remove-Item -Path $tempZip -Force)
        }
    }
    return $serversToUpdate
}