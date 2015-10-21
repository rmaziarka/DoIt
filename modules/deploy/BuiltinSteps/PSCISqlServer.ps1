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

Configuration PSCISqlServer {

    <#
    .SYNOPSIS
    Ensures SQL Server is installed with specific options.

    .DESCRIPTION
    This is DSC configuration, so it should be invoked locally (but can also be invoked with -RunRemotely).
    It uses following tokens:
    - **SqlServerSourcePath** - (Required) UNC path to the root of the source files for installation. Note if you want to install from ISO, you need to first mount it.
    - **SetupCredential** - (Required) Credential to be used to perform the installation.
    - **Features** - (Required) SQL features to be installed. Following features are available in SQL Server 2016 (most of them also in previous versions):
      - SQL - SQL Server Database Engine (SQLEngine), Replication (Replication), Fulltext (FullText) and Data Quality Server (DQ)
      - AS - all Analysis Services components
      - RS - all Reporting Services components
      - IS - all Integration Services components
      - DQC - Data Quality Client
      - MDS - Master Data Services
      - SSMS - SQL Server Management Tools - Basic
      - ADV_SSMS - SQL Server Management Tools - Complete
      - BIDS - SQL Server Data Tools (SSDT)
      - BC - Backward compatibility components
      - BOL - SQL Server Books Online
      - Conn - Connectivity components
      - DREPLAY_CTLR - Distributed Replay Controller
      - DREPLAC_CLT - Distributed Replay Client
      - SNAC_SDK - SDK for Microsoft SQL Server Native Client
      - SDK - Software Development Kit
      - LocalDB - LocalDB
    - **SQLCollation** - (Required) Collation for SQL Server (e.g. Latin1_General_CI_AS).
    - **InstanceName** - SQL instance to be installed. If not specified, default instance (MSSQLSERVER) will be used.
    - **ConfigureFirewall** - if true, firewall will be opened for installed features.
    - **InstanceDir** - Installation path for SQL instance files.
    - **SQLSysAdminAccounts** - Array of accounts to be made SQL administrators.
    - **SecurityMode** - SQL security mode - can be 'SQL' or 'Windows' (default). 
    - **SAPwd** - SA password, if SecurityMode=SQL.
    - **InstallSQLDataDir** - Root path for SQL database files.
    - **SQLUserDBDir** - Path for SQL database files.
    - **SQLUserDBLogDir** - Path for SQL log files.
    - **SQLTempDBDir** - Path for SQL TempDB files.
    - **SQLTempDBLogDir** - Path for SQL TempDB log files.
    - **SQLBackupDir** - Path for SQL backup files.
    - **ASCollation** - Collation for Analysis Services.
    - **ASSysAdminAccounts** - Array of accounts to be made Analysis Services admins.
    - **ASDataDir** - Path for Analysis Services data files.
    - **ASLogDir** - Path for Analysis Services log files.
    - **ASBackupDir** - Path for Analysis Services backup files.
    - **ASTempDir** - Path for Analysis Services temp files.
    - **ASConfigDir** - Path for Analysis Services config.
    
    Note it can also install missing features.
    Note currently non-default service accounts are not supported. If you need to use non-default ones please create your own configuration basing on this one.

    See also [xSQLServer](https://github.com/PowerShell/xSQLServer).

    .EXAMPLE
    ```
    Import-Module "$PSScriptRoot\..\PSCI\PSCI.psd1" -Force

    # clear any old Environment definitions - required only for -NoConfigFiles deployments
    $Global:Environments = @{}

    Environment Local { 
        ServerConnection WebServer -Nodes localhost
        ServerRole Database -Steps 'PSCISqlServer' -ServerConnection WebServer

        Tokens Database @{
            SqlServerSourcePath = 'e:\'
            WindowsSourcePath = '\\localhost\InstallPackages\WindowsServer'
            IsClientWindows = $false
            SetupCredential = { $Tokens.Credential.Credential }
            Features = 'SQLENGINE', 'SSMS', 'ADV_SSMS'
            InstanceName = 'MSSQLSERVER'
            SQLCollation = 'Latin1_General_CI_AS'
            InstallSQLDataDir = 'C:\SQLServerData\Data'
            SQLUserDBLogDir = 'C:\SQLServerData\Log'
            SQLBackupDir = 'C:\SQLServerData\Backup'
            ConfigureFirewall = $true
        }
    }

    Install-DscResources -ModuleNames 'xSQLServer', 'xDismFeature'

    try { 
        Start-Deployment -Environment Local -NoConfigFiles
    } catch {
        Write-ErrorRecord
    }
    ```
    Configures SQL Server according to the settings specified in 'Database' tokens section.
    #>
    
    Import-DSCResource -ModuleName xSQLServer
    Import-DSCResource -ModuleName xDismFeature

    Node $AllNodes.NodeName {

        $sqlServerSourcePath = Get-TokenValue -Name 'SqlServerSourcePath' 

        if (!$sqlServerSourcePath) {
            Write-Log -Warn 'No SqlServerSourcePath defined in tokens - SQL Server will not be installed.'
            return
        }
        
        $options = @{
            SqlServerSourcePath = $sqlServerSourcePath
            WindowsSourcePath = Get-TokenValue -Name 'WindowsSourcePath'
            IsClientWindows = Get-TokenValue -Name 'IsClientWindows'
            SetupCredential = Get-TokenValue -Name 'SetupCredential' -Mandatory
            Features = (Get-TokenValue -Name 'Features' -Mandatory) -join ','
            SQLCollation = Get-TokenValue -Name 'SQLCollation' -Mandatory
            ConfigureFirewall = Get-TokenValue -Name 'ConfigureFirewall'

            InstanceName = Get-TokenValue -Name 'InstanceName'
            InstanceDir = Get-TokenValue -Name 'InstanceDir'
            SQLSysAdminAccounts = Get-TokenValue -Name 'SQLSysAdminAccounts'
            SecurityMode = Get-TokenValue -Name 'SecurityMode'
            SAPwd = Get-TokenValue -Name 'SAPWd'
            InstallSQLDataDir = Get-TokenValue -Name 'InstallSQLDataDir'
            SQLUserDBDir = Get-TokenValue -Name 'SQLUserDBDir'
            SQLUserDBLogDir = Get-TokenValue -Name 'SQLUserDBLogDir'
            SQLTempDBDir = Get-TokenValue -Name 'SQLTempDBDir'
            SQLBackupDir = Get-TokenValue -Name 'SQLBackupDir'
            ASCollation = Get-TokenValue -Name 'ASCollation'
            ASSysAdminAccounts = Get-TokenValue -Name 'ASSysAdminAccounts'
            ASDataDir = Get-TokenValue -Name 'ASDataDir'
            ASLogDir = Get-TokenValue -Name 'ASLogDir'
            ASBackupDir = Get-TokenValue -Name 'ASBackupDir'
            ASTempDir = Get-TokenValue -Name 'ASTempDir'
            ASConfigDir = Get-TokenValue -Name 'ASConfigDir'
        }

        if ($options.SecurityMode -eq 'SQL' -and !$options.SAPwd) {
            throw 'SAPwd must be specified when SecurityMode is SQL.'
        }

        if ($options.SecurityMode -and $options.SecurityMode -ne 'SQL' -and $options.SecurityMode -ne 'Windows') {
            throw "SecurityMode value is incorrect: '$($options.SecurityMode)' - can be 'SQL' or 'Windows'"
        }

        if (!$options.instanceName) {
            $options.instanceName = 'MSSQLSERVER'
        }

        Write-Log -Info "Preparing .NET 3.5 - source '$($options.WindowsSourcePath)', IsClientWindows: '$($options.IsClientWindows)"
        
        $depends = ''
        if ($options.IsClientWindows -or $options.IsClientWindows -eq $null) {
            xDismFeature Net35 {
                Name = 'NetFx3'
            }
            $depends = '[xDismFeature]Net35'
        } else {
            WindowsFeature Net35 {
                Name = 'NET-Framework-Core'
                Source = $options.windowsSourcePath
            }
            $depends = '[WindowsFeature]Net35'
        }
        
        Write-Log -Info ('Preparing SQL Server instance - parameters: {0}' -f (Convert-HashtableToString -Hashtable $options))

        xSQLServerSetup DatabaseSetup {
            SourcePath = $options.SqlServerSourcePath
            SourceFolder = ''
            SetupCredential = $options.SetupCredential
            UpdateEnabled = 'False' 
            UpdateSource = ''
            Features = $options.Features
            InstanceName = $options.InstanceName
            InstanceDir = $options.InstanceDir
            SQLCollation = $options.SQLCollation
            SQLSysAdminAccounts = $options.SQLSysAdminAccounts
            SecurityMode = $options.SecurityMode
            SAPwd = $options.SAPWd
            InstallSQLDataDir = $options.InstallSQLDataDir
            SQLUserDBDir = $options.SQLUserDBDir
            SQLUserDBLogDir = $options.SQLUserDBLogDir
            SQLTempDBDir = $options.SQLTempDBDir
            SQLBackupDir = $options.SQLBackupDir
            ASCollation = $options.ASCollation
            ASSysAdminAccounts = $options.ASSysAdminAccounts
            ASDataDir = $options.ASDataDir
            ASLogDir = $options.ASLogDir
            ASBackupDir = $options.ASBackupDir
            ASTempDir = $options.ASTempDir
            ASConfigDir = $options.ASConfigDir
            DependsOn  = $dependsOn
        }

        if ($options.ConfigureFirewall) { 
            xSQLServerFirewall DatabaseFirewall {
                Ensure  = 'Present'
                SourcePath = $options.SqlServerSourcePath
                SourceFolder  = ''
                Features = $options.Features
                InstanceName = $options.InstanceName
                DependsOn = '[xSQLServerSetup]DatabaseSetup'
            }
        }
    }
}
