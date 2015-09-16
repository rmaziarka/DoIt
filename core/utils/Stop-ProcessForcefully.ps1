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

function Stop-ProcessForcefully {

    <#
    .SYNOPSIS
    Kills process forcefully along with its children.
    
    .PARAMETER Process
    Process object.

    .PARAMETER KillTimeoutInSeconds
    Time to wait for process before killing it.
    
    .EXAMPLE
    Stop-ProcessForcefully -Process $process
    #>

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        $Process,

        [Parameter(Mandatory=$true)]
        [int]
        $KillTimeoutInSeconds
    )
    
    $childProcesses = Get-WmiObject -Class Win32_Process -Filter "ParentProcessID=$($Process.Id)" | Select-Object -ExpandProperty ProcessID
    
    try { 
        if ($childProcesses) {
            Write-Log -Info "Killing child processes: $childProcesses"
            Stop-Process -Id $childProcesses -Force
        } else {
            Write-Log -Info "No child processes for pid $($Process.Id)"
        }
        Write-Log -Info "Killing process $($Process.Id)"
        $Process.Kill()
    } catch {
        Write-Log -Warn "Kill method thrown exception: $_ - waiting for exit."
    }
    if (!$Process.WaitForExit($KillTimeoutInSeconds * 1000)) {
        throw "Cannot kill process (pid $($Process.Id)) - still running after $($KillTimeoutInSeconds * 1000 * 2) s"
    }
    Write-Log -Info "Process $($Process.Id) killed along with its children."
}