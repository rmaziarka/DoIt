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

function Update-SqlLogin {
    <# 
    .SYNOPSIS 
    Creates or updates database login on MSSQL Server.

    .PARAMETER ConnectionString
    Connection string.

    .PARAMETER Username
    Username.

    .PARAMETER Password
    Password.

    .PARAMETER WindowsAuthentication
    Whether this login uses Windows Authentication (if not set, it will use SQL Server Authentication).

    .PARAMETER ServerRoles
    List of server roles to assign to the user. Note roles are only added, not removed.

    .EXAMPLE
    Update-SqlLogin -ConnectionString "data source=localhost;integrated security=True" -Username "username" -Password "password"
    #> 

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $ConnectionString,
        
        [Parameter(Mandatory=$true)]
        [string]
        $Username,
        
        [Parameter(Mandatory=$false)]
        [string]
        $Password,
        
        [Parameter(Mandatory=$false)]
        [switch]
        $WindowsAuthentication,

        [Parameter(Mandatory=$false)]
        [string[]]
        $ServerRoles
    )
    $sqlScript = Join-Path -Path $PSScriptRoot -ChildPath 'Update-SqlLogin.sql'

    if ([string]::IsNullOrEmpty($Password) -and !$WindowsAuthentication) {
        Write-Log -Critical "Empty password when WindowsAuthentication is set to false"
    }
    
    if ($WindowsAuthentication) {
        $WinAuth = "1"
    } else {
        $WinAuth = "0"
    }
    
    $parameters =  @{ 
        Username = $Username 
        Password = $Password 
        WindowsAuthentication = $WinAuth
    }

   [void](Invoke-Sql -ConnectionString $connectionString -InputFile $sqlScript -SqlCmdVariables $parameters -IgnoreInitialCatalog)

   $sqlScript = Join-Path -Path $PSScriptRoot -ChildPath 'Update-SqlLoginRole.sql'
   foreach ($role in $ServerRoles) {
     [void](Invoke-Sql -ConnectionString $connectionString -InputFile $sqlScript -SqlCmdVariables @{ Username = $Username; Role = $role } -IgnoreInitialCatalog)
   }
}