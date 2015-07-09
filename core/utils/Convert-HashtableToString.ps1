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

function Convert-HashtableToString {

    <#
    .SYNOPSIS
    Converts hashtable or any other dictionary to a serializable string. It also supports nested hashtables.

    .PARAMETER Hashtable
    Hashtable to convert.

    .EXAMPLE
    Convert-HashtableToString -Hashtable @{'key'='value'}
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true)]
        [System.Collections.IDictionary]
        $Hashtable
    )

    $sb = New-Object -TypeName System.Text.StringBuilder
    [void]($sb.Append('@{'))
    foreach ($entry in $Hashtable.GetEnumerator()) {

        $key = $entry.Key -replace "'","''"
        $key = "'$key'"
        $value = $entry.Value
        if ($value -is [System.Collections.IDictionary]) {
            $value = Convert-HashtableToString -Hashtable $value
        } else {
            $value = $value -replace "'","''"
            $value = "'$value'"
        }
        
        [void]($sb.Append("$key=$value; "))
    }
    [void]($sb.Append('}'))

    return $sb.ToString()
}