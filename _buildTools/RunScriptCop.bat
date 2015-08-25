@echo off
pushd %~dp0
SET SCRIPTCOP_PATH=%1
SET SCRIPTCOP_EXCLUDE=%2
IF "%1"=="" SET SCRIPTCOP_PATH=%~dp0..
IF "%2"=="" SET SCRIPTCOP_EXCLUDE="@('bat','_buildTools','dsc','externalLibs','teamcityProvisioning','examples','configurations')"

powershell -command "& {. '.\Invoke-ScriptCop.ps1'; Invoke-ScriptCop -Path '%SCRIPTCOP_PATH%' -ExcludeNames %SCRIPTCOP_EXCLUDE% }"
if "%TEAMCITY_VERSION%"=="" pause
EXIT /B %errorlevel%

:parametermissing
echo %0 path