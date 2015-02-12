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

#
# cWindowsFeatureClient: DSC resource to install Windows Features on client SKUs (using DISM)
#

#
# The Get-TargetResource cmdlet.
#
function Get-TargetResource
{
    param
    (	
        [parameter(Mandatory=$true)] 
        [ValidateNotNullOrEmpty()]
        [string] 
        $Name,

        [parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Source
    )

    $cmd = "dism /online /Get-FeatureInfo /FeatureName:$Name"
    
    $dismResult = Invoke-Expression $cmd
    if ($lastexitcode -ne 0) {
        throw "Dism failed with exitcode $lastexitcode. Output: $dismResult"
    }

    if ($dismResult -match "State : Disabled") {
        $ensure = "Absent"
    } elseif ($dismResult -match "State : Enabled") { 
        $ensure = "Present"
    } else {
        throw "Cannot get state of feature '$Name' - dism output: $dismResult"
    }

    return @{ 
        Name = $Name; 
        Ensure = $ensure
    }

}


#
# The Set-TargetResource cmdlet.
#
function Set-TargetResource
{
    param
    (	
        [parameter(Mandatory=$true)] 
        [ValidateNotNullOrEmpty()]
        [string] 
        $Name,

        [parameter()]
        [ValidateSet("Present", "Absent")]
        [string]
        $Ensure = "Present",
        
        [parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Source

    )

    #TODO: Ensure = Absent
    Write-Verbose "Installing feature named '$Name' using dism."
    $cmd = "dism /online /Enable-Feature /all /FeatureName:$Name"
    if ($Source) {
        $cmd += " /Source:$Source"
    }

    $dismResult = Invoke-Expression $cmd
    if ($lastexitcode -ne 0) {
        throw "Dism failed with exitcode $lastexitcode. Output: $dismResult"
    }

    if ($dismResult) {
        Write-Verbose -Message $dismResult.ToString()
    }
}

#
# The Test-TargetResource cmdlet.
#
function Test-TargetResource
{
    param
    (	
        [parameter(Mandatory=$true)] 
        [ValidateNotNullOrEmpty()]
        [string] 
        $Name,

        [parameter()]
        [ValidateSet("Present", "Absent")]
        [string]
        $Ensure = "Present",

        [parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Source
    )

    $info = Get-TargetResource -Name $Name 
    
    return ($info.Ensure -eq $Ensure)
}



Export-ModuleMember -Function *-TargetResource
