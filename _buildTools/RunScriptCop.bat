@echo off
pushd %~dp0
SET SCRIPTCOP_PATH=%1
SET SCRIPTCOP_EXCLUDE=%2
SET SCRIPTCOP_PREREQ=%3
IF "%1"=="" SET SCRIPTCOP_PATH=%~dp0..
IF "%2"=="" SET SCRIPTCOP_EXCLUDE="@('bat','_buildTools','dsc','externalLibs','teamcityProvisioning')"
IF "%3"=="" SET SCRIPTCOP_PREREQ=%~dp0..\PSCI.classes.ps1,%~dp0..\core\Write-ProgressExternal.ps1
)
powershell -command "& {. '.\Invoke-ScriptCop.ps1'; Invoke-ScriptCop -Path '%SCRIPTCOP_PATH%' -ExcludeNames %SCRIPTCOP_EXCLUDE% -PrerequisitesPaths %SCRIPTCOP_PREREQ% }"
EXIT /B %errorlevel%

:parametermissing
echo %0 path