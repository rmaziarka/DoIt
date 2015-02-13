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

    .PARAMETER Node
    Name of the node to add to the deployment plan.

    .PARAMETER ConfigurationName
    Name of the configuration (DSC configuration or function) to add to the deployment plan.

    .PARAMETER TokensOverride
    A list of tokens to override. Token defined in the configuration files will be overrided with values specified in this array 
    (tokens will be matched by name, ignoring categories).

    .PARAMETER DscOutputPath
    Path where the .MOF files will be generated.

    .PARAMETER RunOn
    Defines on which machine run deployment of given server role.

    .PARAMETER RunOnCurrentNode
    If set then each conifguration deployment is run directly on the specified node.

    .PARAMETER CopyTo
    Defines location on remote machine where deployment package will be copied to.

    .PARAMETER Port
    Defines the port used for establishing remote connection.

    .PARAMETER RemotingMode
    Defines type of remoting protocol to be used for remote deployment.

    .PARAMETER RemotingCredential
    Credentials that should be used when invoking 'Start-DscConfiguration' (only relevent for DSC configurations).

    .PARAMETER Authentication
    Defines type of authentication that will be used to establish remote conncetion.

    .PARAMETER Protocol
    Defines the transport protocol used for establishing remote connection (HTTP or HTTPS).

    .PARAMETER CrossDomain
    This switch should be on when destination nodes are in different domain (additional setup is required in this case).

    .PARAMETER RebootHandlingMode
    Specifies what to do when a reboot is required by DSC resource:
    None (default)     - don't check if reboot is required - leave it up to DSC (by default it stops current configuration, but next configurations will run)
    Stop               - stop and fail the deployment
    RetryWithoutReboot - retry several times without reboot
    AutoReboot         - reboot the machine and continue deployment
    Note that any setting apart from 'None' will cause output messages not to log in real-time.

    .PARAMETER DeployType
    Deployment type:
    All       - deploy everything according to configuration files (= Provision + Deploy)
    Provision - deploy only DSC configurations
    Deploy    - deploy only non-DSC configurations
    Adhoc     - override configurations and nodes with $ConfigurationsFilter and $NodesFilter (they don't have to be defined in ServerRoles - useful for adhoc deployments)

    .LINK
        New-DeploymentPlan

    .EXAMPLE
        New-DeploymentPlanEntry -Environment $Environment -Node $Node `
                                   -ConfigurationName $configName -DscOutputPath $DscOutputPath -RemotingCredential $remotingCredential

    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]
        $AllEnvironments,

        [Parameter(Mandatory=$true)]
        [string]
        $Environment,

        [Parameter(Mandatory=$true)]
        [string]
        $ServerRole,

        [Parameter(Mandatory=$true)]
        [string]
        $Node,

        [Parameter(Mandatory=$true)]
        [string]
        $ConfigurationName,

        [Parameter(Mandatory=$false)]
        [hashtable]
        $TokensOverride,

        [Parameter(Mandatory=$true)]
        [string]
        $DscOutputPath,

        [Parameter(Mandatory=$false)]
        [string]
        $RunOn,

        [Parameter(Mandatory=$false)]
        [switch]
        $RunOnCurrentNode = $false,

        [Parameter(Mandatory=$false)]
        [object]
        $CopyTo,

        [Parameter(Mandatory=$false)]
        [object]
        $Port,

        [Parameter(Mandatory=$false)]
        [ValidateSet("PSRemoting", "WebDeployHandler", "WebDeployAgentService")]
        [string]
        $RemotingMode,

        [Parameter(Mandatory=$false)]
        [object]
        $RemotingCredential,

        [Parameter(Mandatory=$false)]
        [ValidateSet("Basic", "NTLM", "Credssp", "Default", "Digest", "Kerberos", "Negotiate", "NegotiateWithImplicitCredential")]
        [string]
        $Authentication,

        [Parameter(Mandatory=$false)]
        [ValidateSet($null, 'HTTP', 'HTTPS')]
        [string]
        $Protocol = 'HTTP',

        [Parameter(Mandatory=$false)]
        [switch]
        $CrossDomain,

        [Parameter(Mandatory=$false)]
        [ValidateSet($null, 'None', 'Stop', 'RetryWithoutReboot', 'AutoReboot')]
        [string]
        $RebootHandlingMode,

        [Parameter(Mandatory=$false)]
        [ValidateSet('All', 'Provision', 'Deploy', 'Adhoc')]
	    [string]
	    $DeployType = 'All'
    )

    $mofDir = ''

    $cmd = Get-Command -Name $ConfigurationName -ErrorAction SilentlyContinue

    $resolvedTokens = Resolve-Tokens -AllEnvironments $AllEnvironments -Environment $Environment -Node $Node -TokensOverride $TokensOverride

    # note that only parameters that are of type [object] in ServerRole can be scriptblock (otherwise scriptblock will be converted to string)

    $connectionParams = @{
                    Nodes = $Node
                    RemotingMode = $RemotingMode
                    Credential = (Resolve-ScriptedToken -ScriptedToken $RemotingCredential -Tokens $resolvedTokens -Environment $Environment -Node $Node)
                    Authentication = $Authentication
                    Port = (Resolve-ScriptedToken -ScriptedToken $Port -Tokens $resolvedTokens -Environment $Environment -Node $Node)
                    Protocol = $Protocol
                    CrossDomain = $CrossDomain
                }

    $connectionParamsObj = New-ConnectionParameters @connectionParams
    
    if ($RunOnCurrentNode) {
        $runOnNode = $Node
    } elseif ($RunOn) {
        $runOnNode = $RunOn
    }

    if ($runOnNode) {
        $connectionParams.Nodes = $runOnNode
        $runOnConnectionParamsObj = New-ConnectionParameters @connectionParams
    }

    if ($cmd.CommandType -eq 'Configuration') {
        if ($DeployType -eq 'Deploy') {
            Write-Log -Info "Skipping configuration '$ConfigurationName'"
            return $null
        }
		
		# When RunOnCurrentNode = true, DSC will run in local mode (we don't want to open Cim session then)
		if ($RunOnCurrentNode) {
			$dscNode = 'localhost'
		} else {
			$dscNode = $Node
		}
    
        $mofDir = Invoke-ConfigurationOrFunction -ConfigurationName $ConfigurationName -OutputPath $DscOutputPath -Node $dscNode -Environment $Environment -ResolvedTokens $resolvedTokens -ConnectionParams $connectionParamsObj
        if (!(Get-ChildItem -Path $mofDir -Filter "*.mof")) {
            Write-Log -Warn "Mof file has not been generated for configuration named '$ConfigurationName' (ServerRole '$serverRoleName' / Environment '$Environment'. Please ensure your configuration definition is correct."
            continue
        }
    } elseif ($cmd.CommandType -eq 'Function') {
        if ($DeployType -eq 'Provision') {
            Write-Log -Info "Skipping configuration '$ConfigurationName'"
            return $null
        }
    } else {
        Write-Log -Critical "Command '$ConfigurationName' is of unrecognized type - neither 'Configuration' nor 'Function'."
    }

    $isLocalRun = $RunOnCurrentNode -or $RunOn -eq $Node

    return [PSCustomObject]@{ 
        ConnectionParams = $connectionParamsObj
        RunOnConnectionParams = $runOnConnectionParamsObj
        IsLocalRun = $isLocalRun
        Environment = $Environment;
        ServerRole = $ServerRole;
        Configuration = [PSCustomObject]@{
            "Type" = $cmd.CommandType; 
            "Name" = $ConfigurationName;
            "MofDir" = $mofDir 
        }
        Tokens = $resolvedTokens; 
        TokensOverride = $TokensOverride;
        CopyTo = (Resolve-ScriptedToken -ScriptedToken $CopyTo -Tokens $resolvedTokens -Environment $Environment -Node $Node)
        RebootHandlingMode = $RebootHandlingMode
    }
}

