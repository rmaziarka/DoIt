$Global:ErrorActionPreference = 'Stop'
Import-Module "$PSScriptRoot\..\..\..\PSCI.psm1" -Force
Install-DSCResources -ModuleNames 'all'