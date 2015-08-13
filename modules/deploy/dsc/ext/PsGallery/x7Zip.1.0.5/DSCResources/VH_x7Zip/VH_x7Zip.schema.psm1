# Powershell DSC Resource for 7-Zip versions 15.05, 9.38, and 9.20
# vasken@ucr.edu
#
# $MachineBits should be either "x64" or "x86"
# $VersionNumber should be "1505" or "938" or "920"
# Exe installations are used for all 32-bit versions and the latest version (15.05)
# MSI installations are used for the 64-bit versions of 9.38 and 9.20

Configuration VH_x7Zip
{
    param
    (
        [ValidateSet("1505","938","920")] 
        [string]$VersionNumber = "1505",
        [ValidateSet("x86","x64")] 
        [string]$MachineBits = "x64",
        [string]$LocalPath = "$env:SystemDrive\Windows\DtlDownloads\7zip Setup " + $VersionNumber
    )

        Import-DscResource -ModuleName xPSDesiredStateConfiguration
        Import-DscResource -ModuleName PSDesiredStateConfiguration

    if($MachineBits -eq "x64")
    {
        if($VersionNumber -eq "938")
        {
            $installer = "msi"
            $URI = "http://www.7-zip.org/a/7z" + $VersionNumber + "-" + $MachineBits + ".$installer"
            $LocalPath = "$env:SystemDrive\Windows\DtlDownloads\7zip Setup " + $VersionNumber + ".$installer"
            $Name = "7-Zip 9.38 (x64 edition)"
        }
        if($VersionNumber -eq "920")
        {
            $installer = "msi"
            $URI = "http://www.7-zip.org/a/7z" + $VersionNumber + "-" + $MachineBits + ".$installer"
            $LocalPath = "$env:SystemDrive\Windows\DtlDownloads\7zip Setup " + $VersionNumber + ".$installer"
            $Name = "7-Zip 9.20 (x64 edition)"
        }
        if($VersionNumber -eq "1505")
        {
            $installer = "exe"
            $URI = "http://www.7-zip.org/a/7z" + $VersionNumber + "-" + $MachineBits + ".$installer"
            $LocalPath = "$env:SystemDrive\Windows\DtlDownloads\7zip Setup " + $VersionNumber + ".$installer"
            $Name = "7-Zip 15.05 beta x64"
        }

    }
    if($MachineBits -eq "x86")
    {
        $installer = "exe"
        if($VersionNumber -eq "1505")
        {
            $URI = "http://www.7-zip.org/a/7z" + $VersionNumber + ".$installer"
            $Name = "7-Zip 15.05 beta"
            $LocalPath = "$env:SystemDrive\Windows\DtlDownloads\7zip Setup " + $VersionNumber + ".$installer"
        }
        if($VersionNumber -eq "938")
        {
            $URI = "http://www.7-zip.org/a/7z" + $VersionNumber + ".$installer"
            $Name = "7-Zip 9.38 beta"
            $LocalPath = "$env:SystemDrive\Windows\DtlDownloads\7zip Setup " + $VersionNumber + ".$installer"
        }
        if($VersionNumber -eq "920")
        {
         $URI = "http://www.7-zip.org/a/7z" + $VersionNumber + ".$installer"
         $Name = "7-Zip 9.20"
         $LocalPath = "$env:SystemDrive\Windows\DtlDownloads\7zip Setup " + $VersionNumber + ".$installer"
        }
    }

    xRemoteFile Downloader
    {
        Uri = $URI
        DestinationPath = $LocalPath
    }
  
  if($installer -eq "msi")
    { 
        $installArgs = "/q" 
    }
  if($installer -eq "exe")
    { 
        $installArgs = "/S" 
    }
    Package Installer
    {
        Ensure = "Present"
        Path = $LocalPath
        Name =  $Name
        ProductId = ''
        Arguments = $installArgs
        DependsOn = "[xRemoteFile]Downloader"
    }
 }