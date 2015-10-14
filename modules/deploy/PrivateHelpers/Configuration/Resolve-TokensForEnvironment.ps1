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

function Resolve-TokensForEnvironment {
    
    <#
    .SYNOPSIS
    Helper function to resolve given tokens hashtable.

    .PARAMETER Tokens
    Tokens hashtable.

    .PARAMETER ResolvedTokens
    Resolved tokens (result hashtable)

    .PARAMETER TokensOverride
    A list of tokens to override. Token defined in the configuration files will be overrided with values specified in this array 
    (tokens will be matched by name, ignoring categories).

    .EXAMPLE
    Resolve-TokensForEnvironment -Tokens $AllEnvironments[$env].Tokens -ResolvedTokens $resolvedTokens -TokensOverride $TokensOverride
    #>

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]
        $Tokens,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $ResolvedTokens,

        [Parameter(Mandatory=$false)]
        [hashtable]
        $TokensOverride
    )

    foreach ($category in $tokens.Keys) {
        if (!$resolvedTokens.ContainsKey($category)) {
            $ResolvedTokens[$category] = @{}
        }
        foreach ($token in $tokens[$category].GetEnumerator()) {
            $overridden = $false
            if ($TokensOverride) {
                $compositeKey = "$category.$($token.Key)"
                if ($TokensOverride.ContainsKey($compositeKey)) {
                    $val = $TokensOverride[$compositeKey]
                    $overridden = $true
                } elseif ($TokensOverride.ContainsKey($token.Key)) {
                    $val = $TokensOverride[$token.Key]
                    $overridden = $true
                }
                if ($val -ieq '$true') {
                    $val = $true
                } elseif ($val -ieq '$false') {
                    $val = $false
                }
            }
            if (!$overridden) {
                $val = $token.Value
            }
            $ResolvedTokens[$category][$token.Key] = $val
        }      
    }
}