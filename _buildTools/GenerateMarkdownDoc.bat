@echo off
powershell -NonInteractive -NoProfile -ExecutionPolicy Bypass -Command ^
 "& { Import-Module '%~dp0\..\DoIt.psd1'; . %~dp0\New-MarkdownDoc.ps1; @('DoIt.core', 'DoIt.build', 'DoIt.deploy', 'DoIt.teamcityExtensions', 'DoIt.teamcityMaintenance') | Foreach-Object { New-MarkdownDocModule -ModuleName $_ -OutputPath '%~dp0\..\..\DoIt.wiki'}; New-MarkdownDocDirectory -Path '%~dp0\..\modules\deploy\BuiltinSteps' -OutputPath '%~dp0\..\..\DoIt.wiki' }"
if "%TEAMCITY_VERSION%"=="" pause
exit /B %errorlevel%
