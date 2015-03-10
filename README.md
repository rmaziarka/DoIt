### PSCI - Powershell Continuous Integration / Configuration as Code
-------------
PSCI is a build and deployment automation library, that provides a simple Powershell DSC-like language that allows to express configuration as code. It provides following features:
- simple DSL to describe Environments, Server Roles, Server Connections, Configurations and Tokens (per-environment parameters), 
- written entirely in Powershell (requires Powershell 3.0, or 4.0 for DSC support),
- provisioning mechanism that is based on Powershell Desired State Configuration technology or custom Powershell functions,
- agentless architecture - deployment to remote environments pushes packages and execute code remotely using Powershell Remoting (WinRM) or Web Deploy, 
- reliable logging mechanism throughout the whole build and deployment process - every step is logged to console, text file and event log (optionally), errors include full stack trace / script lines information and friendly messages,
- building and deploying various types of packages (MsDeploy - e.g. ASP.NET MVC or WPF, SQL, DbDeploy, Entity Framework Migrations, SSRS, SSAS, SSIS), easily extensible with new types of packages,
- supports several methods of tokenizing configuration files (e.g. Web.config) - directly replace tokens in files (using regex), transform using XDT (Web.\<env_name\>.config) or use Web Deploy parameterization,
- supports Windows Server 2008 R2 SP1 / 7 and above (some Wave DSCs like xWebsite have been fixed to work with pre-Server 2012),

#### Example - web application with database
-------------
topology.ps1 - defining what to deploy (Configurations), where and how (ServerConnections):

```powershell

Environment Default {
    ServerConnection WebServer -Nodes localhost
    ServerConnection DatabaseServer -Nodes localhost
  
    ServerRole Web -Configurations WebServerProvision,WebServerDeploy -ServerConnections WebServer
    ServerRole Database -Configurations DatabaseDeploy -ServerConnections DatabaseServer -RunRemotely
}

Environment Test {
    ServerConnection WebServer -Nodes TestWeb.local.domain -RemotingMode PSRemoting
    ServerConnection DatabaseServer -Nodes TestDb.local.domain -RemotingMode PSRemoting
}

Environment UAT {
    ServerConnection WebServer -Nodes UATWeb.remote.domain -RemotingMode WebDeployHandler
    ServerConnection DatabaseServer -Nodes UATDB.remote.domain -Authentication CredSSP -Protocol HTTPS 
}

```
tokens.ps1 - defining parameters for each environment (with inheritance):

```powershell

Environment Default {
    Tokens WebConfig @{
      AppPoolName = 'TestAppPool'
      WebsiteName = 'TestWebsite'
      WebsitePort = 80
      WebsitePhysicalPath = 'c:\inetpub\wwwroot\TestWebsite'
    }
  
    Tokens DatabaseConfig @{
      ConnectionString = 'Server=${Node};Integrated Security=SSPI'
      DropDatabase = $true
    }
}

Environment UAT -BasedOn Default {
    Tokens WebConfig @{
      AppPoolName = 'UATAppPool'
      WebsiteName = 'UATWebsite'
      WebsitePort = 8080
    }
  
    Tokens DatabaseConfig @{
      DropDatabase = $false
    }
}

```
configurations.ps1 - defining what to actually deploy on remote servers:

```powershell

# this DSC configuration will be applied on nodes defined in 'ServerConnection WebServer'
Configuration WebServerProvision {
    param ($NodeName, $Environment, $Tokens)
  
    # DSC Wave resources are included in PSCI
    Import-DSCResource -Module xWebAdministration
  
    Node $NodeName {
        # configure application pool
        xWebAppPool MyWebAppPool { 
            Name   = $Tokens.WebConfig.AppPoolName
            Ensure = 'Present' 
            State  = 'Started'
        }
      
        # create website directory
        File MyWebsiteDir {
            DestinationPath = $Tokens.WebConfig.WebsitePhysicalPath
            Ensure = 'Present'
            Type = 'Directory'
        }

        # create site on IIS
        xWebsite MyWebsite { 
  	        Name = $Tokens.WebConfig.WebsiteName
            ApplicationPool = $Tokens.WebConfig.AppPoolName 
            BindingInfo = MSFT_xWebBindingInformation { 
                Port = $Tokens.WebServerConfig.WebsitePort
            } 
            PhysicalPath = $Tokens.WebConfig.WebsitePhysicalPath
            Ensure = 'Present' 
            State = 'Started' 
            DependsOn = @('[File]MyWebsiteDir')
      } 
}

# this function will be run locally (because related ServerRole has no -RunRemotely switch)
function WebServerDeploy {
    param ($NodeName, $Environment, $Tokens, $ConnectionParams)
  
    # we can run msdeploy manually from a function that is run locally
    $msDeployParams = @{ PackageName = 'MyWebsite'
                         PackageType = 'Web'
                         Node = $NodeName
                         MsDeployDestinationString = $ConnectionParams.MsDeployDestinationString
                         Website = $Tokens.WebConfig.WebsiteName
                         SkipDir = 'App_Data'
                         Environment = $Environment
                       }
  
    Deploy-MsDeployPackage @msdeployParams
}

# this function will be run remotely on nodes defined in 'ServerConnection DatabaseServer' (because related ServerRole has -RunRemotely switch)
function DatabaseDeploy {
    param ($NodeName, $Environment, $Tokens, $ConnectionParams)
  
    $databaseName = $Tokens.DatabaseConfig.DatabaseName
    $connectionString = $Tokens.DatabaseConfig.DatabaseDeploymentConnectionString
    if ($Tokens.DatabaseConfig.DropDatabase) { 
      Remove-SqlDatabase -DatabaseName $databaseName -ConnectionString $connectionString
      New-SqlDatabase -DatabaseName $databaseName -ConnectionString $connectionString
    }
    
    # we can for example run some commands directly
    Invoke-Sql -ConnectionString $connectionString -Query "USE ${databaseName}; PRINT 'some commands'"
    
    # or run every sql file that is available in package named 'sql' (assuming we have built the package beforehand)
    Deploy-SqlPackage -PackageName 'sql' -ConnectionString $connectionString
    
    # or restore database from backup
    Restore-SqlDatabase -ConnectionString $connectionString -Path $Tokens.DatabaseConfig.BackupPath -DatabaseName $databaseName 
    
    # or use other functions from PSCI, e.g. Deploy-EntityFrameworkMigratePackage, Deploy-DBDeploy, Deploy-SSRS*
}
```
Starting the deployment to 'Test' environment:
```powershell
.\deploy.ps1 -Environment Test
```

#### Where to start?
-------------
- Checkout the code and explore a little (note there are lot of files - [PsISEProjectExplorer](https://github.com/mgr32/PsISEProjectExplorer) might come in handy).
- Ensure Powershell remoting is enabled on your local machine (check by running `Invoke-Command -ComputerName localhost -ScriptBlock { Write-Host 'test' }`). If not, run `Enable-PSRemoting`.
- Go into `examples\simple` directory and run deploy.ps1. This will create 'c:\test1' directory using a DSC configuration from `configuration.ps1` and write greetings using a Powershell function from the same file. The 'c:\test1' is a variable defined in `tokens.ps1`,
- Look into `topology.ps1` - this is where you configure what should be deployed where. Note there are three environments defined - `Default`, `SecondEnv` and `RemoteRun`. 
- Go into `deploy.ps1`, change parameter value `$Environment = 'Default'` to  `$Environment = 'SecondEnv'` and run the file. It will create 'c:\test2' (thanks to different variable value for `SecondEnv` in `tokens.ps1`).
- Set `$Environment = 'RemoteRun'` and run it again. This time, PSCI will firstly copy itself to the remote server (`localhost` in our case) and then run the configurations remotely (using PSRemoting). This is thanks to `-RunRemotely` flag in `topology.ps1`.
- Look at more complex `examples`.
