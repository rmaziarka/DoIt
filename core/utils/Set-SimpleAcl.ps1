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

function Set-SimpleAcl {
    <#
    .SYNOPSIS
    Sets a simple ACL rule for given Path.
            
    .PARAMETER Path
    Path to update.

    .PARAMETER User
    Username.

    .PARAMETER Permission
    Permission.

    .PARAMETER Type
    Type - Allow or Deny.

    .PARAMETER Inherit
    Inherit.

    .EXAMPLE
    Set-SimpleAcl -Path 'c:\test' -User 'Everyone' -Permission 'FullControl' -Type 'Allow'
    #>
    
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Path,

        [Parameter(Mandatory=$true)]
        [string]
        $User,

        [Parameter(Mandatory=$true)]
        [string]
        [ValidateSet('FullControl', 'Modify', 'ReadAndExecute', 'ListDirectory', 'Read', 'Write')]
        $Permission,

        [Parameter(Mandatory=$true)]
        [string]
        [ValidateSet('Allow', 'Deny')]
        $Type,

        [Parameter(Mandatory=$false)]
        [switch]
        $Inherit = $true

    ) 

    $acl = (Get-Item -Path $path).GetAccessControl('Access')

    if ($Inherit) {
        $inheritArg = @([System.Security.AccessControl.InheritanceFlags]::ContainerInherit,[System.Security.AccessControl.InheritanceFlags]::ObjectInherit)
    } else {
        $inheritArg = @([System.Security.AccessControl.InheritanceFlags]::None)
    }

    $propagation = [System.Security.AccessControl.PropagationFlags]::None

    Write-Log -Info "Setting ACL on '$Path' - '$Type' user '$User', permission '$Permission', inherit $Inherit"
    $accessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $User, $Permission, $inheritArg, $propagation, $Type

    $acl.AddAccessRule($accessRule)
    Set-Acl -Path $Path -AclObject $acl
}