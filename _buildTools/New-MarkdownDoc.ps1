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

function New-MarkdownDoc {
    <#
    .SYNOPSIS
    Generates markdown documentation for each public function from given module.

    .PARAMETER ModuleName
    Module to scan.

    .PARAMETER OutputPath
    Base output path.

    .EXAMPLE
    New-MarkdownDoc -ModuleName 'PSCI.build' -OutputPath '..\PSCI.wiki'
    #>

    [CmdletBinding()]
	[OutputType([void])]
	param(
		[Parameter(Mandatory=$true)]
		[string]
        $ModuleName,

        [Parameter(Mandatory=$true)]
		[string]
        $OutputPath
	)

    $outputBasePath = Join-Path $OutputPath -ChildPath "api\$ModuleName"
    if ((Test-Path -Path $outputBasePath)) { 
        Write-Log -Info "Deleting directory '$outputBasePath'"
        Remove-Item -Path $outputBasePath -Recurse -Force
    }
    [void](New-Item -Path $outputBasePath -ItemType Directory -Force)

    $outputIndexString = New-Object -TypeName System.Text.StringBuilder
    $modulePath = Get-PSCIModulePath -ModuleName $ModuleName
    $readmePath = Join-Path -Path $modulePath -ChildPath 'readme.txt'

    [void]($outputIndexString.Append("## Module $ModuleName`r`n"))
    if ((Test-Path -Path $readmePath)) {
        $readmeContents = Get-Content -Path $readmePath -ReadCount 0 | Out-String
        [void]($outputIndexString.Append($readmeContents))
    }

    $arrParameterProperties = @(
        'DefaultValue',
        'PipelineInput',
        'Required'
    )

    $allPs1Files = Get-ChildItem -Path $modulePath -Include "*.ps1" -Recurse | Select-Object -ExpandProperty FullName

    $currentRelativeLocation = ''
    foreach ($ps1File in $allPs1Files) {
        $funcName = (Split-Path -Path $ps1File -Leaf).Replace('.ps1', '')
        $cmd = Get-Command -Module $ModuleName -Name $funcName -ErrorAction SilentlyContinue
        if (!$cmd) {
            continue
        }

        Write-Log -Info "Generating markdown for $funcName"

        $funcRelativeLocation = (Split-Path -Path $ps1File -Parent).Replace("$modulePath\", '')
        if ($funcRelativeLocation -ne $currentRelativeLocation) {
            [void]($outputIndexString.Append("`r`n### $funcRelativeLocation`r`n"))    
            $currentRelativeLocation = $funcRelativeLocation
        }

        $help = Get-Help -Name $funcName -ErrorAction SilentlyContinue
        if (!$help -or $help -is [string]) {
            throw "Function '$funcName' does not have help."
        }
        
        $outputString = New-Object -TypeName System.Text.StringBuilder
        [void]($outputIndexString.Append("* [[$funcName]]"))
        [void]($outputString.Append("## $funcName`r`n"))
        if ($help.Synopsis) {
            [void]($outputIndexString.Append(" - $($help.Synopsis)`r`n"))
            [void]($outputString.Append("### Synopsis`r`n"))
            [void]($outputString.Append("$($help.Synopsis)`r`n"))
        } else {
            [void]($outputIndexString.Append("`r`n"))
        }

        if ($help.Syntax) {
            [void]($outputString.Append("### Syntax`r`n"))
            $syntax = ($help.Syntax | Out-String).Trim()
            [void]($outputString.Append("``````PowerShell`r`n$syntax`r`n```````r`n"))
        }

        if ($help.Description) {
            [void]($outputString.Append("### Description`r`n"))
            [void]($outputString.Append("$($help.Description.Text)`r`n"))
        }

        if ($help.Parameters) {
            [void]($outputString.Append("### Parameters`r`n"))
            foreach ($item in $help.Parameters.Parameter) {
                [void]($outputString.Append("#### -$($item.Name)\<$($item.Type.Name)\>`r`n"))
                [void]($outputString.Append($($item.Description.Text)))
                [void]($outputString.Append("`r`n"))

                foreach ($arrParamProperty in $arrParameterProperties){
                    if ($item.$arrParamProperty){
                         [void]($outputString.Append("- **$arrParamProperty**: $($item.$arrParamProperty)`r`n"))
                    }
                }
                [void]($outputString.Append("`r`n"))
            }
        }

        if ($help.Examples) {
            [void]($outputString.Append("### Examples`r`n"))
            foreach ($item in $help.Examples.Example) {
                $example = $item.title.Replace("--------------------------","").Replace("EXAMPLE","Example")
                [void]($outputString.Append("`r`n#### $example`r`n"))
                if ($item.Code) {
                    [void]($outputString.Append("``````PowerShell`r`n"))
                    [void]($outputString.Append("$($item.Code)`r`n```````r`n"))
                }
                if ($item.Remarks) {
                    foreach ($remark in $item.Remarks.Text) { 
                        if ($remark -and $remark.Trim()) { 
                            [void]($outputString.Append("$($remark.Trim())`r`n"))
                        }
                    }
                }
            }
        }

        $outputFilePath = Join-Path -Path $outputBasePath -ChildPath "${funcName}.md"
        $outputString.ToString() | Out-File -FilePath $outputFilePath  
    }

    $outputIndexPath = Join-Path -Path $outputBasePath -ChildPath "$ModuleName.md"
    $outputIndexString.ToString() | Out-File -FilePath $OutputIndexPath
}

