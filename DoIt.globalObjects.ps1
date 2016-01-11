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

$Global:DoItGlobalConfiguration = [PSCustomObject]@{
    # Logging level threshold - available values: DEBUG, INFO, WARN, ERROR, CRITICAL
    LogLevel = [DoIt.LogSeverity]::DEBUG;

    # Path to file log or $null if shouldn't log to file. 
    LogFile = $null;

    # Name of Event Log Source to log to or $null if shouldn't log to Event Log.
    LogEventLogSource = $null;         

    # Logging level threshold for Event Log - available values: DEBUG, INFO, WARN, ERROR, CRITICAL. 
    # This would normally have higher threshold than LogLevel.
    LogEventLogThreshold = [DoIt.LogSeverity]::ERROR; 

    # If true and Event Log Source specified in LogEventLogSource is not available,
    # it will be created automatically.
    # Note: Event Log Source creation requires Administrative privileges
    LogEventLogCreateSourceIfNotExists = $false;

    # If $null then it means that script is executed on the current machine (without remoting)
    # PSRemoting - means script is executed remotely using psremoting mechanism
    # WebDeployHandler - means script is executed remotely using web deployment hanlder (IIS handler)
    # WebDeployAgentService - means script is executed remotely using remote agent service
    RemotingMode = $null;

    # ConfigurationPaths object created in Initialize-ConfigurationPaths. It has following properties:
    # ProjectRootPath         - base directory of the project, relative to the directory where this script resides (it is used as a base directory for other directories)
    # PackagesPath            - path to directory with packages
    # PackagesContainDeployScripts - $true if $PackagesPath exists and contains DeployScripts / DoIt
    # DeployConfigurationPath - path to directory with configuration files
    # DeployScriptsPath       - path to directory with deploy.ps1
    ConfigurationPaths = $null

    # If not $null, it means deployment runs under CI Server (currently supported: TeamCity)
    CIServer = $null

    # If $true, 'exit 1' will be run on error (otherwise an exception will be thrown).
    # This is useful if running with "powershell -File" as it doesn't return non-zero exit code on exceptions.
    # Also for some CI Servers (to ensure build is make red, e.g. TeamCity < 9).
    # In case you want to catch critical errors, or the script is running in ISE, you need to set it to $false.
    ExitImmediatelyOnError = $false

}

if (Test-Path -LiteralPath Variable:Global:DoItRemotingMode) {
    $Global:DoItGlobalConfiguration.RemotingMode = $Global:DoItRemotingMode
}

if (Test-Path -LiteralPath Variable:Global:DoItCIServer) {
    $Global:DoItGlobalConfiguration.CIServer = $Global:DoItCIServer
} elseif ($env:TEAMCITY_VERSION) {
    $Global:DoItGlobalConfiguration.CIServer = 'TeamCity'
}
