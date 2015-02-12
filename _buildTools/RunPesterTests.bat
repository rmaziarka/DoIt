@echo off
call Pester\bin\Pester.bat -Tag PSCI.unit,PSCI.integration -Path ..
pause
