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

    .PARAMETER ConnectionString
    Connection string.

    .PARAMETER DatabaseName
    Database name - if not specified, Initial Catalog from ConnectionString will be used.

    .PARAMETER Path
    Backup file path.

    .PARAMETER Credential
    Credential to impersonate in Integrated Security mode.

    .PARAMETER RemoteShareCredential
    Remote share credential to use if $Path is an UNC path. Note the file will be copied to localhost if this set, and this will work only if 
    you're connecting to local database.

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
        $ConnectionString,

        [Parameter(Mandatory=$false)]
        [string]
        $DatabaseName, 
        
        [Parameter(Mandatory=$true)]
        [string]
        $Path,

        [Parameter(Mandatory=$false)]
        [PSCredential] 
        $Credential,

        [Parameter(Mandatory=$false)]
        [PSCredential] 
        $RemoteShareCredential,
            
        [Parameter(Mandatory=$false)] 
        [int]
        $QueryTimeoutInSeconds = 3600
    )

    try { 
        if (!$DatabaseName) { 
            $csb = New-Object -TypeName System.Data.SqlClient.SqlConnectionStringBuilder -ArgumentList $ConnectionString
            $DatabaseName = $csb.InitialCatalog
        }
        if (!$DatabaseName) {
            throw "No database name - please specify -DatabaseName or add Initial Catalog to ConnectionString."
        }

        if ($RemoteShareCredential) {
            $shareDir = Split-Path -Path $Path -Parent
            #TODO: disconnect-share by prefix
            Connect-Share -Path $shareDir -Credential $RemoteShareCredential
            $tempDir = New-TempDirectory
            Write-Log -Info "Copying '$Path' to '$tempDir'"
            Copy-Item -Path $Path -Destination $tempDir -Force
            #TODO: unhardcode this user
            Set-SimpleAcl -Path $tempDir -User 'NT Service\MSSQLSERVER' -Permission 'Read' -Type 'Allow'
            $Path = Join-Path -Path $tempDir -ChildPath (Split-Path -Path $Path -Leaf)
        }

        $sqlScript = Join-Path -Path $PSScriptRoot -ChildPath "Restore-SqlDatabase.sql"
        $parameters =  @{ "DatabaseName" = $DatabaseName }
        $parameters += @{ "Path" = $Path }
        [void](Invoke-Sql -ConnectionString $ConnectionString -InputFile $sqlScript -SqlCmdVariables $parameters -Credential $Credential -QueryTimeoutInSeconds $QueryTimeoutInSeconds -DatabaseName '')
    } finally {
        if ($RemoteShareCredential) {
            Disconnect-Share -Path $shareDir
            Remove-TempDirectory
        }
    }
}