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

$curDir = Split-Path -Parent $MyInvocation.MyCommand.Definition 
Get-ChildItem -Recurse $curDir -Include *.ps1 | Where-Object { $_ -notmatch ".Tests.ps1" } | Foreach-Object {
    . $_.FullName      
}

Export-ModuleMember -Function `
    Add-QuotesToPaths, `
    Convert-LocalUncPathToLocalPath, `
    Convert-XmlUsingXdt, `
    Get-CurrentUser, `
    Get-PSCIBuildNumber, `
    Get-PSCIModulePath, `
    Get-ProgramFilesx86Path, `
    Import-Carbon, `
    Import-SQLPSXSSIS, `
    Get-PathToExternalLib, `
    Import-ExternalLib, `
    Invoke-ExternalCommand, `
    Start-ExternalProcess, `
    Invoke-WebRequestWrapper, `
    New-TempDirectory, `
    Remove-TempDirectory, `
    Request-UserInputToContinue, `
    Stop-Execution, `
    Sync-DirectoriesWithRobocopy, `
    Test-IsAdmin, `
    Update-EnvironmentVariables, `
    Write-ErrorRecord, `
    Write-Log, `
    Compress-With7Zip, `
	Expand-Zip, `
    Expand-With7Zip, `
    Invoke-Sql, `
    Remove-SqlDatabase, `
    Restore-SqlDatabase, `
    New-SqlDatabase, `
    Update-SqlLogin, `
    Update-SqlUser, `
    Convert-ConfigurationPaths, `
    Read-ConfigFiles, 
    Copy-FilesToRemoteServer, `
    ConvertTo-PSCredential, `
    New-Zip, `
    Disable-ReadOnlyFlag, `
    Get-FlatFileList, `
    Get-Hash, `
    Convert-FunctionToScriptBlock, `
    Test-ComputerNameIsLocalhost, `
    Get-AllBytes, `
    Write-ProgressExternal, `
    New-ConnectionParameters, `
    New-MsDeployDestinationString, `
    Convert-HashtableToString, `
    Test-IsSubdirectory
