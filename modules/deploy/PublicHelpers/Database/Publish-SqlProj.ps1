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

function Publish-SqlProj {
    <#
    .SYNOPSIS
    Publishes a .dacpac file using sqlpackage.exe.

    .PARAMETER DacpacFilePath
    Local path pointing to the .dacpac file.

    .PARAMETER DbConnectionString
    Connection string to database.

    .PARAMETER Options
    Additional Options passed directly to SqlPackage.

    .PARAMETER Variables
    Variables passed to SqlPackage.

    .PARAMETER IgnoreStdErr
    If true, stderr from SqlPackage.exe will be ignored (script will continue).

    .EXAMPLE
    Publish-SqlProj -DacpacFilePath $DacpacFilePath -DbConnectionString $DbConnectionString -Options $Options -Variables $Variables -IgnoreStdErr:$IgnoreStdErr
    #>

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string] 
        $DacpacFilePath, 
        
        [Parameter(Mandatory=$true)]
        [string] 
        $DbConnectionString,

        [Parameter(Mandatory=$false)]
        [hashtable] 
        $Options,

        [Parameter(Mandatory=$false)]
        [hashtable] 
        $Variables,

        [Parameter(Mandatory=$false)]
        [switch] 
        $IgnoreStdErr
    )

    $programFilesDir = Get-ProgramFilesx86Path
    $packageLocalPath = Split-Path -Parent $DacpacFilePath
    $sqlPackagePath = Join-Path -Path $programFilesDir -ChildPath "Microsoft SQL Server\110\DAC\bin\SqlPackage.exe"
    if (!$sqlPackagePath) {
        Write-Log -Critical "Cannot find '$sqlPackagePath' which is required to publish package '$packageLocalPath'."
    }
    
    if (!(Test-Path -Path $DacpacFilePath)) {
        Write-Log -Critical "Cannot find file '$DacpacFilePath'."
    }
    

    $sqlPackageParams = ('/Action:Publish /SourceFile:"{0}" /TargetConnectionString:"{1}" /p:VerifyDeployment=True ' -f $DacpacFilePath, $DbConnectionString)
    if ($Options) {
        foreach ($option in $Options.GetEnumerator()) {
            $sqlPackageParams += ("/p:{0}={1} " -f $option.Key, $option.Value)
        }
    }
    if ($Variables) {
        foreach ($variable in $Variables.GetEnumerator()) {
            $sqlPackageParams += ("/Variables:{0}={1} " -f $variable.Key, $variable.Value)
        }
    }

    $cmd = "{0} {1}" -f (Add-QuotesToPaths $sqlPackagePath), $sqlPackageParams

    Write-Log -Info "Running sqlpackage.exe for package: '$packageLocalPath'"
    try { 
        Push-Location -Path $packageLocalPath   
        [void](Invoke-ExternalCommand -Command $cmd -CheckStdErr:(!$IgnoreStdErr))
    } finally {
        Pop-Location
    }
    
}