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

Configuration ConfigureIISWebApp {
    param ($NodeName, $Environment, $Tokens)
    
    Import-DSCResource -Module cIIS

    Node $NodeName {

        cAppPool DoItTestAppPool { 
            Name   = $Tokens.WebServerProvision.AppPoolName 
            managedRuntimeVersion = 'v4.0'
            managedPipelineMode = 'Integrated'
            Ensure = 'Present' 
        }

        File DoItTestWebsiteDir {
            DestinationPath = $Tokens.WebServerProvision.WebsitePhysicalPath
            Ensure = 'Present'
            Type = 'Directory'
            DependsOn = @('[cAppPool]DoItTestAppPool')
        }

        cWebsite DoItWebsite { 
            Name   = $Tokens.WebServerProvision.WebsiteName
            ApplicationPool = $Tokens.WebServerProvision.AppPoolName 
            Ensure = 'Present' 
            BindingInfo = OBJ_cWebBindingInformation { 
                            Port = $Tokens.WebServerProvision.WebsitePort
                        } 
            PhysicalPath = $Tokens.WebServerProvision.WebsitePhysicalPath
            State = 'Started' 
            DependsOn = @('[File]DoItTestWebsiteDir')
        } 
        

        cIISWebsiteAuthentication DoItWebsiteWindowsAuth {
            WebsiteName =  $Tokens.WebServerProvision.WebsiteName
            Ensure = 'Present'
            AuthenticationMethod = 'Windows'
            DependsOn = @('[cWebsite]DoItWebsite')
        }

        cIISWebsiteAuthentication DoItWebsiteAnonymousAuth {
            WebsiteName =  $Tokens.WebServerProvision.WebsiteName
            Ensure = 'Present'
            AuthenticationMethod = 'Anonymous'
            DependsOn = @('[cWebsite]DoItWebsite')
        }

    }
}