# Powershell DSC Configuration Script for installing 7-Zip versions 15.05, 9.38, and 9.20. This Configuration Script supports both 32-bit and 64-bit architectures for all 3 versions.
# Vasken Houdoverdov
#
# Each of these calls to Sample_Install7zip will generate a MOF file which can be fed into Start-DscConfiguration
#
# 7-Zip Version 1505, 64-bit: 
# Sample_Installx7Zip -VersionNumber 1505 -MachineBits x64 -LocalPath 'C:\Windows\DtlDownloads\7zip Setup 1505-x64.exe'
# 7-Zip Version 1505, 32-bit: 
# Sample_Installx7Zip -VersionNumber 1505 -MachineBits x86 -LocalPath 'C:\Windows\DtlDownloads\7zip Setup 1505.exe'
# 7-Zip Version 938, 64-bit: 
# Sample_Installx7Zip -VersionNumber 938 -MachineBits x64 -LocalPath 'C:\Windows\DtlDownloads\7zip Setup 938-x64.msi'
# 7-Zip Version 938, 32-bit: 
# Sample_Installx7Zip -VersionNumber 938 -MachineBits x86 -LocalPath 'C:\Windows\DtlDownloads\7zip Setup 938.exe'
# 7-Zip Version 920, 64-bit: 
# Sample_Installx7Zip -VersionNumber 920 -MachineBits x64 -LocalPath 'C:\Windows\DtlDownloads\7zip Setup 920-x64.msi'
# 7-Zip Version 1505, 32-bit: 
# Sample_Installx7Zip -VersionNumber 920 -MachineBits x86 -LocalPath 'C:\Windows\DtlDownloads\7zip Setup 920-x64.exe'

Configuration Sample_Installx7Zip
{
    param
    (
	[Parameter(Mandatory)]
	$VersionNumber,
    [Parameter(Mandatory)]
	$MachineBits,
    [Parameter(Mandatory)]
	$LocalPath			
    )
	
    Import-DscResource -module x7Zip
	
    VH_x7Zip 7zip
    {
	VersionNumber = $VersionNumber
    MachineBits = $MachineBits
	LocalPath = $LocalPath
    }
}