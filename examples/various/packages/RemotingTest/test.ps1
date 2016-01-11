[void](New-Item -Path 'c:\DoItTest' -ItemType Directory -Force)
[void](New-Item -Path 'c:\DoItTest\RemotingTestEvidence' -ItemType File -Value 'test' -Force)
Write-Host 'Created file c:\DoItTest\RemotingTestEvidence.'