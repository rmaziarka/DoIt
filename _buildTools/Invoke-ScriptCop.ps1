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

function Invoke-ScriptCop {
    <#
    .SYNOPSIS
    Runs ScriptCop on ps1 files.

    .PARAMETER Path
    Folder path to scan. If not given current path wil be used.

    .PARAMETER ExcludeNames
    Names to exclude from scanning (e.g. directory names) - will be converted to regex.

    .PARAMETER PrerequisitesPaths
    List of files to run before running actual scans. Required e.g. if custom classes are used in the scanned files.

    .EXAMPLE
    Invoke-SCriptCop -Path "c:\PSCI"
    #>

    [OutputType([int])]
	Param(
		[Parameter(Mandatory=$true)]
		[string]
        $Path,

        [Parameter(Mandatory=$false)]
		[string[]]
        $ExcludeNames,

        [Parameter(Mandatory=$false)]
		[string[]]
        $PrerequisitesPaths
	)

	begin {
		$global:ErrorActionPreference = "Stop"
		if ($PrerequisitesPaths) {
            foreach ($prereq in $PrerequisitesPaths) {
                Write-Output -InputObject "Including '$prereq'"
                . $prereq
            }
        }
        Write-ProgressExternal -Message 'Running ScriptCop' -ErrorMessage 'ScriptCop invocation error'
    }
	process {
		Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "ScriptCop\ScriptCop.psm1") -Force;
        
        $testResults = New-Object System.Collections.ArrayList
        if ($ExcludeNames) {
            $excludeRegex = '.*\\(' + ($ExcludeNames -join "|") + ')\\.*'
        }
        
		Get-ChildItem -Path $Path -Recurse -Filter "*.ps*1" -Exclude "deployConfiguration.ps1", "*.Tests.ps1" | Where-Object { !$excludeRegex -or $_.FullName -inotmatch $excludeRegex } | ForEach-Object { 
               $content = [IO.File]::ReadAllText($_.FullName)
               $cmd = "Test-Command -ScriptBlock { $content }" 
               $fileName = $_.Name
               Write-Output -InputObject "Testing '$($_.Name)'"
               try { 
                  Invoke-Expression -Command $cmd | Foreach-Object { [void]($testResults.Add($_)) }
               } catch {
                    $err = $_
                    Write-Output -InputObject "FAILED: $($err.Exception)"
                    $result = New-Object PSObject -Property @{
                        Rule = "EXCEPTION"
                        Problem = $err.Exception
                        ItemWithProblem = $fileName
                    }

                    $testResults.Add($result)
               }
        }
         
        Remove-Item -LiteralPath 'ScriptCop.txt' -Force -ErrorAction SilentlyContinue
		$testResults | ForEach-Object { Tee-Object -FilePath 'ScriptCop.txt' -InputObject "$($_.ItemWithProblem) - $($_.Rule) - $($_.Problem))" -Append  }
        $numErrors = $testResults.Count
	}
	end {
        Write-ProgressExternal -Message '' -ErrorMessage ''
        if ($numErrors -gt 0) {
            Write-ProgressExternal -Message "ScriptCop errors ($numErrors)" -MessageType Problem
        }
		exit $numErrors
	}
}