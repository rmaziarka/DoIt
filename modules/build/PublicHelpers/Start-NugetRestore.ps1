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

function Start-NugetRestore {
    <#
    .SYNOPSIS
    Runs nuget restore for given project.

    .PARAMETER ProjectPath
    Path to the project file.

    .EXAMPLE
    Start-NugetRestore -ProjectPath $projectPath
    #>

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $ProjectPath
    )

    Write-ProgressExternal -Message 'Running Nuget restore' -ErrorMessage 'Nuget restore error'

    if (!(Test-Path -Path $ProjectPath)) {
        Write-Log -Critical "Project file does not exist at '$ProjectPath'."
    }

    $projectDir = Split-Path -Parent $ProjectPath

    $currentPath = $projectDir
    $nugetPath = ''
    while (!$nugetPath -and $currentPath) {
        $path = Join-Path -Path $currentPath -ChildPath '.nuget\nuget.exe'
        if (Test-Path -Path $path) {
            $nugetPath = $path
        } else {
            $currentPath = Split-Path -Path $currentPath -Parent
        }
    }

    if (!$nugetPath) {
        Write-Log -Critical "Nuget.exe does not exist at '$currentPath\.nuget\nuget.exe' or any parent directory. Please ensure it's present there or remove line 'Build.RestoreNuGetPackages' from topology config."
    }

    $cmd = Add-QuotesToPaths -Paths $nugetPath
    $cmd += " restore " + (Add-QuotesToPaths -Paths $ProjectPath)

    [void](Invoke-ExternalCommand -Command $cmd)
    
    Write-ProgressExternal -Message '' -ErrorMessage ''
}