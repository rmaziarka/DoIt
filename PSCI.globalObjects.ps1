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

$PSCIGlobalConfiguration = [PSCustomObject]@{
    # Logging level threshold - available values: DEBUG, INFO, WARN, ERROR, CRITICAL
    LogLevel = [PSCI.LogSeverity]::INFO;

    # Path to file log or $null if shouldn't log to file. 
    LogFile = $null;

    # Name of Event Log Source to log to or $null if shouldn't log to Event Log.
    LogEventLogSource = $null;         

    # Logging level threshold for Event Log - available values: DEBUG, INFO, WARN, ERROR, CRITICAL. 
    # This would normally have higher threshold than LogLevel.
    LogEventLogThreshold = [PSCI.LogSeverity]::ERROR; 

    # If true and Event Log Source specified in LogEventLogSource is not available,
    # it will be created automatically.
    # Note: Event Log Source creation requires Administrative privileges
    LogEventLogCreateSourceIfNotExists = $false;

    # If $null then it means that script is executed on the current machine (without remoting)
    # PSRemoting - means script is executed remotely using psremoting mechanism
    # WebDeployHandler - means script is executed remotely using web deployment hanlder (IIS handler)
    # WebDeployAgentService - means script is executed remotely using remote agent service
    RemotingMode = $null;
}

if (Test-Path -Path Variable:Global:RemotingMode) {
    $PSCIGlobalConfiguration.RemotingMode = $Global:RemotingMode
}