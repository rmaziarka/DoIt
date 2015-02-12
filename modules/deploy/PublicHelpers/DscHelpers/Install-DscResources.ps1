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

function Install-DscResources {
    <#
    .SYNOPSIS
    Installs DSC resources that comes with PSCI to a local or remote computer.

    .DESCRIPTION
    The DSC resources come from 'PSCI\modules\deploy\dsc' directory.
    If no parameter is provided, the DSC resources will be copied locally with robocopy.
    If $ComputerNames is provided, the DSC resources will be copied using Powershell remoting (using Copy-FilesToRemoteServers).

    .PARAMETER ConnectionParams
    Connection parameters created by New-ConnectionParameters function.

    .EXAMPLE
    Install-DscResources
    
    #>

	[CmdletBinding()]
	[OutputType([void])]
    param(
        [Parameter(Mandatory=$false)]
        [object] 
        $ConnectionParams
    )

    if (!$ConnectionParams) {
        $ConnectionParams = New-ConnectionParameters -Nodes 'localhost'
    }

    $srcBasePath = Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\..\dsc")
    # note: $Env:ProgramFiles gives Program Files (x86) if running Powershell x86...
    $baseDestPath = Join-Path -Path "C:\Program Files" -ChildPath "WindowsPowerShell\Modules"
    $externalLibDirs = @(Join-Path -Path $srcBasePath -ChildPath "ext\*\*" | Get-ChildItem -Directory | Select-Object -ExpandProperty FullName)
    $customDSCResources = @(Join-Path -Path $srcBasePath -ChildPath "custom" | Get-ChildItem -Directory | Select-Object -ExpandProperty FullName)
    $srcPaths = $customDSCResources + $externalLibDirs
    
    $clearDSCCache = {
        $DscNamespace = "root/Microsoft/Windows/DesiredStateConfiguration" 

        Write-Verbose 'Stopping any existing WMI processes to clear cached resources.'
        Get-process -Name WmiPrvSE -erroraction silentlycontinue | stop-process -force
                
        Write-Verbose 'Clearing out any tmp WMI classes from tested resources.'
        Get-wmiobject -Namespace $DscNamespace -List -Class tmp* | ForEach-Object { (Get-wmiobject -Namespace $DscNamespace -list -Class $_).psbase.delete() }
    }

    $nodes = $ConnectionParams.Nodes.Clone()

    Write-Log -Info ("Installing DSC modules from '$srcBasePath' to {0}" -f ($nodes -join ", "))

    $localhostNodePresent = $false
    foreach ($node in $ConnectionParams.Nodes) {
        if (Test-ComputerNameIsLocalhost -ComputerName $node) {
            $localhostNodePresent = $true
            $nodes = $nodes -ne $node
        }
    }

    if ($localhostNodePresent) {
        #TODO: this does not copy files in root of external\ReskitWave7 and can result in mismatching hashes (for now patched by specifying exclude below)
        foreach ($srcPath in $srcPaths) {
            $dscDirName = Split-Path -Path $srcPath -Leaf
            $destPath = Join-Path -Path $baseDestPath -ChildPath $dscDirName
            Sync-DirectoriesWithRobocopy -SrcPath $srcPath -DestPath $destPath -Sync:$true -Quiet
        }

        Write-Log -Info "Clearing DSC cache on 'localhost'"
        try { 
            Invoke-Command -ScriptBlock $clearDSCCache
        } catch {
            Write-Log -Warn "Failed to clear DSC cache (you might need to clear it manually): $_."
        }
    } 
      
    if ($nodes) {
        $uniqueSrcPaths = $srcPaths | Split-Path -Parent | Select-Object -Unique
        
        foreach ($computerName in $nodes) {
            #TODO: exclude workaround - see comment above

            $copyParams = @{
                Path = $uniqueSrcPaths
                Destination = $baseDestPath
                ConnectionParams = New-ConnectionParameters -Nodes $computerName -Credential $ConnectionParams.Credential -Authentication $ConnectionParams.Authentication -Port $ConnectionParams.Port -Protocol $ConnectionParams.Protocol
                Exclude = 'upgrade.txt','AllResources*.html'
                ClearDestination = $true
                CheckHashMode = 'UseHashFile'
            } 

            $clearDSCCacheParams = $connectionParams.PSSessionParams
            $clearDSCCacheParams.ScriptBlock = $clearDSCCache

            try { 
                $updated = Copy-FilesToRemoteServer @copyParams
            } catch {
                # Sometimes wmiprvse.exe is locking dlls used by DSC resources - restarting the process helps
                Write-Log -Warn ("Copy-FilesToRemoteServer failed with message: '{0}' - clearing DSC cache and retrying" -f $_.Exception.Message)
                Invoke-Command @clearDSCCacheParams
                $updated = Copy-FilesToRemoteServer @copyParams
            }

            if ($updated) {
                Write-Log -Info "Clearing DSC cache on '$($ConnectionParams.NodesAsString)'"
                Invoke-Command @clearDSCCacheParams
            }
        }
    }
}