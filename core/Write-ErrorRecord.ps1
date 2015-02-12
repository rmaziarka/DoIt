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

function Write-ErrorRecord {
    <#
    .SYNOPSIS
    Logs ErrorRecord message, including script StackTrace and exception StackTrace.

    .PARAMETER ErrorRecord
    Error record to log. If null, $_ will be used.

    .PARAMETER message
    Additional message to log.

    .PARAMETER stopExecution
    If true, script will stop execution (exit with errorcode).

    .EXAMPLE
    Write-ErrorRecord -ErrorRecord $errorRecord -Message "message" -StopExecution
    #>

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$false)]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord, 
        
        [Parameter(Mandatory=$false)]
        [string] 
        $Message, 
        
        [Parameter(Mandatory=$false)]
        [switch] 
        $StopExecution = $true
    )
    
    if (!$ErrorRecord) {
        $ErrorRecord = $_
    }
    $exception = $ErrorRecord.Exception
    $messageToLog = $Message + "`n" + ($ErrorRecord | Format-List -Force | Out-String) + ($exception | Format-List -Force | Out-String)
   
    if (!$Message -and $exception.Message) {
        $progressMessage = "$($exception.Message);`n$messageToLog"
    } else {
        $progressMessage = $messageToLog
    }
    if ($Global:ProgressErrorMessage) {
        $Global:ProgressErrorMessage += "; $progressMessage"
    } else {
        $Global:ProgressErrorMessage = $progressMessage
    }
    
    if ($StopExecution) {
        Write-Log -Critical $messageToLog
    } else {
        Write-Log -Error $messageToLog
    }       
}