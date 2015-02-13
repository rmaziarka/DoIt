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

function Restore-SqlDatabase {
    <# 
    .SYNOPSIS 
    Restores database on MSSQL Server.

    .DESCRIPTION 
    Uses Invoke-RestoreDatabase.sql sql script to restore database. 

    .PARAMETER DatabaseName
    Database name

    .PARAMETER ConnectionString
    Connection string

    .PARAMETER Path
    Backup file path

    .PARAMETER Credential
    Credential to impersonate in Integrated Security mode.

    .PARAMETER QueryTimeoutInSeconds
    Timeout for executing sql restore command.

    .EXAMPLE
    Restore-SqlDatabase -DatabaseName "DbName" -ConnectionString "data source=localhost;integrated security=True" -Path "C:\database.bak"
    #> 

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $DatabaseName, 

        [Parameter(Mandatory=$true)]
        [string]
        $ConnectionString,
        
        [Parameter(Mandatory=$true)]
        [string]
        $Path,

        [Parameter(Mandatory=$false)]
        [PSCredential] 
        $Credential,
            
        [Parameter(Mandatory=$false)] 
        [int]
        $QueryTimeoutInSeconds = 600
    )

    $sqlScript = Join-Path -Path $PSScriptRoot -ChildPath "Restore-SqlDatabase.sql"
    $parameters =  @{ "DatabaseName" = $DatabaseName }
    $parameters += @{ "Path" = $Path }
    $result = Invoke-Sql -ConnectionString $ConnectionString -InputFile $sqlScript -SqlCmdVariables $parameters -Credential $Credential -QueryTimeoutInSeconds $QueryTimeoutInSeconds
    if ($result) { 
        Write-Log -Info $result
    }
}

