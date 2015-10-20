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

function Test-ColumnIsValid {

    <#
    .SYNOPSIS
    Validates a column value in a single CSV row.

    .DESCRIPTION
    It is useful in Get-CsvData / Get-ValidationRules to validate columns read from CSV row.
    It returns empty array if the value is valid, or array of error messages if it's invalid.
    
    .PARAMETER Row
    CSV row (or any other PSCustomObject).

    .PARAMETER ColumnName
    Name of the column which will be validated.

    .PARAMETER NonEmpty
    If $true, it will be asserted the column value is not empty.

    .PARAMETER NotContains
    If specified, it will be asserted the column value does not contain any of the specified string.

    .PARAMETER ValidSet
    If specified, it will be asserted the column value is one of the specified string.

    .PARAMETER DateFormat
    If specified, it will be asserted the column value can be converted to a date using specified format.

    .EXAMPLE
    $errors += Test-ColumnIsValid -Row $CsvRow -ColumnName 'Login' -NonEmpty -NotContains '?', ' '
    $errors += Test-ColumnIsValid -Row $CsvRow -ColumnName 'Name' -NonEmpty -NotContains '?'
    $errors += Test-ColumnIsValid -Row $CsvRow -ColumnName 'StartDate' -DateFormat 'yyyy-MM-dd'
    $errors += Test-ColumnIsValid -Row $CsvRow -ColumnName 'Gender' -ValidSet '', 'F', 'M'
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $Row,

        [Parameter(Mandatory = $true)]
        [string]
        $ColumnName,

        [Parameter(Mandatory = $false)]
        [switch]
        $NonEmpty,

        [Parameter(Mandatory = $false)]
        [string[]]
        $NotContains,

        [Parameter(Mandatory = $false)]
        [string[]]
        $ValidSet,

        [Parameter(Mandatory = $false)]
        [string]
        $DateFormat
    )

    $errors = @()

    try {
        $value = $Row.$ColumnName
    } catch {
        $value = $null
    }

    if (!$value) {
        if ($NonEmpty) { 
            $errors += "$ColumnName is missing"
        }
        return $errors
    }
    if ($NotContains) {
        foreach ($illegalChar in $NotContains) {
            if ([char[]]$value -icontains $illegalChar) {
                $errors += "$ColumnName has invalid value ('$value') - contains illegal character: '$illegalChar'"
            }
        }
    }
    if ($ValidSet) {
        $ok = $false
        foreach ($validValue in $ValidSet) {
            if ($value -ieq $validValue) {
                $ok = $true
                break
            }
        }
        if (!$ok) {
            $errors += "$ColumnName has invalid value ('$value') - should be one of '{0}'." -f ($ValidSet -join "', ")
        }
    }
    if ($DateFormat) {
        $date = ConvertTo-Date -String $value -DateFormat $DateFormat
        if (!$date) {
            $errors += "$ColumnName has invalid value ('$value') - should be a date in format '$DateFormat'"
        }
    }
    return $errors
}
