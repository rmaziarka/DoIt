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

    .PARAMETER DeploymentPlanGroupedEntry
    Deployment plan entry (grouped).

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
        $DeploymentPlanGroupedEntry,

        [Parameter(Mandatory=$true)]
        [switch]
        $DscForce
    )

    foreach ($configInfo in $DeploymentPlanGroupedEntry.GroupedConfigurationInfo) {
        Write-Log -Info ("[START] RUN LOCAL CONFIGURATION '{0}' / NODE '{1}'" -f $configInfo.Name, $configInfo.ConnectionParams.NodesAsString) -Emphasize
        Write-ProgressExternal -Message ('Deploying {0} to {1}' -f $configInfo.Name, $configInfo.ConnectionParams.NodesAsString) `
                               -ErrorMessage ('Deploy error - node {0}, conf {1}' -f $configInfo.ConnectionParams.NodesAsString, $configInfo.Name)
        if ($configInfo.Type -eq 'Configuration') {
            $params = @{
                ConnectionParams = $configInfo.ConnectionParams
                MofDir = $configInfo.MofDir
                DscForce = $DscForce
                RebootHandlingMode = $configInfo.RebootHandlingMode
            }

            #TODO: group DSCs that are next to each other and have the same ConnectionParams/RebootHandlingMode
            Start-DscConfigurationWithRetries @params
        } elseif ($configInfo.Type -eq "Function") {
            try { 
                $packagePath = (Get-ConfigurationPaths).PackagesPath
                Push-Location -Path $packagePath
                Invoke-ConfigurationOrFunction -ConfigurationName $configInfo.Name `
                                               -Node $configInfo.ConnectionParams.Nodes[0] `
                                               -Environment $configInfo.Environment `
                                               -ResolvedTokens $configInfo.Tokens `
                                               -ConnectionParams $configInfo.ConnectionParams
           } finally {
                Pop-Location
           }
        }
        Write-Log -Info ("[END] RUN LOCAL CONFIGURATION '{0}' / NODE '{1}'" -f $configInfo.Name, $configInfo.ConnectionParams.NodesAsString) -Emphasize
    }   
}
