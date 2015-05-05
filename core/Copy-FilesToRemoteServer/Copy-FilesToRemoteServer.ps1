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
		The remote path where the file will be saved to (must be absolute path and always mean directory, not a file).

    .PARAMETER BlueGreenEnvVariableName
        If specified, this environment variable name will be used for blue-green deployment 
        (destination directories will be changing between those specified in $Destination).

    .PARAMETER Include
        List of file / directory to include.

    .PARAMETER IncludeRecurse
        Recurse type for Include rules (if set, wildcards will be matched recursively).

    .PARAMETER Exclude
        List of file / directory to exclude.

    .PARAMETER ExcludeRecurse
        Recurse type for Include rules (if set, wildcards will be matched recursively).

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
        [Parameter(Mandatory = $true, ParameterSetName = 'BlueGreen')]
        [string[]]
        $Destination,

        [Parameter(Mandatory = $true, ParameterSetName = 'BlueGreen')]
        [string]
        $BlueGreenEnvVariableName,

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

        [Parameter(Mandatory = $false, ParameterSetName = 'JustCopy')]
        [string]
        [ValidateSet('DontCheckHash','AlwaysCalculateHash','UseHashFile')]
        $CheckHashMode = 'DontCheckHash',

        [Parameter(Mandatory = $false)]
        [switch]
        $ClearDestination = $true
    )

    if ($ConnectionParams.RemotingMode -ne 'PSRemoting') {
        Write-Log -Critical "ConnectionParams.RemotingMode = $($ConnectionParams.RemotingMode) is not supported by this function (only PSRemoting is)."
    }
    if (!$ConnectionParams.Nodes) {
        Write-Log -Critical "ConnectionParams.Nodes is empty. It must be specified for this function."
    }
    
    for ($i = 0; $i -lt $DestinationZipPath.Count; $i++) {
        $dest = $DestinationZipPath[$i]
        $destNext = $DestinationZipPath[$i+1]
        if (![System.IO.Path]::IsPathRooted($dest)) {
            Write-Log -Critical "'Destination' must be an absolute path - invalid value '$dest'."
        }
        if ($destNext -and $dest[0] -ne $destNext[0]) {
            Write-Log -Critical "'Destination' paths must be on the same disk."
        }
    } 

    if (!$BlueGreenEnvVariableName -and $Path.Count -ne $Destination.Count -and $Destination.Count -ne 1) {
        Write-Log -Critical "'Destination' array must be of length 1 or the same length as 'Path' array."
    }

    if ($BlueGreenEnvVariableName -and $Destination.Count -ne 2) {
        Write-Log -Critical "'Destinations' parameter must be two-element array (two paths for blue-green copy)."
    }
    if ($BlueGreenEnvVariableName -and $Destination[0] -ieq $Destination[1]) {
        Write-Log -Critical "'Destinations' parameter must contain two different paths (currently are the same - $($Destination[0])."
    }

    $preCopyScriptBlock = Get-PreCopyScriptBlock 
    $postCopyScriptBlock = Get-PostCopyScriptBlock

    # calculate hash for local files if required
    if ($CheckHashMode -ne 'DontCheckHash') {
       Write-Progress -Activity "Checking whether '$Destination' needs updating" -Id 1
       $hashPath = Get-Hash -Path $Path -Include $Include -IncludeRecurse:$IncludeRecurse -Exclude $Exclude -ExcludeRecurse:$ExcludeRecurse
    }

    $sessions = New-CopySessions -Path $Path `
                                 -ConnectionParams $ConnectionParams `
                                 -Include $Include `
                                 -IncludeRecurse:$IncludeRecurse `
                                 -Exclude $Exclude `
                                 -ExcludeRecurse:$ExcludeRecurse `
                                 -Destination $Destination `
                                 -CheckHashMode $CheckHashMode `
                                 -HashPath $hashPath
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
            $isStructuredZip = $false
        } else {
            $tempZip = ([IO.Path]::GetTempFileName()) + ".zip"
            $zipToCopy = $tempZip
            if (Test-Path -LiteralPath $tempZip) {
                [void](Remove-Item -LiteralPath $tempZip -Force)
            }
            Write-Progress -Activity "Creating '$zipToCopy'" -Status "Preparing files to copy" -Id 1

            $zipParams = @{
                Path = $Path
                OutputFile = $tempZip
                Include = $Include
                IncludeRecurse = $IncludeRecurse
                Exclude = $Exclude
                ExcludeRecurse = $ExcludeRecurse
            }

            if (!$BlueGreenEnvVariableName) { 
                New-Zip @zipParams -DestinationZipPath $Destination
                $isStructuredZip = $true
            } else {
                New-Zip @zipParams
                $isStructuredZip = $false
            }
            if (!(Test-Path -LiteralPath $tempZip)) {
                Write-Log -Critical "Temporary zip file '$tempZip' has not been created - critical exception, please investigate."
            }
        }
        $zipItem = Get-Item -Path $zipToCopy
        foreach ($session in $sessions) { 
           $destZipFile = Invoke-Command -Session $session -ScriptBlock $preCopyScriptBlock -ArgumentList $zipItem.Name, $Destination, $BlueGreenEnvVariableName, $ClearDestination
           Send-FileStream -Session $session -ItemToCopy $zipItem -DestinationPath $destZipFile

           Write-Progress -Activity "Uncompressing $destZipFile" -Id 1
           if ($isStructuredZip) {
               # if we have a 'structured' zip, we just need to expand it to root drive
               $dest = $Destination[0].Substring(0, 3)
           } else {
               $dest = Split-Path -Parent $destZipFile
           }
           [void](Invoke-Command -Session $session -ScriptBlock $postCopyScriptBlock -ArgumentList $destZipFile, $dest, $BlueGreenEnvVariableName, $hashPath, $ClearDestination)

           Remove-PSSession -Session $session
           Write-Progress -Activity "Finished" -Completed -Id 1
        }
    } finally {
        foreach ($session in ($sessions | Where-Object { $_.State -ne 'Closed' })) {
            Remove-PSSession -Session $session
        }
        if ($tempZip -and (Test-Path -LiteralPath $tempZip)) {
            [void](Remove-Item -LiteralPath $tempZip -Force)
        }
    }
    return $serversToUpdate
}