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

function Update-SqlUser {
    <# 
    .SYNOPSIS 
    Update User on given database.

    .DESCRIPTION 
    Uses Invoke-CreateSqlUser.sql sql script to create login for user to specific database. If user exists then it is remapped to current login.
    DbRoles should be given in pipe-separated format

    .PARAMETER ConnectionString
    Connection String

    .PARAMETER DatabaseName
    Database name

    .PARAMETER Username
    Username

    .PARAMETER DbRole
    Db roles to apply

    .EXAMPLE
    Update-SqlUser -ConnectionString $connectionString -DatabaseName "database" -Username "username"  -DbRole "db_owner|db_datareader"
    #> 
    
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $ConnectionString,
    
        [Parameter(Mandatory=$true)]
        [string]
        $DatabaseName,
    
        [Parameter(Mandatory=$true)]
        [string]$Username,
    
        [Parameter(Mandatory=$false)]
        [string]$DbRole
    )
    $sqlScript = Join-Path -Path $PSScriptRoot -ChildPath "Update-SqlUser.sql"
    $parameters =  @{ "Username" = $Username }
    $parameters += @{ "DatabaseName" = $DatabaseName }
    $parameters += @{ "Role" = $DbRole }
    $result = Invoke-Sql -ConnectionString $ConnectionString -InputFile $sqlScript -SqlCmdVariables $parameters
    if ($result) { 
        Write-Log -Info $result
    }
}