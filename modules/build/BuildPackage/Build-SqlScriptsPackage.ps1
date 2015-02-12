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

function Build-SqlScriptsPackage {
     <#
    .SYNOPSIS
    Builds a package containing sql files.

    .DESCRIPTION
    It copies all *.sql files from $ScriptsPath to $OutputPath (or $PackagesPath\$PackageName if $OutputPath is not provided).
    The package can be deployed with cmdlet Deploy-DBDeploySqlScriptsPackage or Deploy-SqlPackage.

    .PARAMETER PackageName
    Name of the package. It determines OutputPath if it's not provided.

    .PARAMETER ScriptsPath
    Path to the sql scripts. They will be copied to OutputPath.

    .PARAMETER OutputPath
    Output path where the package will be created. If not provided, $OutputPath = $PackagesPath\$PackageName, where $PackagesPath is taken from global variable.

    .PARAMETER Include
    The files to be included in the package.

    .PARAMETER Exclude
    The files to be excluded from the package.

    .LINK
    Deploy-DBDeploySqlScriptsPackage
    Deploy-SqlPackage
    Build-DBDeployPackage

    .EXAMPLE
    Build-SqlScriptsPackage -PackageName 'YourProject.SqlScriptsDBName' -ScriptsPath 'Database\DbName\changes'

    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $PackageName,

        [Parameter(Mandatory=$true)]
        [string]
        $ScriptsPath,

        [Parameter(Mandatory=$false)]
        [string]
        $OutputPath,

        [Parameter(Mandatory=$false)]
        [string]
        $Include = "*.sql",

        [Parameter(Mandatory=$false)]
        [string]
        $Exclude = $null
    )

    $configPaths = Get-ConfigurationPaths

    $ScriptsPath = Resolve-PathRelativeToProjectRoot `
                    -Path $ScriptsPath `
                    -ErrorMsg "Sql scripts directory '$ScriptsPath' does not exist (package '$PackageName'). Tried following absolute path: '{0}'."

    $OutputPath = Resolve-PathRelativeToProjectRoot `
                            -Path $OutputPath `
                            -DefaultPath (Join-Path -Path $configPaths.PackagesPath -ChildPath $PackageName) `
                            -CheckExistence:$false
    
    [void](New-Item -Path $OutputPath -ItemType Directory)

    Write-Log -Info "Copying Scripts from $ScriptsPath.."

    [void](Copy-Item -Path "$ScriptsPath\*.*" -Include $Include -Exclude $Exclude -Destination $OutputPath)

}