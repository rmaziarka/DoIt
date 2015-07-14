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

function Get-CsvData {

    <#
    .SYNOPSIS
    Reads CSV file using specific encoding and running optional Validation and Transformation rules.

    .DESCRIPTION
    After CSV file is read, Validation phase is run, that is for each row $CsvValidationRules scriptblock is invoked, which returns array of string: 
        - if the array is empty it is assumed the row is valid.
        - if the array is non-empty, it is assumed the row is invalid and the strings will be displayed after the Validation phase.
    Then, Transformation phase is run, that is for each row $CsvTransformationRules scriptblock is invoked, which returns a hashtable that is then
    passed as a final result.       
    
    .PARAMETER CsvPath
    Path to input CSV file.

    .PARAMETER CsvDelimiter
    CSV delimiter in input CSV file.

    .PARAMETER CustomEncoding
    If specified, CSV file will be first reencoded to UTF-8 (to a temporary file).

    .PARAMETER CsvValidationRules
    A scriptblock invoked for each row that accepts [PSCustomObject]$CsvRow and [int]$CsvRowNum. It returns array of string.

    .PARAMETER CsvTransformRules
    A scriptblock ivoked for each row that accepts [PSCustomObject]$CsvRow and [int]$CsvRowNum. It returns hashtable.
     
    .EXAMPLE
    function Get-ValidationRules {

        [CmdletBinding()]
        [OutputType([string[]])]
        param(
            [Parameter(Mandatory = $true)]
            [PSCustomObject]
            $CsvRow,

            [Parameter(Mandatory = $true)]
            [int]
            $CsvRowNum
        )

        $errors = @()
        $errors += Test-ColumnIsValid -Row $CsvRow -ColumnName 'Login' -NonEmpty -NotContains '?', ' '
        $errors += Test-ColumnIsValid -Row $CsvRow -ColumnName 'Name' -NonEmpty -NotContains '?'
        $errors += Test-ColumnIsValid -Row $CsvRow -ColumnName 'First Name' -NonEmpty -NotContains '?', ' '
        $errors += Test-ColumnIsValid -Row $CsvRow -ColumnName 'Last Name' -NonEmpty -NotContains '?'
    
        return $errors
    }

    function Get-TransformRules {

        [CmdletBinding()]
        [OutputType([hashtable])]
        param(
            [Parameter(Mandatory = $true)]
            [PSCustomObject]
            $CsvRow,

            [Parameter(Mandatory = $true)]
            [int]
            $CsvRowNum
        )

        $result = @{
            Name = Remove-DiacriticChars -String (($CsvRow.'Name'))
            FirstName = Remove-DiacriticChars -String (($CsvRow.'First Name'))
            LastName = Remove-DiacriticChars -String (($CsvRow.'Last Name'))
            Login = $CsvRow.Login 
        }

        return $result
    }

    $csvParams = @{
        CsvPath = 'test.csv'
        CsvDelimiter = ';'
        CsvValidationRules = (Get-Command -Name Get-ValidationRules).ScriptBlock
        CsvTransformRules = (Get-Command -Name Get-TransformRules).ScriptBlock
        CustomEncoding = 'Windows-1250'
    }
    $employeeData = Get-CsvData @csvParams
    #>
    [CmdletBinding()]
    [OutputType([hashtable[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $CsvPath,

        [Parameter(Mandatory = $true)]
        [string]
        $CsvDelimiter,

        [Parameter(Mandatory = $false)]
        [string]
        $CustomEncoding,

        [Parameter(Mandatory = $false)]
        [scriptblock]
        $CsvValidationRules,

        [Parameter(Mandatory = $false)]
        [scriptblock]
        $CsvTransformRules
    )

    if (!(Test-Path -LiteralPath $CsvPath)) {
        throw "Csv input file '$CsvPath' does not exist at $((Get-Location).Path)."
    }

    $tempFileName = ''
    try { 
        
        if ($CustomEncoding) {
            $tempFileName = [System.IO.Path]::GetTempFileName()
            Convert-FileEncoding -Path $CsvPath -OutputPath $tempFileName -InputEncoding $CustomEncoding -OutputEncoding 'UTF-8'
            $csvFileToRead = $tempFileName
        } else {
            $csvFileToRead = $CsvPath
        }

        Write-Log -Info "Reading file '$csvFileToRead' using delimiter '$CsvDelimiter'"
        $inputData = Import-Csv -Path $csvFileToRead -Delimiter $CsvDelimiter -Encoding UTF8
        if (!$inputData) {
            throw "There is no data to import. Please check file '$CsvPath'."
        }
        Write-Log -Info "Read $($inputData.Length) rows."

        foreach ($row in $inputData) { 
            foreach ($prop in $row.PSObject.Properties.Name) {
                $row.$prop = $row.$prop.Trim()
            }
        }
    
        # Run Validation Rules
        if ($CsvValidationRules) {
            $errorArray = New-Object -TypeName System.Collections.ArrayList
            $rowNum = 2

            Write-Log -Info 'Validating CSV data.'
            foreach ($row in $inputData) {

                try { 
                    $errors = Invoke-Command -ScriptBlock $CsvValidationRules -ArgumentList $row, $rowNum
                } catch {
                    Write-ErrorRecord -ErrorRecord $_
                }
                foreach ($err in $errors) {
                    [void]($errorArray.Add("Validation error in row ${rowNum}: $err"))
                }
                $rowNum++
            }
    
            if ($errorArray) {
                $msg = "`r`n" + ($errorArray -join "`r`n")
                Write-Log -Error $msg
                Write-Log -Critical "Input CSV file has not passed validation rules. Please fix the file and try again."
            }
        }

        $added = 0
        $ignored = 0
        # Run Transformation Rules
        if ($CsvTransformRules) {
            $resultArray = New-Object -TypeName System.Collections.ArrayList
            $rowNum = 2

            Write-Log -Info 'Transforming CSV data.'
            foreach ($row in $inputData) {
                try { 
                    $resultRow = Invoke-Command -ScriptBlock $CsvTransformRules -ArgumentList $row, $rowNum
                } catch {
                    Write-ErrorRecord -ErrorRecord $_
                }
                if ($resultRow) { 
                    [void]($resultArray.Add($resultRow))
                    $added++
                } else {
                    $ignored++
                }
            }
            Write-Log -Info "CSV file read successfully ($added rows returned, $ignored rows ignored)."
            return $resultArray
        } else {
            return $inputData
        }
    } finally {
        if ($tempFileName -and (Test-Path -Path $tempFileName)) {
            Remove-Item -Path $tempFileName -Force
        }
    }

    
    
}