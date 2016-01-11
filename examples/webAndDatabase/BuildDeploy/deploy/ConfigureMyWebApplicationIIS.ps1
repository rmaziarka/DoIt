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

Configuration ConfigureMyWebApplicationIIS {
    param ($NodeName, $Environment, $Tokens)

    Import-DSCResource -Module cIIS
    # DSC PSGallery resources are included in DoIt
    Import-DSCResource -Module xNetworking

    Node $NodeName {

        # configure application pool
        cAppPool $Tokens.WebConfig.AppPoolName { 
            Name   = $Tokens.WebConfig.AppPoolName
            Ensure = 'Present'
            AutoStart = $true
            StartMode = 'AlwaysRunning'
            ManagedRuntimeVersion = 'v4.0'
            IdentityType = 'ApplicationPoolIdentity'
        } 

        # create website directory
        File MyWebsiteDir {
            DestinationPath = $Tokens.WebConfig.WebsitePhysicalPath
            Ensure = 'Present'
            Type = 'Directory'
        }

        # create site on IIS
        cWebsite MyWebsite { 
            Name   = $Tokens.WebConfig.WebsiteName
            ApplicationPool = $Tokens.WebConfig.AppPoolName 
            BindingInfo = OBJ_cWebBindingInformation { 
                Port = $Tokens.WebConfig.WebsitePort
            } 
            PhysicalPath = $Tokens.WebConfig.WebsitePhysicalPath
            Ensure = 'Present' 
            State = 'Started' 
            DependsOn = @('[File]MyWebsiteDir')
        }

        # you can write normal statements inside Configuration - for instance if you want to conditionally include a resource
        if ($Environment -ine 'Default' -and $Environment -ine 'Local') {
            xFirewall MyWebsiteFirewall {
                Name = 'MyWebsite'
                DisplayName = 'MyWebsite' 
                Ensure = 'Present' 
                Access = 'Allow' 
                State = 'Enabled'
                LocalPort = "$($Tokens.WebConfig.WebsitePort)"
                RemotePort = 'Any'
                Profile = 'Any'
                Direction = 'InBound'
                Protocol = 'TCP'
            }
        }
    }
}

