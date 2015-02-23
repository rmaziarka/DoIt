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

Configuration WebServerProvision {
    param ($NodeName, $Environment, $Tokens)

    Import-DSCResource -Module cIIS
    # DSC Wave resources are included in PSCI
    Import-DSCResource -Module xNetworking

    Node $NodeName {

        #TODO: install IIS features

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


function WebServerDeploy {
    param ($NodeName, $Environment, $Tokens, $ConnectionParams)

    $msDeployParams = @{ PackageName = 'SampleWebApplication';
                         PackageType = 'Web';
                         Node = $NodeName;
                         MsDeployDestinationString = $ConnectionParams.MsDeployDestinationString
                         TokensForConfigFiles = $Tokens.WebTokensConfig;
                         FilesToIgnoreTokensExistence = @( 'NLog.config' );
                         Website = $Tokens.WebConfig.WebsiteName;
                         SkipDir = 'App_Data';
                         Environment = $Environment
					   }

    Deploy-MsDeployPackage @msDeployParams
}

function DatabaseDeploy {
    param ($NodeName, $Environment, $Tokens, $ConnectionParams)

    $databaseName = $Tokens.DatabaseConfig.DatabaseName
    $connectionString = $Tokens.DatabaseConfig.ConnectionString
    if ($Tokens.DatabaseConfig.DropDatabase) { 
        Remove-SqlDatabase -DatabaseName $databaseName -ConnectionString $connectionString
    }

    Deploy-EntityFrameworkMigratePackage -PackageName 'Migrations' -ConnectionString $connectionString -MigrateAssembly 'DataModel.dll'

    $defaultAppPoolUserName = "IIS AppPool\$($Tokens.WebConfig.AppPoolName)"
    Update-SqlLogin -ConnectionString $connectionString -Username $defaultAppPoolUserName -WindowsAuthentication
    Update-SqlUser -ConnectionString $connectionString -DatabaseName $databaseName -Username $defaultAppPoolUserName -DbRole 'db_datareader'
}

function ValidateDeploy {
    param ($NodeName, $Environment, $Tokens, $ConnectionParams)

    $url = "http://${NodeName}:$($Tokens.WebConfig.WebsitePort)"
    Write-Log -Info "Sending HTTP GET request to '$url'"
    $result = Invoke-WebRequest -Uri $url -UseBasicParsing
    if ($result.StatusCode -ne 200) {
        Write-Log -Critical "Web page at $url is not available - response status code: $($result.StatusCode)."
    }
    if ($result.Content -inotmatch 'id: 1, name: OrderFromDatabase') {
        Write-Log -Critical "Web page at $url returns invalid response - does not include order information from database."
    }
    Write-Log -Info 'HTTP response contains information from database - deployment successful.'
}