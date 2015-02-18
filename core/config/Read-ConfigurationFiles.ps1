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

function Read-ConfigurationFiles {
    <#
    .SYNOPSIS
        Reads configuration files and analyzes 'Import-DSCResource' invocations to collect DSC module dependencies.

    .PARAMETER Path
        Path where the configuration files will be read from.

    .OUTPUTS
        PSCustom object with following properties:
          Files - array containing full paths to the configuration files
          RequiredDSCModules - array containing names of required DSC modules

    .EXAMPLE
        $configInfo = Read-ConfigurationFiles -Path $DeployConfigurationPath
    #>

    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Path
    ) 

    if (!(Test-Path -Path $Path)) {
        Write-Log -Critical "Path that should contain configuration files ('$Path') does not exist. Please ensure you have passed valid 'DeployConfigurationPath' parameter."
    }
    $Path = Resolve-Path -Path $Path
    Write-Log -Info "Reading configuration files from '$Path'."
    # Load file with 'tokens' in the name first, since other files can make use of it
    $configScripts = Get-ChildItem -Recurse $Path -Include *.ps*1 | Sort-Object -Property { $_.Name -inotmatch "tokens" }, { $_.Name }
    if (!$configScripts) {
        Write-Log -Critical "There are no configuration files at '$Path'. Please ensure you have passed valid 'DeployConfigurationPath' parameter."
    }

    $result = [PSCustomObject]@{
        Files = @()
        RequiredDSCModules = @()
    }

    $invalidLineRegex = '(Import-DSCResource.*`[\s\\r\\n$])'
    $dscResourceRegex = 'Import-DSCResource\s+(?:-Module)?\s*([^-][^\s;]+)|Import-DSCResource.+-Module\s*([^-][^\s;]+)'

    foreach ($script in $configScripts) {
        $contents = Get-Content -Path $script.FullName -ReadCount 0 | Out-String
        if ($contents -imatch $invalidLineRegex) {
            Write-Log -Critical "File '$Path' contains 'Import-DSCResource' line that ends with backtick, which is not allowed. Please change it to fit into one line. Offending line: $($matches[0])"
        }
        $result.Files += $script.FullName
        $matchInfo = Select-String -InputObject $contents -Pattern $dscResourceRegex -AllMatches
        foreach ($match in $matchInfo.Matches) {
            if ($match.Groups[1].Success) {
               $moduleName = $match.Groups[1].Value
            } elseif ($match.Groups[2].Success) {
               $moduleName = $match.Groups[2].Value
            } else {
                Write-Log -Critical "Critical regex error during reading file '$Path' - matches.Groups: $($matches.Groups)"
            }
            if ($moduleName -imatch '\$') {
                Write-Log -Critical "File '$Path' contains 'Import-DSCResource' invocation with a variable substitution which is not allowed. Please change it to a string. Offending line: $($match.Value)"
            }
            $moduleName = $moduleName -replace '"', ''
            $moduleName = $moduleName -replace "'", ''
            if ($result.RequiredDSCModules -inotcontains $moduleName) {
                $result.RequiredDSCModules += $moduleName
            }
        }
    }

    return $result
}