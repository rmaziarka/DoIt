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

function Build-DeploymentScriptsPackage {
    <#
    .SYNOPSIS
    Builds a package containing PSCI library and deployment configuration.

    .DESCRIPTION
    It copies whole PSCI library to $OutputPathPsci (or $PackagesPath\PSCI if $OutputPathPsci is not provided).
    It also copies project configuration files (tokens / server roles) from $DeployScriptsPaths to $OutputPathDeploymentScripts 
    (or $PackagesPath\DeployScripts if $OutputPathDeploymentScripts is not provided).
    These packages are required for any deployment that is to be run by PSCI.
    
    .PARAMETER DeployScriptsPath
    Path to the project deployment scripts (deploy.ps1).

    .PARAMETER ReplaceDeployScriptParameters
    If true, default variable values (paths) in deploy.ps1 file will be updated to reflect the default package directory structure.

    .PARAMETER OutputPathPsci
    Output path where the PSCI package will be created. If not provided, $OutputPath = $PackagesPath\PSCI, where $PackagesPath is taken from global variable.

    .PARAMETER OutputPathDeploymentScripts
    Output path where project configuration package will be created. If not provided, $OutputPath = $PackagesPath\DeokiyScripts, where $PackagesPath is taken from global variable.

    .PARAMETER ModulesToInclude
    List of PSCI modules to include. If empty, only 'PSCI.deploy' module will be included.

    .EXAMPLE
    Build-DeploymentScriptsPackage -DeployScriptsPath $PSScriptRoot

    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$false)]
        [string]
        $DeployScriptsPath,

        [Parameter(Mandatory=$false)]
        [switch]
        $ReplaceDeployScriptParameters = $true,

        [Parameter(Mandatory=$false)]
        [string]
        $OutputPathPsci,

        [Parameter(Mandatory=$false)]
        [string]
        $OutputPathDeploymentScripts,

        [Parameter(Mandatory=$false)]
        [string[]]
        $ModulesToInclude

    )

    $configPaths = Get-ConfigurationPaths

    $DeployScriptsPath = Resolve-PathRelativeToProjectRoot `
                            -Path $DeployScriptsPath `
                            -DefaultPath '.' `
                            -CheckExistence:$true
    

    $OutputPathPsci = Resolve-PathRelativeToProjectRoot `
                            -Path $OutputPathPsci `
                            -DefaultPath (Join-Path -Path $configPaths.PackagesPath -ChildPath "PSCI") `
                            -CheckExistence:$false

    $OutputPathDeploymentScripts = Resolve-PathRelativeToProjectRoot `
                            -Path $OutputPathDeploymentScripts `
                            -DefaultPath (Join-Path -Path $configPaths.PackagesPath -ChildPath "DeployScripts") `
                            -CheckExistence:$false


    $rootPath = Get-PSCIModulePath
    $modules = @('PSCI.core', 'PSCI.deploy') 
    if ($ModulesToInclude) { 
        # SuppressScriptCop - adding small arrays is ok
        $modules += $ModulesToInclude
    }
    $externalLibsPath = Get-PathToExternalLib
    $externalLibs = @('SQLPSX', 'Carbon\Carbon\bin', 'Carbon\Carbon\Path', 'Carbon\Carbon\Xml')

    Write-Log -Info "Copying deployment configuration from '$DeployScriptsPath' to '$OutputPathDeploymentScripts'"
    
    # if output is a subdirectory of DeployScriptsPath, we need to copy it to temp directory to prevent infinite recursion
    if (Test-IsSubdirectory -Path1 $DeployScriptsPath -Path2 $OutputPathDeploymentScripts) {
        $tempDir = New-TempDirectory
        [void](Copy-Item -Path "${DeployScriptsPath}\*" -Destination $tempDir -Exclude '.git' -Recurse -Force)
        [void](New-Item -Path $OutputPathDeploymentScripts -ItemType Directory -Force)
        [void](Move-Item -Path "${tempDir}\*" -Destination $OutputPathDeploymentScripts)
        Remove-TempDirectory
    } else { 
        [void](New-Item -Path $OutputPathDeploymentScripts -ItemType Directory -Force)
        [void](Copy-Item -Path "${DeployScriptsPath}\*" -Destination $OutputPathDeploymentScripts -Exclude '.git' -Recurse -Force)
    }
    
    # make sure that deployment scripts are editable inside of the package
    Get-ChildItem -Path $OutputPathDeploymentScripts -Recurse -File | ForEach-Object {
        Disable-ReadOnlyFlag -Path $_.FullName
    }

    Write-Log -Info "Copying PSCI library from '$rootPath' to '$OutputPathPsci'"
    [void](New-Item -Path $OutputPathPsci -ItemType Directory -Force)

    Copy-Item -Path "${rootPath}\*" -Destination $OutputPathPsci -Recurse -Force -Include 'bat','build.*','Get-ConfigurationPaths.ps1','Initialize-ConfigurationPaths.ps1','Resolve-Path*.ps1','PSCI.*' -Exclude '*.Tests.ps1'

    try { 
        Push-Location -Path $rootPath
        foreach ($module in $modules) {
            $srcPath = Get-PSCIModulePath -Module $module
            $dstPath = Join-Path -Path $OutputPathPsci -ChildPath (Resolve-Path -Path $srcPath -Relative)
            # need to use robocopy here due to 260 path length limitation
            Sync-DirectoriesWithRobocopy -SrcPath $srcPath -DestPath $dstPath -Quiet -ExcludeFiles '*Tests.ps1'    
        }

        foreach ($externalLib in $externalLibs) {
            $srcPath = Join-Path -Path $externalLibsPath -ChildPath $externalLib
            $dstPath = Join-Path -Path $OutputPathPsci -ChildPath (Resolve-Path -Path $srcPath -Relative)
            Copy-Item -Path $srcPath -Destination $dstPath -Recurse -Force
        }
    } finally { 
        Pop-Location
    }

    if ($ReplaceDeployScriptParameters) {
        $deployScriptPath = Join-Path -Path $OutputPathDeploymentScripts -ChildPath "deploy.ps1"
        Write-Log -Info "Replacing default path values / variables in file '$deployScriptPath'"
        if (!(Test-Path -Path $deployScriptPath)) {
            Write-Log -Critical "Cannot find '$deployScriptPath' file. Please ensure it exists or pass parameter -ReplaceDeployScriptParameters:`$false"
        }

        $variablesToReplace = @{ 
                'ProjectRootPath' = '..';
                'PSCILibraryPath' = 'PSCI';
                'PackagesPath' = '.';
                'Environment' = '';
                'DeployConfigurationPath' = '';
        }

        # Replace deploy.ps1 with new default values of path variables (specified in $variablesToReplace)
        $numMatch = 0

        (Get-Content -Path $deployScriptPath -ReadCount 0) | Foreach-Object {
            $matched = $false
            foreach ($varToReplace in $variablesToReplace.GetEnumerator()) {
                $varName = $varToReplace.Key
                $varValue = $varToReplace.Value
                if ($_ -imatch "(\s*\`$$varName)[^=]*=[^,]*,") {
                    $matched = $true
                    $numMatch++
                    "$($Matches[1]) = '$varValue',"
                    break
                }
            }
            if (!$matched) {
                $_
            }
        } | Set-Content -Path $deployScriptPath

        if ($numMatch -ne $variablesToReplace.Count) {
            Write-Log -Critical "Failed to replace all default path values / variables in file '$deployScriptPath'. Successful: $numMatch, target: $($variablesToReplace.Count)."
        }
    }
}