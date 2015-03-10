# This file is a stub only to document Build-DeploymentScriptsPackage function, which is available in core\utils.


<#
.SYNOPSIS
Builds a package containing PSCI library and deployment configuration.

.DESCRIPTION
It copies the following to the destination package:
- PSCI library to $OutputPathPsci - by default only core functions, PSCI.deploy module and DSC modules that are used in configuration files will be copied.
    If you need additional modules or external libraries, use $ModulesToInclude or $ExternalLibsToInclude parameters.
- deploy.ps1 from current directory to $OutputPathDeploymentScripts
- project configuration files (tokens / server roles) from $deployConfigurationPath to $OutputPathDeploymentScripts\configuration.
These files are required for any deployment that is to be run by PSCI.

If $OutputPathPsci is not provided, it will be set to $PackagesPath\PSCI.
If $OutputPathDeploymentScripts is not provided, it will be set to $PackagesPath\DeployScripts.
    
.PARAMETER ReplaceDeployScriptParameters
If true, default variable values (paths) in deploy.ps1 file will be updated to reflect the default package directory structure.

.PARAMETER OutputPathPsci
Output path where the PSCI package will be created. If not provided, $OutputPath = $PackagesPath\PSCI, where $PackagesPath is taken from global variable.

.PARAMETER OutputPathDeploymentScripts
Output path where project configuration package will be created. If not provided, $OutputPath = $PackagesPath\DeokiyScripts, where $PackagesPath is taken from global variable.

.PARAMETER ModulesToInclude
List of PSCI modules to include. If empty, only 'PSCI.deploy' module will be included.

.PARAMETER ExternalLibsToInclude
List of external libraries from to include (will be copied from 'externalLibs' folder).

.EXAMPLE
Build-DeploymentScriptsPackage

#>
