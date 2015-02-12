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

function Start-DeploymentPlanEntryLocally {
    <#
    .SYNOPSIS
    Runs the deployment locally basing on the deployment plan entry.

    .DESCRIPTION
    It iterates through the deployment plan and it either runs 'Start-DscConfiguration' or the specified function for each entry.

    .PARAMETER DeploymentPlanEntry
    Deployment plan entry.

    .PARAMETER DscForce
    If true, '-Force' parameter will be passed to 'Start-DscConfiguration'. It is required e.g. when last attempt failed and is still running.

    .EXAMPLE
    Start-DeploymentPlanEntryLocally -DeploymentPlanEntry $deploymentPlanEntry -Environment $Environment -DscForce:$DscForce
    
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $DeploymentPlanEntry,

        [Parameter(Mandatory=$true)]
        [switch]
        $DscForce
    )

    $connectionParams = $deploymentPlanEntry.ConnectionParams
    $configuration = $deploymentPlanEntry.Configuration
    $resolvedTokens = $deploymentPlanEntry.Tokens
    $rebootHandlingMode = $deploymentPlanEntry.RebootHandlingMode
    $environment = $DeploymentPlanEntry.Environment

    $configName = $configuration.Name

    if ($configuration.Type -eq "Configuration") {
        $mofDir = $configuration.MofDir

        $params = @{
            ConnectionParams = $connectionParams
            MofDir = $mofDir
            DscForce = $DscForce
            RebootHandlingMode = $rebootHandlingMode
        }

        Write-Log -Info "Deploying configuration '$configName' to node '$($connectionParams.NodesAsString)' using mof '$MofDir'"
        Start-DscConfigurationWithRetries @params

    } elseif ($configuration.Type -eq "Function") {
        Invoke-ConfigurationOrFunction -ConfigurationName $configName -Node $connectionParams.Nodes[0] -Environment $Environment -ResolvedTokens $resolvedTokens -ConnectionParams $ConnectionParams
    }
}
