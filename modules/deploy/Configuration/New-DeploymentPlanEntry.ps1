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

    .PARAMETER EntryNo
    Consecutive number of this entry in the whole deployment plan.

    .PARAMETER Environment
    Name of the environment where the packages should be deployed.

    .PARAMETER ServerRole
    Name of the the server role that will be deployed.

    .PARAMETER ServerConnection
    ServerConnection object.

    .PARAMETER Node
    Name of the node to add to the deployment plan.

    .PARAMETER Configuration
    Configuration object containing information about DSC configuration or function to be added to the deployment plan (created in Resolve-Configurations).

    .PARAMETER DscOutputPath
    Path where the .MOF files will be generated.

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
        [int]
        $EntryNo,

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
    
    if ($Configuration.RunOn) {
        $runOnNode = $Configuration.RunOn
    } elseif ($Configuration.RunRemotely) {
        $runOnNode = $Node
    }

    if ($runOnNode) {
        $connectionParams.Nodes = $runOnNode
        $runOnConnectionParamsObj = New-ConnectionParameters @connectionParams
    }

    $isLocalRun = $runOnNode -ieq $Node

    if ($Configuration.Type -eq 'Configuration') {		
		if ($isLocalRun) {
			$dscNode = 'localhost'
		} else {
			$dscNode = $Node
		}

        if (!$runOnNode -and $ServerConnection.RemotingMode -and $ServerConnection.RemotingMode -ne 'PSRemoting') {
            Write-Log -Critical "Cannot deploy DSC configurations from localhost when RemotingMode is not PSRemoting. Please either change it to PSRemoting or add '-RunRemotely' switch to the ServerRole or ConfigurationSettings (Environment '$Environment' / ServerRole '$($ServerRole.Name)' / Configuration '$($Configuration.Name)')."
        }
    
        $mofDir = Invoke-ConfigurationOrFunction -ConfigurationName $Configuration.Name -OutputPath $DscOutputPath -Node $dscNode -Environment $Environment -ResolvedTokens $ResolvedTokens -ConnectionParams $connectionParamsObj
        if (!(Get-ChildItem -Path $mofDir -Filter "*.mof")) {
            Write-Log -Warn "Mof file has not been generated for configuration named '$($Configuration.Name)' (Environment '$Environment' / ServerRole '$($ServerRole.Name)'). Please ensure your configuration definition is correct."
            continue
        }
        $mofDir = Resolve-Path -Path $mofDir

    }

    $packageDirectory = (Resolve-ScriptedToken -ScriptedToken $ServerConnection.PackageDirectory -ResolvedTokens $ResolvedTokens -Environment $Environment -Node $Node)
    if (!$packageDirectory) {
        $packageDirectory = "c:\PSCIPackage"
    }

    $requiredPackages = @((Resolve-ScriptedToken -ScriptedToken $Configuration.RequiredPackages -ResolvedTokens $ResolvedTokens -Environment $Environment -Node $Node))
    if ($requiredPackages) {
        $packagePath = (Get-ConfigurationPaths).PackagesPath
        foreach ($package in $requiredPackages) {
            $dir = Join-Path -Path $packagePath -ChildPath $package
            if (!(Test-Path -Path $dir)) {
                Write-Log -Critical "A required package named '$package' does not exist at '$dir' (defined in environment '$Environment' / ServerRole '$($ServerRole.Name)' / Configuration '$($Configuration.Name)'."
            }
        }
    }

    return [PSCustomObject]@{ 
        EntryNo = $entryNo
        ConnectionParams = $connectionParamsObj
        RunOnConnectionParams = $runOnConnectionParamsObj
        PackageDirectory = $packageDirectory;
        IsLocalRun = $isLocalRun
        Environment = $Environment;
        ServerRole = $ServerRole.Name;
        ConfigurationName = $Configuration.Name
        ConfigurationType = $Configuration.Type
        ConfigurationMofDir = $mofDir
        Tokens = $ResolvedTokens; 
        TokensOverride = $TokensOverride;
        RequiredPackages = $requiredPackages
        RebootHandlingMode = $RebootHandlingMode
    }
}

