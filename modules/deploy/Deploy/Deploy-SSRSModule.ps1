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

function Deploy-SSRSModule {
    <#
    	.SYNOPSIS
    		Deploys SSRS Module (.dlls) by copying files to Reporting Services and Visual Studio instances on the server.
    
    	.PARAMETER  PackageName
    		Name of the package to be deployed.
    
    	.PARAMETER  PackagePath
    		Path of the package.
  
    	.EXAMPLE
    		PS C:\> Deploy-SSRSModule -PackageName 'MyPackage' -Server localhost
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string] 
        $PackageName, 

        [Parameter(Mandatory=$false)]
        [string] 
        $PackagePath
    )

    # TODO: add check to ensure that we're on correct node ($node) - as this will fail if 'RunOn' is not specified

    $PackagePath = Resolve-PathRelativeToProjectRoot `
                -Path $PackagePath `
                -DefaultPath (Join-Path -Path $configPaths.PackagesPath -ChildPath $PackageName) `
                -ErrorMsg "Cannot find file '{0}' required for deployment of package '$PackageName'. Please ensure you have run the build and the package exists."

    $instances = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances
    $paths = New-Object -Type System.Collections.ArrayList

    # Get MSRS paths
    foreach ($instance in $instances) {
        $msrsInstanceName = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\RS').$instance
        $sqlPath = Join-Path -Path (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$msrsInstanceName\Setup").SQLPath -ChildPath "\bin\"
        [void]$paths.Add($sqlPath)
    }

    # Get VS paths
    $vsEnvVars = (Get-ChildItem -Path Env:).Name -match "VS[0-9]{1,3}COMNTOOLS"
    foreach ($vsInstance in $vsEnvVars) {
        $vsPath = Get-Content -Path Env:\$vsInstance -ReadCount 0
        $privAssembliesPath =  Join-Path -Path $vsPath.ToString() -ChildPath "..\IDE\PrivateAssemblies\"
        if (Test-Path -Path $privAssembliesPath -PathType Container) {
            [void]$paths.Add($privAssembliesPath)
        }
    }

    foreach ($path in $paths) {
        Write-Log -Info "Copying $PackagePath\*.* to $path ..."
        if (!(Test-Path $path)) {
            Write-Log -Critical ("Path $path does not exist. Please ensure you're deploying SSRS module on correct server ({0}) - RunOn/RunOnCurrentNode missing?" -f (hostname))
        }
        Copy-Item -Path "$PackagePath\*.*" -Destination $path -Recurse -Force
    }
}