@pushd %~dp0
@powershell -File deploy.ps1 -Environment dev
@pause