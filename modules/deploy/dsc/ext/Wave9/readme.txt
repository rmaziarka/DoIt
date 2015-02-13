This folder contains DSC Resource Kit: https://gallery.technet.microsoft.com/scriptcenter/DSC-Resource-Kit-All-c449312d

Custom modifications listed below:
1. xWebAdministration / MSFT_xWebsite.psm1
    - Each "Get-Website $Name" invocation replaced with "Get-Item "IIS:\sites\$Name" due to known IIS7 Get-Website bug where parameter -Name is ignored, see http://forums.iis.net/p/1167298/1943273.aspxm
    - New-Website workaround for Windows 2008 R2 - see comment 'this is a workaround for 2008 R2'
    - Fixed exception messages - if $PSCmdlet.ThrowTerminatingError is invoked from 'catch' block, its error message is "$($_.Exception.Message) / $($_.ScriptStackTrace)" instead of a generic message without any information about the original exception.
	- Added '-ErrorAction SilentlyContinue' to each $allDefaultPage assignment - it causes issues on WinServer2008R2 ('Error: The configuration section 'system.web.extensions' cannot be read because it is missing a section declaration')

3. xWebAdministration / MSFT_xWebVirtualDirectory.psm1 
      - added [AllowEmptyString()] above every $WebApplication parameter to enable creating virtual directories on web site level
		
4. xPSDesiredStateConfiguration / MSFT_xServiceResource.psm1
      - modified to be idempotent - see https://gallery.technet.microsoft.com/scriptcenter/DSC-Resource-Kit-All-c449312d/view/Discussions
	  - increased timeout from 2 s to 30 s