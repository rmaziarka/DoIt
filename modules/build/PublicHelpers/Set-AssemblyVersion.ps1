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

function Set-AssemblyVersion { 
     <#
    .SYNOPSIS
    Sets version in the assembly info file.

    .PARAMETER Path
    Path to the assembly info file.

    .PARAMETER Version
    Version number to set.

    .PARAMETER VersionAttribute
    Version attribute to set - see http://stackoverflow.com/questions/64602/what-are-differences-between-assemblyversion-assemblyfileversion-and-assemblyin.

    .EXAMPLE
    Set-AssemblyVersion -Path 'C:\Projects\MyProjectName\trunk\Src\CSProjectName\Properties\AssemblyInfo.cs' -Version '1.0.1.2'

    #>

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Path,

        [Parameter(Mandatory=$true)]
        [string]
        $Version,

        [Parameter(Mandatory=$false)]
        [string[]]
        [ValidateSet($null, 'AssemblyVersion', 'AssemblyFileVersion', 'AssemblyInformationalVersion')]
        $VersionAttribute = 'AssemblyVersion'
    )

    if (!(Test-Path -Path $Path)) {
        Write-Log -Critical "Path '$Path' does not exist."
    }

    if (!$VersionAttribute) {
        $VersionAttribute = 'AssemblyVersion'
    }

    Write-Log -Info "Setting $($VersionAttribute -join ', ')='$Version' in file '$Path'"

    $regexes = @()
    foreach ($attr in $VersionAttribute) { 
        $regexes += ('({0})\(\"([^\"]*)\"\)' -f $attr)
    }
    $regexReplace = '$1("{0}")' -f $Version    

	Disable-ReadOnlyFlag -Path $Path
	(Get-Content -Path $Path -Encoding UTF8 -ReadCount 0) | Foreach-Object {
            $line = $_
            foreach ($regex in $regexes) {
                $line = $line -ireplace $regex, $regexReplace
            }
			$line
	} | Set-Content -Encoding UTF8 -Path $Path
}