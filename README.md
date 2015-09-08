### PSCI - Powershell Continuous Integration / Configuration as Code
-------------
PSCI is a build and deployment automation library, that provides a simple Powershell DSC-like language that allows to express configuration as code. The general flow is presented on the image below:
![PSCI overview](https://github.com/ObjectivityBSS/PSCI/wiki/images/PSCI_overview.png)

PSCI provides following features:
- simple DSL to describe Environments, Server Roles, Server Connections, Configurations and Tokens (per-environment parameters), 
- written entirely in Powershell (requires Powershell 3.0, or 4.0 for DSC support),
- provisioning mechanism that is based on Powershell Desired State Configuration resources or custom Powershell functions,
- agentless architecture - deployment to remote environments pushes packages and execute code remotely using Powershell Remoting (WinRM) or Web Deploy, 
- reliable logging mechanism throughout the whole build and deployment process - every step is logged to console, text file and event log (optionally), errors include full stack trace / script lines information and friendly messages,
- building and deploying various types of packages (MsDeploy - e.g. ASP.NET MVC or WPF, SQL, DbDeploy, Entity Framework Migrations, SSRS, SSAS, SSIS), easily extensible with new types of packages,
- supports several methods of tokenizing configuration files (e.g. Web.config) - directly replace tokens in files (using regex), transform using XDT (Web.\<env_name\>.config) or use Web Deploy parameterization,
- supports Windows Server 2008 R2 SP1 / 7 and above (some available DSC resources like xWebsite have been fixed to work with pre-Server 2012).

#### Where to start?
-------------
- See [Getting started](https://github.com/ObjectivityBSS/PSCI/wiki/Getting-started).
- Checkout the code and explore a little (note there are lot of files - [PsISEProjectExplorer](https://github.com/mgr32/PsISEProjectExplorer) might come in handy).
- Ensure Powershell remoting is enabled on your local machine (check by running `Invoke-Command -ComputerName localhost -ScriptBlock { Write-Host 'test' }`). If not, run `Enable-PSRemoting`.
- Go into `examples\simple` directory and run deploy.ps1. This will create 'c:\test1' directory using a DSC configuration from `configuration.ps1` and write greetings using a Powershell function from the same file. The 'c:\test1' is a variable defined in `tokens.ps1`,
- Look into `topology.ps1` - this is where you configure what should be deployed where. Note there are three environments defined - `Default`, `SecondEnv` and `RemoteRun`. 
- Go into `deploy.ps1`, change parameter value `$Environment = 'Default'` to  `$Environment = 'SecondEnv'` and run the file. It will create 'c:\test2' (thanks to different variable value for `SecondEnv` in `tokens.ps1`).
- Set `$Environment = 'RemoteRun'` and run it again. This time, PSCI will firstly copy itself to the remote server (`localhost` in our case) and then run the configurations remotely (using PSRemoting). This is thanks to `-RunRemotely` flag in `topology.ps1`.
- Look at more complex [examples](https://github.com/ObjectivityBSS/PSCI/tree/master/examples).
