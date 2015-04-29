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

function Backup-SqlDatabase {
    <#
    .SYNOPSIS
    Creates SQL database backup.

    .DESCRIPTION
    Uses Invoke-Sql cmdlet to run Backup-SqlDatabase SQL script to backup database. 

    .PARAMETER ConnectionString
    Connection string
  
    .PARAMETER DatabaseName
    The name of the database to be backed up.

    .PARAMETER BackupPath
    The folder path where backup will be stored.
    
    .PARAMETER BackupName
    The name of the backup. If you add placehodler {0} to BackupName, current date will be inserted.
    
    .PARAMETER Credential
    Credentials for a SQL Server.

    .EXAMPLE
    Backup-SqlDatabase -DatabaseName "DbName" -ConnectionString "data source=localhost;integrated security=True" -BackupPath "C:\db_backups\" -BackupName "DbName{0}.bak"
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
        [string]
        $BackupPath,

        [Parameter(Mandatory=$true)]
        [string]
        $BackupName,

        [Parameter(Mandatory=$false)]
        [PSCredential] 
        $Credential
    )

    $BackupName = if ($BackupName.Contains('{0}')) { $BackupName -f $(Get-Date -Format yyyy-MM-dd_HH-mm-ss) } else { $BackupName }
    $BackupFullPath = Join-Path -Path $BackupPath -ChildPath $BackupName

    $sqlScript = Join-Path -Path $PSScriptRoot -ChildPath "Backup-SqlDatabase.sql"
    $parameters = @{ 
        DatabaseName = $DatabaseName
        BackupPath = $BackupFullPath
    }

    Write-Log -Info "Start creating database $DatabaseName backup to location $BackupFullPath"
    [void](Invoke-Sql -ConnectionString $ConnectionString -InputFile $sqlScript -SqlCmdVariables $parameters -Credential $Credential -DatabaseName '')
}