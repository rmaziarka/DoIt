<#
The MIT License (MIT)

Copyright (c) 2015 Objectivity Bespoke Software Specialists

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

function Get-DscResourceWmiClass {
    <#
        .Synopsis
            Retrieves WMI classes from the DSC namespace. Source https://github.com/PowerShellOrg/DSC/blob/master/Tooling/dscbuild/DscResourceWmiClass.ps1.
        .Description
            Retrieves WMI classes from the DSC namespace.
        .Example
            Get-DscResourceWmiClass -Class tmp*
        .Example
            Get-DscResourceWmiClass -Class 'MSFT_UserResource'
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param (
        #The WMI Class name search for.  Supports wildcards.
        [parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Name')]
        [string]
        $Class
    )
    begin {
        $DscNamespace = "root/Microsoft/Windows/DesiredStateConfiguration"        
    }
    process {        
        Get-wmiobject -Namespace $DscNamespace -list @psboundparameters
    }
}


function Remove-DscResourceWmiClass {
    <#
        .Synopsis
            Removes a WMI class from the DSC namespace. Source https://github.com/PowerShellOrg/DSC/blob/master/Tooling/dscbuild/DscResourceWmiClass.ps1.
        .Description
            Removes a WMI class from the DSC namespace.
        .Example
            Get-DscResourceWmiClass -Class tmp* | Remove-DscResourceWmiClass
        .Example
            Remove-DscResourceWmiClass -Class 'tmpD460'
            
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param (
        #The WMI Class name to remove.  Supports wildcards.
        [parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [alias('Name')]
        [string]
        $ResourceType
    )
    begin {
        $DscNamespace = "root/Microsoft/Windows/DesiredStateConfiguration"        
    }
    process { 
        #Have to use WMI here because I can't find how to delete a WMI instance via the CIM cmdlets.       
        (Get-wmiobject -Namespace $DscNamespace -list -Class $ResourceType).psbase.delete()
    }
}


function Clear-DscCache {
    <#
    .SYNOPSIS
    Clears local DSC cache. Source https://github.com/PowerShellOrg/DSC/blob/master/Tooling/dscbuild/Clear-CachedDscResource.ps1.

    .DESCRIPTION
    When you change a DSC resource, it can happen that it is not updated due to caching in WMI Provider Host Process.
    This cmdlet stops the process which clears the cache.
    
    .LINK
    http://social.technet.microsoft.com/Forums/windowsserver/en-US/58352ed2-869a-45be-ad61-9019bb975cc7/desired-state-configuration-manager-caching-custom-resource-scripts?forum=winserverpowershell
    
    .EXAMPLE
    Clear-DscCache

    #>
    [CmdletBinding()]
    [OutputType([void])]
    param() 

    Write-Verbose 'Stopping any existing WMI processes to clear cached resources.'
    Get-process -Name WmiPrvSE -erroraction silentlycontinue | stop-process -force 


    Write-Verbose 'Clearing out any tmp WMI classes from tested resources.'
    Get-DscResourceWmiClass -class tmp* | remove-DscResourceWmiClass

}