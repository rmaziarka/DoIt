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

function Deploy-SqlProjectPackage {
    <#
    .SYNOPSIS
    Deploys a package containing SSDT .dacpac files.

    .DESCRIPTION
    Deploys a package created with cmdlet (TODO - not existing yet).
    It deploys a .dacpac file from $PackagePath\$PackageName.dacpac using sqlpackage.exe.

    .PARAMETER PackageName
    Name of the package. It determines PackagePath if it's not provided.

    .PARAMETER ConnectionString
    Connection string that will be used to connect to the destination database.

    .PARAMETER SqlPackageOptions
    Hashtable containing additional sqlpackage.exe options that will be passed to sqlpackage.exe command line.

    .PARAMETER Variables
    Hashtable containing variables that will be passed to sqlpackage.exe.

    .PARAMETER IgnoreStdErr
    If true, stderr output from sqlpackage.exe will be ignored. It needs to be enabled if warnings are to be ignored.

    .PARAMETER PackagePath
    Path to the package containing the .dacpac. If not provided, $PackagePath = $PackagesPath\$PackageName, where $PackagesPath is taken from global variable.

    .LINK
    Build-SqlScriptsPackage

    .EXAMPLE
    Deploy-SqlProjectPackage -PackageName 'SQLScripts' -ConnectionString 'Server=localhost;Database=YourDb;Integrated Security=True;MultipleActiveResultSets=True'

    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string] 
        $PackageName, 

        [Parameter(Mandatory=$true)]
        [string] 
        $ConnectionString,

        [Parameter(Mandatory=$false)]
        [hashtable] 
        $SqlPackageOptions,

        [Parameter(Mandatory=$false)]
        [hashtable] 
        $Variables,

        [Parameter(Mandatory=$false)]
        [switch] 
        $IgnoreStdErr,

        [Parameter(Mandatory=$false)]
        [string] 
        $PackagePath
    )

    $PackagePath = Resolve-PathRelativeToProjectRoot `
                    -Path $PackagePath `
                    -DefaultPath (Join-Path -Path $configPaths.PackagesPath -ChildPath $PackageName) `
                    -ErrorMsg "Cannot find file '{0}' required for deployment of package '$PackageName'. Please ensure you have run the build and the package exists."

    $dirName = Split-Path -Leaf $PackagePath
    $dacPacFilePath = Join-Path -Path $PackagePath -ChildPath "$dirName.dacpac"

    if (!(Test-Path -Path $dacPacFilePath)) {
        Write-Log -Critical "Cannot find dacpac file '$dacPacFilePath'."
    }

    Write-Log -Info "Deploying sqlproj package '$packageName' using connection string '$ConnectionString'" -Emphasize
    Publish-SqlProj -DacpacFilePath $dacpacFilePath -DbConnectionString $ConnectionString -Options $SqlPackageOptions -Variables $Variables -IgnoreStdErr:$IgnoreStdErr
}