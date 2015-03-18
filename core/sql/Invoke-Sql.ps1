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

function Invoke-Sql {
    <# 
    .SYNOPSIS 
    Runs a T-SQL script using sqlcmd.exe. 
    
    .DESCRIPTION 
    Runs sql command or sql script file 
    
    .PARAMETER ConnectionString
    Connection string.
    
    .PARAMETER Query
    Sql queries that will be run.
    
    .PARAMETER InputFile
    File(s) containing sql query to run.

    .PARAMETER Mode
    Determines how the sql is run - by sqlcmd.exe or .NET SqlCommand.

    .PARAMETER SqlCommandMode
    Sql command mode to use if Mode = .net (NonQuery / Scalar / Dataset). Ignored if mode is different than .net.
    
    .PARAMETER IgnoreErrors
    If set ignore errors when sqlcmd.exe is running
    
    .PARAMETER QueryTimeoutInSeconds
    Query timeout.

    .PARAMETER ConnectTimeoutInSeconds
    Connect timeout.
    
    .PARAMETER SqlCmdVariables
    Hashtable containing sqlcmd variables.

    .PARAMETER Credential
    Credential to impersonate in Integrated Security mode.

    .PARAMETER IgnoreInitialCatalog
    If $true, InitialCatalog will be removed from ConnectionString (if present).

    .OUTPUTS
    String if Mode = sqlcmd.
    System.Data.DataSet if Mode = .net.

    .EXAMPLE
    Invoke-Sql -ConnectionString $connectionString -Sql $Query-TimeoutInSeconds -SqlCmdVariables $param
    #> 

    [CmdletBinding()] 
    [OutputType([object])]
    param( 
        [Parameter(Mandatory=$true)] 
        [string]
        $ConnectionString, 
    
        [Parameter(Mandatory=$false)] 
        [string[]]
        $Query,
    
        [Parameter(Mandatory=$false)] 
        [string[]]
        $InputFile,

        [Parameter(Mandatory=$false)] 
        [string]
        [ValidateSet($null, 'sqlcmd', '.net')]
        $Mode = '.net',

        [Parameter(Mandatory=$false)] 
        [string]
        [ValidateSet($null, 'NonQuery', 'Scalar', 'Dataset')]
        $SqlCommandMode = 'Dataset',
    
        [Parameter(Mandatory=$false)] 
        [bool]
        $IgnoreErrors,
    
        [Parameter(Mandatory=$false)] 
        [int]
        $QueryTimeoutInSeconds = 120,

        [Parameter(Mandatory=$false)] 
        [int]
        $ConnectTimeoutInSeconds = 8,
    
        [Parameter(Mandatory=$false)] 
        [hashtable]
        $SqlCmdVariables,

        [Parameter(Mandatory=$false)]
        [PSCredential] 
        $Credential,

        [Parameter(Mandatory=$false)]
        [switch] 
        $IgnoreInitialCatalog
    ) 

    if (!$Mode) {
        $Mode = '.net'
    }

    if (!$Query -and !$InputFile) {
        Write-Log -Critical 'Missing -Query or -InputFile parameter'
    }

    if ($Mode -eq 'sqlcmd') {
        $sqlCmdPath = Get-CurrentSqlCmdPath
        if (!$sqlCmdPath) {
            Write-Log -Warn 'Cannot find sqlcmd.exe - falling back to .NET'
            $Mode = '.net'
        }
    }

    if ($InputFile) {
        foreach ($file in $Inputfile) { 
            if (!(Test-Path -Path $file)) { 
                Write-Log -Critical "$InputFile does not exist. Current directory: $(Get-Location)"
            }
        }
    }
      
    $csb = New-Object -TypeName System.Data.SqlClient.SqlConnectionStringBuilder -ArgumentList $ConnectionString

    if ($IgnoreInitialCatalog -and $csb.InitialCatalog) {
        $csb.set_InitialCatalog('')
    }

    $params = @{
        ConnectionStringBuilder = $csb
        IgnoreErrors = $IgnoreErrors
        QueryTimeoutInSeconds = $QueryTimeoutInSeconds
        ConnectTimeoutInSeconds = $ConnectTimeoutInSeconds
        SqlCmdVariables = $SqlCmdVariables
        Credential = $Credential
    }

    $targetLog = "$($csb.DataSource)"
    if ($csb.InitialCatalog) {
        $targetLog += " / $($csb.InitialCatalog)"
    }

    if ($Mode -eq 'sqlcmd') {
        foreach ($q in $Query) { 
            $params['Query'] = $q
            if ($q.Length -gt 40) {
                $qLog = ($q.Substring(0, 40) -replace "`r", '' -replace "`n", '; ') + '...'
            } else {
                $qLog = $q
            }
            Write-Log -_Debug "Running custom query at $targetLog using sqlcmd (${qLog}...)"
            Invoke-SqlSqlcmd @params
        }

        [void]($params.Remove('Query'))
        foreach ($file in $InputFile) {
            $file = (Resolve-Path -Path $file).ProviderPath
            $params['InputFile'] = $file
            Write-Log -_Debug "Running sql file '$file' at $targetLog using sqlcmd"
            Invoke-SqlSqlcmd @params
        }

    } elseif ($Mode -eq '.net') {
        $params['Mode'] = $SqlCommandMode
        foreach ($q in $Query) { 
            $params['Query'] = $q
            if ($q.Length -gt 40) {
                $qLog = ($q.Substring(0, 40) -replace "`r", '' -replace "`n", '; ') + '...'
            } else {
                $qLog = $q
            }
            Write-Log -_Debug "Running custom query at $targetLog using .Net (${qLog})"
            Invoke-SqlDotNet @params
        }

        foreach ($file in $InputFile) {
            $file = (Resolve-Path -Path $file).ProviderPath
            Write-Log -_Debug "Running sql file '$file' at $targetLog using .Net"
            $params['Query'] = Get-Content -Path $file -ReadCount 0 | Out-String
            Invoke-SqlDotNet @params
        }
    } else {
        Write-Log -Critical "Unrecognized mode: ${Mode}."
    }

}