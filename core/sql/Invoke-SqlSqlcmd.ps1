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

function Invoke-SqlSqlcmd {
    <# 
    .SYNOPSIS 
    Runs a T-SQL script using sqlcmd.exe. 
    
    .DESCRIPTION 
    Runs sql command or sql script file. Gives proper error handling as opposed to Invoke-Sqlcmd.
    See https://connect.microsoft.com/SQLServer/feedback/details/779320/invoke-sqlcmd-does-not-return-t-sql-errors.
    
    .PARAMETER ConnectionStringBuilder
    SqlConnectionStringBuilder object.
    
    .PARAMETER Query
    Sql query that will be run (if not specified, $InputFile will be used).
    
    .PARAMETER InputFile
    File containing sql query to run (if not specified, $Query will be used).
    
    .PARAMETER IgnoreErrors
    If set ignore errors when sqlcmd.exe is running.
    
    .PARAMETER QueryTimeoutInSeconds
    Query timeout.

    .PARAMETER ConnectTimeoutInSeconds
    Connect timeout.
    
    .PARAMETER SqlCmdVariables
    Hashtable containing sqlcmd variables.

    .PARAMETER Credential
    Credential to impersonate in Integrated Security mode.

    .EXAMPLE
    Invoke-SqlSqlcmd -ConnectionString $connectionString -Sql $Query -SqlCmdVariables $param
    #> 

    [CmdletBinding()] 
    [OutputType([string])]
    param( 
        [Parameter(Mandatory=$true)] 
        [object]
        $ConnectionStringBuilder, 
    
        [Parameter(Mandatory=$false)] 
        [string]
        $Query,
    
        [Parameter(Mandatory=$false)] 
        [string]
        $InputFile,
    
        [Parameter(Mandatory=$false)] 
        [bool]
        $IgnoreErrors,
    
        [Parameter(Mandatory=$true)] 
        [int]
        $QueryTimeoutInSeconds,

        [Parameter(Mandatory=$true)] 
        [int]
        $ConnectTimeoutInSeconds,
    
        [Parameter(Mandatory=$false)] 
        [hashtable]
        $SqlCmdVariables,

        [Parameter(Mandatory=$false)]
        [PSCredential] 
        $Credential
    ) 

    [string[]]$params = ""

    if ($InputFile) {
        $params += "-i `"$InputFile`""
    } else { 
        $params += "-Q ""$Query"""
    }

    $serverAddress = $ConnectionStringBuilder.DataSource
    
    if (![string]::IsNullOrEmpty($ConnectionStringBuilder.InitialCatalog)) {
        $params += "-d $($ConnectionStringBuilder.InitialCatalog)"
    }
    
    if (![string]::IsNullOrEmpty($ConnectionStringBuilder.UserID) -and ![string]::IsNullOrEmpty($ConnectionStringBuilder.Password)) {
        $params += "-U $($ConnectionStringBuilder.UserID)"
        $params += "-P ""$($ConnectionStringBuilder.Password)"""
    } else {
        $params += '-E'
    }
    
    if ($SqlCmdVariables) {
        $sqlCmdVariables.GetEnumerator() | Foreach-Object { $params += "-v $($_.key)=""$($_.value)""" }
    }

    if (!$IgnoreErrors) {
        $params += '-b'
    } 

    $output = ''

    $startSqlCmdParams = @{ Command=$sqlcmd;
             ArgumentList="-S $serverAddress -t $QueryTimeoutInSeconds -l $ConnectTimeoutInSeconds $params -w 65535 -h -1 -W -s "",""";
             Output=([ref]$output);
             Credential=$Credential;
             }

    if ($Credential) {
        # this is to ensure we don't get error 'The directory name is invalid'
        $startSqlCmdParams.WorkingDirectory = (Get-Location)
        Write-Log -Info "Running sqlcmd as user '$($Credential.UserName)'"
    }

    [void](Start-ExternalProcess @startSqlCmdParams)
 
    return $output
}