@ECHO OFF
SET ARGS=%*
if NOT '%1'=='' SET ARGS=%ARGS:"=\"% 
if '%1'=='' SET ARGS=-Tag PSCI.unit,PSCI.integration -Path %~dp0..

%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NonInteractive -NoProfile -ExecutionPolicy Bypass -Command ^
 "& { Import-Module '%~dp0\Pester\Pester.psm1'; Invoke-Pester -OutputFile Test.xml -OutputFormat NUnitXml -Strict -EnableExit %ARGS%}"
if '%TEAMCITY_VERSION%'=='' pause
