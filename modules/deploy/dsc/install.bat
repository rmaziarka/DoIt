@echo off
powershell -Command "& { Import-Module "%~dp0..\PSCI.psm1"; Install-DscResources }"
pause