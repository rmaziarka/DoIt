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

<#
.SYNOPSIS
Starts the deployment process using configuration scripts residing in $DeployConfigurationPath.

.DESCRIPTION
It will deploy packages available in $PackagesPath to the $Environment, using configuration scripts at $DeployConfigurationPath.

.PARAMETER ProjectRootPath
Base directory of the project, relative to the directory where this script resides. It is used as a base directory for other directories.
  
.PARAMETER DoItLibraryPath
Base directory where DoIt library resides, relative to $ProjectRootPath.

.PARAMETER PackagesPath
Path to the directory where packages reside, relative to $ProjectRootPath.

.PARAMETER DeployConfigurationPath
Path to the directory where configuration files reside, relative to $ProjectRootPath. By default '$ProjectRootPath\deploy' or '$PackagesPath\DeployScripts\deploy'.

.PARAMETER Environment
Environment where the packages should be deployed (chooses ServerRoles / Tokens specified in the configuration scripts).

.PARAMETER TokensOverride
A hashtable containing tokens to override during this deployment. For example, if you don't want to store Live credentials in your configuration files,
you can pass them using this parameter. It should be a 'flat' hashtable containing only token names and their values (no categories).

.PARAMETER ServerRolesFilter
Allows to limit server roles to deploy.

.PARAMETER NodesFilter
List of Nodes where steps will be deployed - can be used if you don't want to deploy to all nodes defined in the configuration files.
If not set, steps will be deployed to all nodes according to the ServerRoles defined in the configuration files.

.PARAMETER StepsFilter
List of Steps to deploy - can be used if you don't want to deploy all steps defined in the configuration files.
If not set, steps will be deployed according to the ServerRoles defined in the configuration files.

.PARAMETER DeployType
Deployment type:
- All       - deploy everything according to configuration files (= Provision + Deploy)
- Provision - deploy only provisioning steps (-StepsProvision)
- Deploy    - deploy only deploy steps (-StepsDeploy / -Steps) 
- Adhoc     - deploy steps defined in $StepsFilter to server roles defined in $ServerRolesFilter and/or nodes defined in $NodesFilter
              (note the steps do not need to be defined in server roles)

.PARAMETER ValidateOnly
If true, deployment plan will be created but actual deployment will not run.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]
    $ProjectRootPath = '..', # Modify this path according to your project structure. This is relative to the directory where deploy.ps1 resides ($PSScriptRoot).
    
    [Parameter(Mandatory=$false)]
    [string]
    $DoItLibraryPath = '..\..', # Modify this path according to your project structure. This is absolute or relative to $ProjectRootPath.

    [Parameter(Mandatory=$false)]
    [string]
    $PackagesPath = 'bin', # Modify this path according to your project structure. This is absolute or relative to $ProjectRootPath. Leave empty for packageless deployment.
    
    [Parameter(Mandatory=$false)]
    [string]
    $DeployConfigurationPath = '', # Modify this path according to your project structure. This is absolute or relative to $ProjectRootPath (by default '$ProjectRootPath\deploy' or '$PackagePath\DeployScripts\deploy').

    [Parameter(Mandatory=$false)]
    [string[]]
    $Environment = 'Default',

    [Parameter(Mandatory=$false)]
    [hashtable]
    $TokensOverride,
    
    [Parameter(Mandatory=$false)]
    [string[]]
    $ServerRolesFilter,

    [Parameter(Mandatory=$false)]
    [string[]]
    $StepsFilter,

    [Parameter(Mandatory=$false)]
    [string[]]
    $NodesFilter,

    [Parameter(Mandatory=$false)]
    [ValidateSet('All', 'Provision', 'Deploy', 'Adhoc')]
    [string]
    $DeployType = 'All',

    [Parameter(Mandatory=$false)]
    [switch]
    $ValidateOnly
)

$global:ErrorActionPreference = 'Stop'

try {
    ############# Initialization
    Push-Location -Path $PSScriptRoot

    if (![System.IO.Path]::IsPathRooted($DoItLibraryPath)) {
        $DoItLibraryPath = Join-Path -Path $ProjectRootPath -ChildPath $DoItLibraryPath
    }
    if (!(Test-Path -LiteralPath "$DoItLibraryPath\DoIt.psd1")) {
        if (Test-Path -LiteralPath "$PSScriptRoot\packages\DoIt\DoIt.psd1") {
            Write-Host -Object "DoIt library found at '$PSScriptRoot\packages\DoIt'."
        } else {
            Write-Host -Object "Cannot find DoIt library at '$DoItLibraryPath' (current dir: '$PSScriptRoot') - downloading nuget.exe."
            Invoke-WebRequest -Uri 'http://nuget.org/nuget.exe' -OutFile "$env:TEMP\NuGet.exe"
            if (!(Test-Path "$env:TEMP\NuGet.exe")) {
                Write-Host -Object "Failed to download nuget.exe to '$env:TEMP'. Please download DoIt manually and set DoItLibraryPath parameter to an existing path."
                exit 1
            }
            Write-Host -Object 'Nuget.exe downloaded successfully - installing DoIt.'

            & "$env:TEMP\NuGet.exe" install DoIt -ExcludeVersion -OutputDirectory "$PSScriptRoot\packages"
            $DoItLibraryPath = "$PSScriptRoot\packages\DoIt"

            if (!(Test-Path -LiteralPath "$DoItLibraryPath\DoIt.psd1")) {
                Write-Host -Object "Cannot find DoIt library at '$DoItLibraryPath' (current dir: '$PSScriptRoot'). DoIt was not properly installed as nuget."
                exit 1
            }
        }
        $DoItLibraryPath = "$PSScriptRoot\packages\DoIt"
    } else {
        $DoItLibraryPath = (Resolve-Path -Path $DoItLibraryPath).ProviderPath
        Write-Host -Object "DoIt library found at '$DoItLibraryPath'."
    }
    Import-Module "$DoItLibraryPath\DoIt.psd1" -Force

    $DoItGlobalConfiguration.LogFile = "$PSScriptRoot\deploy.log.txt"
    Remove-Item -LiteralPath $DoItGlobalConfiguration.LogFile -ErrorAction SilentlyContinue

    Initialize-ConfigurationPaths -ProjectRootPath $ProjectRootPath -PackagesPath $PackagesPath -DeployConfigurationPath $DeployConfigurationPath -ValidatePackagesPath
    
    ############# Deployment - no custom code here, you need to put your configuration scripts under 'configuration' directory
    Start-Deployment -Environment $Environment `
                     -ServerRolesFilter $ServerRolesFilter `
                     -StepsFilter $StepsFilter `
                     -NodesFilter $NodesFilter `
                     -TokensOverride $TokensOverride `
                     -DeployType $DeployType `
                     -ValidateOnly:$ValidateOnly     
    
} catch {
    Write-ErrorRecord -ErrorRecord $_
} finally {
    Pop-Location
}
