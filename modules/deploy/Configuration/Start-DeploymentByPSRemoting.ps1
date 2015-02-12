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

function Start-DeploymentByPSRemoting {
    <#
    .SYNOPSIS
    Runs the actual deployment basing on the deployment plan on a remote server by using powershell remoting.

    .PARAMETER Environment
    Name of the environment where the packages will be deployed.

    .PARAMETER ServerRole
    Name of the the server role that will be deployed.

    .PARAMETER ConnectionParams
    Connection parameters created by New-ConnectionParameters function.

    .PARAMETER CopyTo
    Defines location on remote machine where deployment package will be copied to.

    .PARAMETER DeployType
    Deployment type:
    All       - deploy everything according to configuration files (= Provision + Deploy)
    Provision - deploy only DSC configurations
    Deploy    - deploy only non-DSC configurations
    Adhoc     - override configurations and nodes with $ConfigurationsFilter and $NodesFilter (they don't have to be defined in ServerRoles - useful for adhoc deployments)

    .PARAMETER CopyPackage
    If true then package will be copied to the remote server. If false then deployment assumes that package is already there.

    .PARAMETER NodesFilter
    List of Nodes where configurations have to be deployed - can be used if you don't want to deploy to all nodes defined in the configuration files.
    If not set, configurations will be deployed to all nodes according to the ServerRoles defined in the configuration files.

    .PARAMETER ConfigurationsFilter
    List of Configurations to deploy - can be used if you don't want to deploy all configurations defined in the configuration files.
    If not set, configurations will be deployed according to the ServerRoles defined in the configuration files.

    .PARAMETER TokensOverride
    A list of tokens to override. Token defined in the configuration files will be overrided with values specified in this array 
    (tokens will be matched by name, ignoring categories).

    .EXAMPLE
    Start-DeploymentByPSRemoting -Environment $Environment -ServerRole $ServerRole -CopyTo "C:\test" -ConnectionParams (New-ConnectionParameters -Nodes localhost -RemotingMode PSRemoting)
    
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Environment,

        [Parameter(Mandatory=$true)]
        [string]
        $ServerRole,

        [Parameter(Mandatory=$true)]
        [object]
        $ConnectionParams,

        [Parameter(Mandatory=$true)]
        [string]
        $CopyTo,

        [Parameter(Mandatory=$false)]
        [ValidateSet('All', 'Provision', 'Deploy', 'Adhoc')]
	    [string]
	    $DeployType = 'All',

        [Parameter(Mandatory=$false)]
        [switch]
        $CopyPackage = $false,

        [Parameter(Mandatory=$false)]
        [string[]]
        $NodesFilter,

        [Parameter(Mandatory=$false)]
        [string[]]
        $ConfigurationsFilter,

        [Parameter(Mandatory=$false)]
        [hashtable]
        $TokensOverride
    )

    if ($ConnectionParams.Authentication -ieq "Credssp") {
        if ((Get-Item WSMan:\LocalHost\Client\Auth\CredSSP).Value -ne "true") {
            Enable-WSManCredSSP -Role Client -DelegateComputer * -Force
        }
        if ($ConnectionParams.CrossDomain) {
            Enable-FreshCredNtlmOnlyDelegation
        }
    }

    $deployScript = (Join-Path -Path $CopyTo -ChildPath "DeployScripts\deploy.ps1") + " -Environment $Environment -ServerRolesToDeploy $ServerRole -DeployType $DeployType"
    
    if ($NodesFilter) {
        $deployScript += " -NodesFilter '{0}'" -f ($NodesFilter -join "','")
    }
    if ($ConfigurationsFilter) {
        $deployScript += " -ConfigurationsFilter '{0}'" -f ($ConfigurationsFilter -join "','")
    }
    if ($TokensOverride) {
       $tokensOverrideString = Convert-HashtableToString -Hashtable $TokensOverride
       $deployScript += " -TokensOverride {0}" -f $tokensOverrideString
    }

    if ($CopyPackage) {
        $configPaths = Get-ConfigurationPaths
        $packagesPath = $configPaths.PackagesPath
        [void](Copy-FilesToRemoteServer -Path $packagesPath -Destination $CopyTo -ConnectionParams $ConnectionParams -ClearDestination)
    }

    $scriptBlock = {
        param(
            [string]
            $DeployScript,

            [string]
            $RemotingMode
        )

        $Global:RemotingMode = $RemotingMode
        Invoke-Expression -Command "& $DeployScript"
    }

    Write-Log -Info "Running `"$deployScript`" using $($ConnectionParams.RemotingMode) on `"$($ConnectionParams.NodesAsString)`""
    $psSessionParams = $ConnectionParams.PSSessionParams
    $success = Invoke-Command @psSessionParams -ScriptBlock $scriptBlock -ArgumentList $deployScript, $ConnectionParams.RemotingMode
    if (!$success) {
        Write-Log -Critical "Remote invocation failed."
    }
}
