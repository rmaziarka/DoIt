@ECHO OFF
SET ARGS=%*
if NOT '%1'=='' SET ARGS=%ARGS:"=\"% 
if '%1'=='' SET ARGS=-Tag PSCI.unit,PSCI.integration -Path %~dp0..

if exist { %systemroot%\sysnative } ( 
   set pspath=%systemroot%\sysnative\WindowsPowerShell\v1.0\powershell.exe
) else (
   set pspath=%systemroot%\system32\WindowsPowerShell\v1.0\powershell.exe
)
%pspath% -NonInteractive -NoProfile -ExecutionPolicy Bypass -Command ^
 "& { Import-Module '%~dp0\Pester\Pester.psm1'; Invoke-Pester -OutputFile Test.xml -OutputFormat NUnitXml -Strict -EnableExit %ARGS%}"
if '%TEAMCITY_VERSION%'=='' pause
exit /B %errorlevel%