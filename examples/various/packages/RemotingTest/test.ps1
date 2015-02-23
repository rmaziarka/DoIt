[void](New-Item -Path 'c:\PSCITest' -ItemType Directory -Force)
[void](New-Item -Path 'c:\PSCITest\RemotingTestEvidence' -ItemType File -Value 'test' -Force)
Write-Host 'Created file c:\PSCITest\RemotingTestEvidence.'