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

function ServerRole {
    <#
    .SYNOPSIS
    Element of configuration DSL that allows for creating $ServerRoles hashtable. It is invoked inside 'Environment' element.

    .DESCRIPTION
    It can be used as a convenient way to define $ServerRoles hashtables as in the following example:
    $Environments = @{
        Default = @{
            ServerRoles = @{
                WebServer = @{
                    Configurations = @('WebServerProvision', 'WebServerDeploy')
                    Nodes = $null
                }
            }
        }
        Local = @{
            ServerRoles = @{
                WebServer = @{
                    Nodes = @('localhost')
                }
            }
        }
        Dev = @{
            ServerRoles = @{
                WebServer = @{
                    Nodes = @('server1', 'server2', 'server3')
                }
            }
        }
    }

    .PARAMETER Name
    Name of the server role.

    .PARAMETER Nodes
    List of nodes where current ServerRole will be deployed. Can be array of strings or scriptblock.

    .PARAMETER Configurations
    List of configurations which will be deployed to the $Nodes.

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
    A PSCredential object that will be used when opening a remoting session to any of the $Nodes specified in this ServerRole.

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

    .EXAMPLE
    Environment Default {
        ServerRole WebServer -Configurations @('WebServerProvision')
    	ServerRole DatabaseServer -Configurations @('DatabaseServerDeploy') #-RemotingCredential { $Tokens.Credentials.RemotingCredential }
    }

    Environment Local {
        ServerRole WebServer -Nodes 'localhost'
    	ServerRole DatabaseServer -Nodes 'localhost'
    }

    Environment Dev { 
        ServerRole WebServer -Nodes 'server1'
    	ServerRole DatabaseServer -Nodes 'server2'
    }

    a) ServerRole WebServer -Configurations 'WebServerProvision' -Nodes 'NODE1'

       Run DSC configuration 'WebServerProvision' locally with destination 'NODE1'. Start-DscConfiguration will connect to NODE1 using PSRemoting.  

    b) ServerRole WebServer -Configurations 'DatabaseServerDeploy' -Nodes 'NODE1'

       Run 'function' configuration 'DatabaseServerDeploy' locally with destination 'NODE1'. Note this function will run locally.

    c) ServerRole WebServer -Configurations 'DatabaseServerDeploy' -Nodes @('NODE1', 'NODE2') -RunOnCurrentNode

       Run configuration 'DatabaseServerDeploy' remotely on nodes NODE1 and NODE2. Deployment package will be copied to both nodes using PSRemoting
       (to "c:\PSCIPackage"), and then function 'DatabaseServerDeploy' will be run on NODE1 (with $NodeName = NODE1) and NODE2 (with $NodeName = NODE2).

    d) ServerRole WebServer -Configurations 'DatabaseServerDeploy' -Nodes @('NODE1', 'NODE2') -RunOnNode 'NODE1'

       Run configuration 'DatabaseServerDeploy' remotely on nodes NODE1 and NODE2. Deployment package will be copied to both nodes using PSRemoting
       (to "c:\PSCIPackage"), and then function 'DatabaseServerDeploy' will be run on NODE1 (with $NodeName = NODE1) and again on NODE1 (with $NodeName = NODE2).

    e) ServerRole WebServer -Configurations 'DatabaseServerDeploy' -Nodes @('NODE1', 'NODE2') -RunOnCurrentNode -CopyTo 'c:\dir'

       As in example c), but deployment package will be copied to directory 'c:\dir'

    f) ServerRole WebServer -Configurations 'DatabaseServerDeploy' -Nodes @('NODE1', 'NODE2') -RunOnCurrentNode -RemotingMode WebDeployHandler -Authentication Basic `
                          -RemotingCredential { $Tokens.Credentials.RemotingCredential } -Port 8192

       Run configuration 'DatabaseServerDeploy' remotely on nodes NODE1 and NODE2. Deployment package will be copied to both nodes using MSDeploy (WebDeployHandler)
       with specified credentials, authentication Basic and port 8192.
       Then function 'DatabaseServerDeploy' will be run on NODE1 (with $NodeName = NODE1) and NODE2 (with $NodeName = NODE2), also using MSDeploy.

    g) ServerRole WebServer -Configurations 'DatabaseServerDeploy' -Nodes @('NODE1', 'NODE2') -RunOnCurrentNode -RemotingMode WebDeployHandler -Authentication Basic `
                          -RemotingCredential { $Tokens.Credentials.RemotingCredential } -Port 8192

       Run configuration 'DatabaseServerDeploy' remotely on nodes NODE1 and NODE2. Deployment package will be copied to both nodes using MSDeploy (WebDeployHandler)
       with specified credentials, authentication Basic and port 8192.
       Then function 'DatabaseServerDeploy' will be run on NODE1 (with $NodeName = NODE1) and NODE2 (with $NodeName = NODE2), also using MSDeploy.
 
    h) ServerRole WebServer -Configurations 'DatabaseServerDeploy' -Nodes @('NODE1', 'NODE2') -RunOnCurrentNode -RemotingMode PSRemoting -Authentication CredSsp `
                          -RemotingCredential { $Tokens.Credentials.RemotingCredential } -Protocol HTTPS

       Run configuration 'DatabaseServerDeploy' remotely on nodes NODE1 and NODE2. Deployment package will be copied to both nodes using PSRemoting / CredSsp / HTTPS
       with specified credentials.
       Then function 'DatabaseServerDeploy' will be run on NODE1 (with $NodeName = NODE1) and NODE2 (with $NodeName = NODE2), also using PSRemoting / CredSsp / HTTPS
 
    i) ServerRole WebServer -Configurations 'WebServerProvision' -Nodes @('NODE1', 'NODE2') -RebootHandlingMode AutoReboot
   
       By default when DSC resource requires a reboot, deployment is stopped and will not run all steps. 
       By specifying -RebootHandlingMode AutoReboot, machine will be rebooted automatically and deployment will continue.

    j) ServerRole WebServer -Configurations 'WebServerProvision' -Nodes @('NODE1', 'NODE2') -RebootHandlingMode RetryWithoutReboot

       By default when DSC resource requires a reboot, deployment is stopped and will not run all steps. 
       By specifying -RebootHandlingMode RetryWithoutReboot, deployment will continue without rebooting and all steps will run.

#>

    [CmdletBinding(DefaultParametersetName='NoRunOn')]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,
        
        [Parameter(Mandatory=$false)]
        [object]
        $Nodes,

        [Parameter(Mandatory=$false)]
        [string[]]
        $Configurations,

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
        [ValidateSet('PSRemoting', 'WebDeployHandler', 'WebDeployAgentService')]
        [string]
        $RemotingMode = 'PSRemoting',

        [Parameter(Mandatory=$false)]
        [object]
        $RemotingCredential,

        [Parameter(Mandatory=$false)]
        [ValidateSet($null, 'Basic', 'NTLM', 'Credssp', 'Default', 'Digest', 'Kerberos', 'Negotiate', 'NegotiateWithImplicitCredential')]
        [string]
        $Authentication,

        [Parameter(Mandatory=$false)]
        [ValidateSet($null, 'HTTP', 'HTTPS')]
        [string]
        $Protocol,

        [Parameter(Mandatory=$false)]
        [switch]
        $CrossDomain,

        [Parameter(Mandatory=$false)]
        [ValidateSet($null, 'None', 'Stop', 'RetryWithoutReboot', 'AutoReboot')]
        [string]
        $RebootHandlingMode
    )

    if ((Test-Path variable:Env_Name) -and $Env_Name) {

        $serverRolesDef = $Global:Environments[$Env_Name].ServerRoles

        if (!$serverRolesDef.Contains($Name)) {
            $serverRolesDef[$Name] = @{ Name = $Name }
        }
    
        $serverRole = $serverRolesDef[$Name]

        if ($PSBoundParameters.ContainsKey('Nodes')) {
            $serverRole.Nodes = $Nodes
        }
        if ($PSBoundParameters.ContainsKey('Configurations')) {
            $serverRole.Configurations = $Configurations
        }
        if ($PSBoundParameters.ContainsKey('RemotingCredential')) {
            $serverRole.RemotingCredential = $RemotingCredential
        }
        if ($PSBoundParameters.ContainsKey('RunOn')) {
            $serverRole.RunOn = $RunOn
        }
        if ($PSBoundParameters.ContainsKey('RunOnCurrentNode')) {
            $serverRole.RunOnCurrentNode = $RunOnCurrentNode
        }
        if ($PSBoundParameters.ContainsKey('CopyTo')) {
            $serverRole.CopyTo = $CopyTo
        }
        if ($PSBoundParameters.ContainsKey('Port')) {
            $serverRole.Port = $Port
        }
        if ($PSBoundParameters.ContainsKey('Authentication')) {
            $serverRole.Authentication = $Authentication
        }
        if ($PSBoundParameters.ContainsKey('RemotingMode')) {
            $serverRole.RemotingMode = $RemotingMode
        }
        if ($PSBoundParameters.ContainsKey('Protocol')) {
            $serverRole.Protocol = $Protocol
        }
        if ($PSBoundParameters.ContainsKey('CrossDomain')) {
            $serverRole.CrossDomain = $CrossDomain
        }
        if ($PSBoundParameters.ContainsKey('RebootHandlingMode')) {
            $serverRole.RebootHandlingMode = $RebootHandlingMode
        }

    } else {
        Write-Log -Critical "'ServerRole' function cannot be invoked outside 'Environment' function."
    }
}
