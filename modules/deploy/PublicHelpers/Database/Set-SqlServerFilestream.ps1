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

function Set-SqlServerFilestream {
    <#
    .SYNOPSIS
    Sets SQL Server Filestream to given level.

    .DESCRIPTION
    It does the following:
    1. Check filestream is at given level globally on SQL Server instance level, and if not set it using WMI. 
    2. If level has been changed restart SQL Server service.
    3. Check filestream is at given level at T-SQL level, and if not set it using SQL query.
    
    Note if SQL Server is not on local machine, you might need to pass $ConnectionParams, as it needs to open 3 kind of connections:
    - WMI connection (only $ConnectionParams.Credential is used)
    - WinRM to restart service (whole $ConnectionParams is used)
    - SQL query ($ConnectionString is used)

    .PARAMETER ConnectionString
    Connection string to database.

    .PARAMETER FilestreamLevel
    Filestream level to set: 
    - 0 - disabled
    - 1 - enabled for T-SQL access
    - 2 - enabled for T-SQL and Win32 streaming access

    .PARAMETER ConnectionParams
    ConnectionParameters object as created by [[New-ConnectionParameters]] - required only for configuring remote SQL Server instances
    using non-current user.

    .EXAMPLE
    Set-SqlServerFilestream -ConnectionString 'Data Source=localhost\SQLEXPRESS;Integrated Security=SSPI' -FilestreamLevel 2

    Enables Filestream on local instance SQLEXPRESS.

    .EXAMPLE
    Set-SqlServerFilestream -ConnectionString 'Data Source=server;Integrated Security=SSPI' -FilestreamLevel 2 `
                            -ConnectionParams (New-ConnectionParameters -Nodes 'server' -Credential $cred)

    Enables Filestream on remote default SQL Server instance using non-default credentials.
    #>

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string] 
        $ConnectionString,

        [Parameter(Mandatory=$true)]
        [int] 
        $FilestreamLevel,

        [Parameter(Mandatory=$false)]
        [object] 
        $ConnectionParams
    )

    Write-Log -Info "Setting filestream level at $ConnectionString to $FilestreamLevel"

    $csb = New-Object -TypeName System.Data.SqlClient.SqlConnectionStringBuilder -ArgumentList $ConnectionString
    $dataSource = $csb.'Data Source'
    if ($dataSource -imatch '([^\\]+)\\(.+)') {
        $computerName = $Matches[1]
        $instanceName = $Matches[2]
        $sqlServiceName = 'MSSQL${0}' -f $instanceName
    } else {
        $computerName = $dataSource
        $instanceName = 'MSSQLSERVER'
        $sqlServiceName = $instanceName
    }

    if (!$ConnectionParams) {
        $ConnectionParams = New-ConnectionParameters -Nodes $computerName
    }

    $wmiParams = @{
        ComputerName = $ConnectionParams.Nodes
    }
    if ($ConnectionParams.Credential) {
        $wmiParams.Credential = $ConnectionParams.Credential
    }

    $sqlServerNamespaces = Get-WmiObject @wmiParams -Namespace 'ROOT\Microsoft\SqlServer' -class '__Namespace' -ErrorAction SilentlyContinue | `
        Where-Object { $_.Name.StartsWith('ComputerManagement') } | Select-Object -ExpandProperty Name
    if (!$sqlServerNamespaces) {
        if ($Error.Count -gt 0) { 
            $errMsg = $Error[0].ToString()
        } else {
            $errMsg = ''
        }
        throw "Cannot get SQL Server WMI namespace from '$computerName': $errMsg."
    }

    $wmiObjects = @()
    foreach ($namespace in $sqlServerNamespaces) { 
        $wmiObjects += Get-WmiObject @wmiParams -Namespace "ROOT\Microsoft\SqlServer\$namespace" -Class 'FilestreamSettings' | where { $_.InstanceName -eq $instanceName }
    }

    if (!$wmiObjects) {
        throw "Cannot find any SQL Server WMI object for instance '$instanceName' at '$($wmiParams.ComputerName)' from namespace ROOT\Microsoft\SqlServer - check your instance name is correct: '$instanceName'"
    }

    $changed = $false
    $numWmiInstancesCorrect = 0
    foreach ($wmiObject in $wmiObjects) { 
        if ($wmiObject.AccessLevel -ne $FilestreamLevel) {
            Write-Log -Info "WMI $($wmiObject.__PATH) - setting filestream from $($wmiObject.AccessLevel) to $FilestreamLevel."
            $result = $wmiObject.EnableFilestream($FilestreamLevel, $instanceName)
            if ($result.ReturnValue -eq 0) {
                $changed = $true
                $numWmiInstancesCorrect++
            } else {
                Write-Log -Warn "Failed to set filestream at $($wmiObject.__PATH) - return value from wmi.EnableFilestream: $($result.ReturnValue)"
            }
        } else {
            Write-Log -Info "WMI $($wmiObject.__PATH) - filestream already at level $($wmiObject.AccessLevel)."
            $numWmiInstancesCorrect++
        }
    }

    if ($numWmiInstancesCorrect -eq 0) {
        throw "Failed to set filestream on any WMI objects."
    }

    if ($changed) {
        Write-Log -Info "Restarting service $sqlServiceName at '$($ConnectionParams.Nodes)'"
        $psSessionParams = $ConnectionParams.PSSessionParams
        Invoke-Command @psSessionParams -ScriptBlock { 
            Restart-Service -Name $using:sqlServiceName -Force # TODO: what about SQL Server Agent?
        }
    }

    $currentFilestreamLevel = Invoke-Sql -ConnectionString $ConnectionString -Query "select serverproperty('FilestreamEffectiveLevel')" -SqlCommandMode Scalar -DatabaseName ''
    if ($currentFileStreamLevel -ne $FilestreamLevel) { 
        Write-Log -Info "Setting filestream to level $FilestreamLevel - SQL"
        Invoke-Sql -ConnectionString $ConnectionString -Query "EXEC sp_configure filestream_access_level, ${FilestreamLevel}; RECONFIGURE" -SqlCommandMode NonQuery -DatabaseName ''
        $changed = $true
    }

    if ($changed) {
        Write-Log -Info "Filestream successfully changed to level $FilestreamLevel."
    } else {
        Write-Log -Info "Filestream already at level $FilestreamLevel."
    }
}
