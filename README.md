PSCI
=======
PSCI is a build and deployment automation library, that provides a simple Powershell DSC-like language that allows to express configuration as code. It provides following features:
- simple DSL to describe Environments, Server Roles, Server Connections, Configurations and Tokens (per-environment parameters), 
- written entirely in Powershell (requires Powershell 3.0, or 4.0 for DSC support),
- provisioning mechanism that is based on Powershell Desired State Configuration technology or custom Powershell functions,
- agentless architecture - deployment to remote environments pushes packages and execute remote code using Powershell Remoting (WinRM) or Web Deploy, 
- reliable logging mechanism throughout the whole build and deployment process - every step is logged to console, text file and event log (optionally), errors include full stack trace / script lines information and friendly messages,
- building and deploying various types of packages (MsDeploy, SQL, DbDeploy, Entity Framework Migrations, SSRS, SSAS, SSIS), easily extensible with new types of packages,
- supports Windows Server 2008 R2 SP1 and above (some Wave DSCs like xWebsite have been fixed to work with < Server 2012).


Example
-------------

