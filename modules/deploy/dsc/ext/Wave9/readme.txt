This folder contains DSC Resource Kit: https://gallery.technet.microsoft.com/scriptcenter/DSC-Resource-Kit-All-c449312d

Custom modifications listed below:
1. MSFT_xWebsite.psm1
    - Set-TargetResource
        - each "get-website $Name" invocation replaced with "Get-Item "IIS:\sites\$Name" due to known IIS7 Get-Webiste bug where parameter -Name is ignored, see see http://forums.iis.net/p/1167298/1943273.aspxm
        - New-Website workaround - see comment 'this is a workaround for 2008 R2'
    - Fixed exception messages - if $PSCmdlet.ThrowTerminatingError is invoked from 'catch' block, its error message is "$($_.Exception.Message) / $($_.ScriptStackTrace)" instead of a generic message without any information about the original exception.
		
2. MSFT_xWebSite.psm1 -> DON'T UPDATE TO Wave7 as it causes issues on WinServer2008R2 ('Error: The configuration section 'system.web.extensions' cannot be read because it is missing a section declaration')

3. MSFT_xWebVirtualDirectory.psm1 
      - added [AllowEmptyString()] above every $WebApplication parameter to enable creating virtual directories on web site level
		
4. MSFT_xServiceResource.psm1
      - modified to be idempotent - see https://gallery.technet.microsoft.com/scriptcenter/DSC-Resource-Kit-All-c449312d/view/Discussions