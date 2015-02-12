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
This file contains configurations which will be deployed on each node defined in ServerRoles belonging to given environment.
Configuration can be one of the following:
   a) DSC configuration (example - WebServerProvision). It will be run on each node defined in ServerRole.
   b) Normal powershell functions - will be run locally. This is useful for example if you want to run msdeploy without using Powershell remoting.
#>

Configuration WebServerProvision {
    param ($NodeName, $Environment, $Tokens)
    
    Import-DSCResource -Module xWebAdministration
    Import-DSCResource -Module cWebAdministration
    Import-DSCResource -Module cPSCI

    Node $NodeName {

        cAppPool PSCITestAppPool { 
            Name   = $Tokens.WebServerProvision.AppPoolName 
            managedRuntimeVersion = 'v4.0'
            managedPipelineMode = 'Integrated'
            Ensure = 'Present' 
        }

        File PSCITestWebsiteDir {
            DestinationPath = $Tokens.WebServerProvision.WebsitePhysicalPath
            Ensure = 'Present'
            Type = 'Directory'
            DependsOn = @('[cAppPool]PSCITestAppPool')
        }

        xWebsite PSCIWebsite { 
            Name   = $Tokens.WebServerProvision.WebsiteName
			ApplicationPool = $Tokens.WebServerProvision.AppPoolName 
            Ensure = 'Present' 
            BindingInfo = MSFT_xWebBindingInformation { 
                            Port = $Tokens.WebServerProvision.WebsitePort
                        } 
            PhysicalPath = $Tokens.WebServerProvision.WebsitePhysicalPath
            State = 'Started' 
            DependsOn = @('[File]PSCITestWebsiteDir')
        } 
		

        cIISWebsiteAuthentication PSCIWebsiteWindowsAuth {
            WebsiteName =  $Tokens.WebServerProvision.WebsiteName
            Ensure = 'Present'
            AuthenticationMethod = 'Windows'
            DependsOn = @('[xWebSite]PSCIWebsite')
        }

        cIISWebsiteAuthentication PSCIWebsiteAnonymousAuth {
            WebsiteName =  $Tokens.WebServerProvision.WebsiteName
            Ensure = 'Present'
            AuthenticationMethod = 'Anonymous'
            DependsOn = @('[xWebSite]PSCIWebsite')
        }

    }
}

function DatabaseServerDeploy {
	param ($NodeName, $Tokens, $Environment)

    Deploy-SqlPackage -PackageName 'DatabaseCleanup' -ConnectionString $Tokens.DatabaseConfig.DatabaseDeploymentConnectionString -Credential $Tokens.Credentials.RemoteCredential
    Deploy-DBDeploySqlScriptsPackage -PackageName 'DatabaseUpdate' -ConnectionString $Tokens.DatabaseConfig.DatabaseDeploymentConnectionString -Credential $Tokens.Credentials.RemoteCredential

}

function RemotingTest {
	param ($NodeName, $Tokens, $Environment, $ConnectionParams)

    New-Item -Path 'c:\PSCITest' -ItemType Directory -Force
    $path = "c:\PSCITest\$($ConnectionParams.NodesAsString)_$($ConnectionParams.RemotingMode)_$($ConnectionParams.Authentication)"
    Write-Log -Info "Creating file '$fileName'"
    New-Item -Path $path -ItemType File -Force
}