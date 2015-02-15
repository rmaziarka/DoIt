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

function New-DeploymentPlanEntry {
    <#
    .SYNOPSIS
    Creates a deployment plan entry and adds it to current deployment plan.

    .DESCRIPTION
    See New-DeploymentPlan.
    Returns modified deployment plan.

    .PARAMETER AllEnvironments
    Hashtable containing all environment definitions.

    .PARAMETER Environment
    Name of the environment where the packages should be deployed.

    .PARAMETER ServerRole
    Name of the the server role that will be deployed.

    .PARAMETER ServerConnection
    ServerConnection object.

    .PARAMETER Node
    Name of the node to add to the deployment plan.

    .PARAMETER Configuration
    DSC configuration or function to add to the deployment plan.

    .PARAMETER DscOutputPath
    Path where the .MOF files will be generated.

    .PARAMETER DeployType
    Deployment type:
    All       - deploy everything according to configuration files (= Provision + Deploy)
    Provision - deploy only DSC configurations
    Deploy    - deploy only non-DSC configurations
    Adhoc     - override configurations and nodes with $ConfigurationsFilter and $NodesFilter (they don't have to be defined in ServerRoles - useful for adhoc deployments)


    .PARAMETER ResolvedTokens
    Resolved tokens.

    .PARAMETER TokensOverride
    A list of tokens to override. Token defined in the configuration files will be overrided with values specified in this array 
    (tokens will be matched by name, ignoring categories).    

    
    .LINK
        New-DeploymentPlan

    .EXAMPLE
        New-DeploymentPlanEntry ...

    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Environment,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $ServerRole,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $ServerConnection,

        [Parameter(Mandatory=$true)]
        [string]
        $Node,

        [Parameter(Mandatory=$true)]
        [object]
        $Configuration,

        [Parameter(Mandatory=$true)]
        [string]
        $DscOutputPath,

        [Parameter(Mandatory=$false)]
        [ValidateSet('All', 'Provision', 'Deploy', 'Adhoc')]
	    [string]
	    $DeployType = 'All',

        [Parameter(Mandatory=$true)]
        [hashtable]
        $ResolvedTokens,

        [Parameter(Mandatory=$false)]
        [hashtable]
        $TokensOverride
        
    )

    $mofDir = ''

    # note that only parameters that are of type [object] in ServerRole can be scriptblock (otherwise scriptblock will be converted to string)
    $connectionParams = @{
                    Nodes = $Node
                    RemotingMode = $ServerConnection.RemotingMode
                    Credential = Resolve-ScriptedToken -ScriptedToken $ServerConnection.RemotingCredential -ResolvedTokens $ResolvedTokens -Environment $Environment -Node $Node
                    Authentication = $ServerConnection.Authentication
                    Port = Resolve-ScriptedToken -ScriptedToken $ServerConnection.Port -ResolvedTokens $ResolvedTokens -Environment $Environment -Node $Node
                    Protocol = $ServerConnection.Protocol
                    CrossDomain = $ServerConnection.CrossDomain
                }

    $connectionParamsObj = New-ConnectionParameters @connectionParams
    
    if ($ServerRole.RunOn) {
        $runOnNode = $ServerRole.RunOn
    } elseif ($ServerRole.RunRemotely) {
        $runOnNode = $Node
    }

    if ($runOnNode) {
        $connectionParams.Nodes = $runOnNode
        $runOnConnectionParamsObj = New-ConnectionParameters @connectionParams
    }

    $isLocalRun = $runOnNode -eq $Node

    if ($Configuration.CommandType -eq 'Configuration') {		
		if ($isLocalRun) {
			$dscNode = 'localhost'
		} else {
			$dscNode = $Node
		}
    
        $mofDir = Invoke-ConfigurationOrFunction -ConfigurationName $Configuration.Name -OutputPath $DscOutputPath -Node $dscNode -Environment $Environment -ResolvedTokens $ResolvedTokens -ConnectionParams $connectionParamsObj
        if (!(Get-ChildItem -Path $mofDir -Filter "*.mof")) {
            Write-Log -Warn "Mof file has not been generated for configuration named '$($Configuration.Name)' (Environment '$Environment' / ServerRole '$($ServerRole.Name)'). Please ensure your configuration definition is correct."
            continue
        }
    }

    $packageDirectory = (Resolve-ScriptedToken -ScriptedToken $ServerConnection.PackageDirectory -ResolvedTokens $ResolvedTokens -Environment $Environment -Node $Node)
    if (!$packageDirectory) {
        $packageDirectory = "c:\PSCIPackage"
    }

    return [PSCustomObject]@{ 
        ConnectionParams = $connectionParamsObj
        RunOnConnectionParams = $runOnConnectionParamsObj
        IsLocalRun = $isLocalRun
        Environment = $Environment;
        ServerRole = $ServerRole.Name;
        Configuration = [PSCustomObject]@{
            "Type" = $Configuration.CommandType; 
            "Name" = $Configuration.Name
            "MofDir" = $mofDir 
        }
        Tokens = $ResolvedTokens; 
        TokensOverride = $TokensOverride;
        PackageDirectory = $packageDirectory;
        #Prerequisites = (Resolve-ScriptedToken -ScriptedToken $ServerRole.Prerequisites -ResolvedTokens $ResolvedTokens -Environment $Environment -Node $Node)
        RebootHandlingMode = $RebootHandlingMode
    }
}

