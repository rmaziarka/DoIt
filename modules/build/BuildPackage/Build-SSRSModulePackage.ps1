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

function Build-SSRSModulePackage {

    <#
    .SYNOPSIS
    Builds a package containing SSRS module.

    .DESCRIPTION
    $ProjectPath is compiled and packaged using msbuild to the $OutputPath (or $PackagesPath\$PackageName if $OutputPath is not provided).
    The resulting package can be deployed using cmdlet Deploy-MsDeployPackage.

    .PARAMETER PackageName
    Name of the package. It determines OutputPath if it's not provided.

    .PARAMETER ProjectPath
    Path to the project file that will be compiled and packaged. It can be a msbuild solution or project.

    .PARAMETER OutputPath
    Output path where the package will be created. If not provided, $OutputPath = $PackagesPath\$PackageName, where $PackagesPath is taken from global variable.

    .PARAMETER ProjectName
    Project name which will be 

    .PARAMETER MsBuildOptions
    An object created by New-MsBuildOptions function, which specifies msbuild options.
    If not provided, default msbuild options will be used.

    .LINK
    Deploy-SSRSModule
    New-MsBuildOptions

    .EXAMPLE
    Build-SSRSModulePackage -PackageName 'MyProject' -ProjectPath 'Src\MyProject.vbproj'

    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $PackageName,

        [Parameter(Mandatory=$true)]
        [string]
        $ProjectPath,

        [Parameter(Mandatory=$false)]
        [string]
        $OutputPath,

        [Parameter(Mandatory=$false)]
        [PSObject]
        $MsBuildOptions
    )
    
    $configPaths = Get-ConfigurationPaths

    $ProjectPath = Resolve-PathRelativeToProjectRoot `
                        -Path $ProjectPath `
                        -ErrorMsg "Project file '$ProjectPath' does not exist (package '$PackageName'). Tried following absolute path: '{0}'."

    $OutputPath = Resolve-PathRelativeToProjectRoot `
                            -Path $OutputPath `
                            -DefaultPath (Join-Path -Path $configPaths.PackagesPath -ChildPath $PackageName)  `
                            -CheckExistence:$false
   
    Invoke-MsBuild -ProjectPath $ProjectPath -MsBuildOptions $MsBuildOptions

    $DllPath = Join-Path -Path (Split-Path -Parent -Path $ProjectPath) -ChildPath "bin\Release"
    [void](New-Item -Path $OutputPath -ItemType Directory -Force)

    Write-Log -Info "Copying Package."
    $projectFile = Split-Path -Leaf -Path $ProjectPath
    $projectName = [System.IO.Path]::GetFileNameWithoutExtension($projectFile)
    Copy-Item -Path "$DllPath/$projectName.dll" -Destination $OutputPath -Recurse

}