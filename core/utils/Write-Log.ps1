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

Function Write-Log {
    <#
    .SYNOPSIS
    Writes a nicely formatted Message to stdout/file/event log.

    .DESCRIPTION
    Writes according to $PSCIGlobalConfiguration.Log* variables.

    .PARAMETER critical
    If specified, an error will be logged and an exception will be thrown

    .PARAMETER error
    If specified, an error will be logged.

    .PARAMETER warn
    If specified, a warning will be logged.

    .PARAMETER info
    If specified, an information will be logged.

     .PARAMETER _debug
    If specified, a debug Message will be logged.

     .PARAMETER Emphasize
    If set, the Message at console will be made more visible (using colors).

    .PARAMETER noHeader
    If specified, Header information will not be logged (e.g. '[ERROR]: (function_name)')

    .PARAMETER indent
    Additional indent (optional).

     .PARAMETER Message
    Message to output

    .EXAMPLE
    Write-Log -Error "A disaster has occurred."
    #>
    
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$false)]
        [switch] 
        $Critical = $false,
        
        [Parameter(Mandatory=$false)]
        [switch] 
        $Error = $false,
        
        [Parameter(Mandatory=$false)]
        [switch] 
        $Warn = $false,
        
        [Parameter(Mandatory=$false)]
        [switch] 
        $Info = $false,
        
        [Parameter(Mandatory=$false)]
        [switch] 
        $_debug = $false,
        
        [Parameter(Mandatory=$false)]
        [switch] 
        $Emphasize = $false,
        
        [Parameter(Mandatory=$false)]
        [switch] 
        $NoHeader = $false,

        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string[]]
        $Message,

        [Parameter(Mandatory=$false)]
        [int]
        $Indent = 0
    )
    Begin { 
        $severityNotSet = $false;

        if ($Critical) {
            $Severity = [PSCI.LogSeverity]::CRITICAL
            $severityChar = 'C'
        } elseif ($Error) {
            $Severity = [PSCI.LogSeverity]::ERROR
            $severityChar = 'E'
        } elseif ($warn) {
            $Severity = [PSCI.LogSeverity]::WARN
            $severityChar = 'W'
        } elseif ($info) {
            $Severity = [PSCI.LogSeverity]::INFO
            $severityChar = 'I'
        } elseif ($_debug) {
            $Severity = [PSCI.LogSeverity]::DEBUG
            $severityChar = 'D'
        } else {
            $severityNotSet = $true;
        }
        if (!$severityNotSet -and [int]$Severity -lt [int]$PSCIGlobalConfiguration.LogLevel) {
            return
        }

        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $callerInfo = Get-CallerInfo
        if ($severityNotSet) {
            $output = "[Write-Log error / $callerInfo]: At least one of switches (critical / error / warn / info / debug) must be on for Write-Log."
            throw $output
        }
        
        if ($NoHeader) {
            $outputHeader = ""
        } else {
            $currentHostname = [system.environment]::MachineName
            $currentUsername = $env:USERNAME    
            if ($PSCIGlobalConfiguration.RemotingMode) {
                $remotingFlag = '[R] '
            } else {
                $remotingFlag = ''
            }
            $outputHeader = "[$severityChar] $timestamp ${remotingFlag}[$currentHostname/${currentUsername}]: ($callerInfo)`t"
        }
        if ($Critical) {
            $Message += "`r`nCritical exception. Please see messages above for details.`r`n"
            $Message += Get-CallStack
        }
    }
    Process { 
        if (!$severityNotSet -and [int]$Severity -lt [int]$PSCIGlobalConfiguration.LogLevel) {
            return
        }
        Write-LogMessage -Header (" " * $Indent + $outputHeader) -Message $Message -Severity $Severity -Emphasize:$Emphasize
    }
    End {
        if ($Critical) {
            Stop-Execution
        }
    }
}

function Get-CallerInfo() {
    <#
    .SYNOPSIS
    Gets information about caller. Helper function.

    .EXAMPLE
    Get-CallerInfo
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param()

    $callerInfo = (Get-PSCallStack)[2]
    $callerCommandName = $callerInfo.InvocationInfo.MyCommand.Name
    if ($callerInfo.ScriptName) {
        $callerScriptName = Split-Path -Leaf $callerInfo.ScriptName
    }
    $callerLineNumber = $callerInfo.ScriptLineNumber
    return "$callerScriptName/$callerCommandName/$callerLineNumber"
}


function Get-CallStack() {
    <#
    .SYNOPSIS
    Gets call stack. Helper function.

    .EXAMPLE
    Get-CallStack
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param()

    $psStack = Get-PSCallStack
    if ($psStack.Length -lt 3) {
        return "No stack trace."
    }
    $msg = ""
    for ($i = 2; $i -lt $psStack.Length; $i++) {
        $msg += ("Stack trace {0}: location={1}, command={2}, arguments={3}`r`n " -f ($i-1), $psStack[$i].Location, $psStack[$i].Command, $psStack[$i].Arguments)
    }
    return $msg
}


function Write-LogMessage() {
    <#
    .SYNOPSIS
    Outputs the Message to stdout/log file/event log. Helper function.

    .PARAMETER Header
    Message Header
    
    .PARAMETER Message
    Message body
    
    .PARAMETER Severity
    Severity

    .PARAMETER Emphasize
    Emphasize

    .EXAMPLE
     Write-LogMessage -Header "Header" -Message "Message" -Severity $Severity 
    #>    

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [string] 
        $Header, 
        
        [string[]] 
        $Message, 
        
        [PSCI.LogSeverity] 
        $Severity, 
        
        [switch] 
        $Emphasize
    )

    try { 
        Write-LogToStdOut -Header $Header -Message $Message -Severity $Severity -Emphasize:$Emphasize
        Write-LogToFile -Header $Header -Message $Message -Severity $Severity
        Write-LogToEventLog -Header $Header -Message $Message -Severity $Severity
    } catch {
        $exception = $_.Exception
        $Message = "Writing to log failed - script will terminate.`r`n"
        $currentUser = Get-CurrentUser
        if ($PSCIGlobalConfiguration.LogFile) {
            $Message += "`r`nPlease ensure that current user ('{0}') has access to file '{1}' or change the path to log file in GlobalSettings.LogFile." -f $currentUser, $PSCIGlobalConfiguration.LogFile
        }
        if ($PSCIGlobalConfiguration.LogEventLogSource) {
            if (!$PSCIGlobalConfiguration.LogEventLogCreateIfNotExists) {
                $Message += "`r`nPlease ensure that Event Log source named '{0}' exists in Application log or switch on 'GlobalSettings.LogEventLogCreateIfNotExists' setting (needs Administrator)." -f $PSCIGlobalConfiguration.LogEventLogSource
            } else {
                $Message += "`r`nPlease ensure that current user ('{0}') is able to create Event Log sources or create the source manually and switch off 'GlobalSettings.LogEventLogCreateIfNotExists' setting." -f $currentUser
            }
        }
        
        $Message += "`n" + ($_ | Format-List -Force | Out-String) + ($exception | Format-List -Force | Out-String)
        Write-Host $Message
        [void](New-Item -Path "error.txt" -ItemType file -Value $Message -Force)
        Stop-Execution
    }
}

function Write-LogToStdOut() {
    <#
    .SYNOPSIS
    Outputs the Message to stdout. Helper function.
    
    .PARAMETER Header
    Message Header
    
    .PARAMETER Message
    Message body
    
    .PARAMETER Severity
    Severity

    .PARAMETER Emphasize
    Emphasize

    .EXAMPLE
    Write-LogToStdOut -Header "Header" -Message "Message" -Severity $Severity 
    #>

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [string] 
        $Header, 
        
        [string[]] 
        $Message, 
        
        [PSCI.LogSeverity] 
        $Severity, 
        
        [switch] 
        $Emphasize
    )
    
    if (Test-WebDeployRemotingMode) {
        $msg = $Message -join "`r`n"
        Write-Host "$Header$msg"
    } else {
        Write-Host $Header -NoNewline -Fore "Gray"

        $color = switch ($Severity) {
            ([PSCI.LogSeverity]::CRITICAL) { [ConsoleColor]::Red }
            ([PSCI.LogSeverity]::ERROR) { [ConsoleColor]::Red }
            ([PSCI.LogSeverity]::WARN) { [ConsoleColor]::Yellow }
            ([PSCI.LogSeverity]::INFO) { 
                if ($PSCIGlobalConfiguration.RemotingMode) {
                    if ($Emphasize) { [ConsoleColor]::DarkCyan } else { [ConsoleColor]::Gray } 
                } else {
                    if ($Emphasize) { [ConsoleColor]::Cyan } else { [ConsoleColor]::White } 
                }
            }
            ([PSCI.LogSeverity]::DEBUG) { 
                if ($PSCIGlobalConfiguration.RemotingMode) { [ConsoleColor]::DarkGray } else { [ConsoleColor]::Gray }
            }
            default { [ConsoleColor]::Red }
        }

        foreach ($msg in $Message) {
            Write-Host $msg -Fore $color
        }
    }
}

function Write-LogToFile() {
    <#
    .SYNOPSIS
    Outputs the Message to file. Helper function.

    .PARAMETER Header
    Message Header
    
    .PARAMETER Message
    Message body
    
    .PARAMETER Severity
    Severity

    .EXAMPLE
    Write-LogToFile  -Header "Header" -Message "Message" -Severity $Severity 
    #>

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [string] 
        $Header, 
        
        [string[]] 
        $Message, 
        
        [PSCI.LogSeverity] 
        $Severity
    )
    
    if ($PSCIGlobalConfiguration.LogFile) {
        $strBuilder = New-Object System.Text.StringBuilder
        [void]($strBuilder.Append($Header))
        foreach ($msg in $Message) {
            [void]($strBuilder.Append($msg).Append("`r`n"))
        }
        [io.file]::AppendAllText($PSCIGlobalConfiguration.LogFile, ($strBuilder.ToString()), [System.Text.Encoding]::Unicode)
    }
}

function Write-LogToEventLog() {
    <#
    .SYNOPSIS
    Outputs the Message to event log.
    
    .DESCRIPTION
    Creates new event log source if not exists and $PSCIGlobalConfiguration.LogEventLogCreateSourceIfNotExists is set. Helper function.

     .PARAMETER Header
    Message Header
    
    .PARAMETER Message
    Message body
    
    .PARAMETER Severity
    Severity

    .EXAMPLE
    Write-LogToEventLog  -Header "Header" -Message "Message" -Severity $Severity 
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string] 
        $Header, 
        
        [string[]] 
        $Message, 
        
        [PSCI.LogSeverity] 
        $Severity
    )
    
    if ($PSCIGlobalConfiguration.LogEventLogSource) {
        if ([int]$Severity -ge [int]$PSCIGlobalConfiguration.LogEventLogThreshold) {

            if ($Severity -eq [PSCI.LogSeverity]::ERROR -or $Severity -eq [PSCI.LogSeverity]::CRITICAL) {
                $entryType = [System.Diagnostics.EventLogEntryType]::Error
            } elseif ($Severity -eq [PSCI.LogSeverity]::WARN) {
                $entryType = [System.Diagnostics.EventLogEntryType]::Warning
            } else {
                $entryType = [System.Diagnostics.EventLogEntryType]::Information
            }

            if ($PSCIGlobalConfiguration.LogEventLogCreateSourceIfNotExists -and ![System.Diagnostics.EventLog]::SourceExists($PSCIGlobalConfiguration.LogEventLogSource)) {
                [void](New-EventLog -LogName Application -Source $PSCIGlobalConfiguration.LogEventLogSource)
            }

            $strBuilder = New-Object System.Text.StringBuilder
            [void]($strBuilder.Append($Header))
            foreach ($msg in $Message) {
                [void]($strBuilder.Append($msg).Append("`r`n"))
            }
            Write-EventLog -LogName Application -Source $PSCIGlobalConfiguration.LogEventLogSource -EntryType $entryType -EventID 1 -Message ($strBuilder.ToString())
        }
    }
}

function Test-WebDeployRemotingMode() {

    <#
    .SYNOPSIS
    Tests whether we're running in WebDeploy remoting mode.

    .EXAMPLE
    Test-WebDeployRemotingMode
    #>

    [CmdletBinding()]
    [OutputType([bool])]
    param ()

    return $PSCIGlobalConfiguration.RemotingMode -in @("WebDeployHandler", "WebDeployAgentService")
}