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

function Resolve-TokensSinglePass {

    <#
    .SYNOPSIS
    Helper function to run one pass of tokens resolve.

    .PARAMETER ResolvedTokens
    Resolved tokens (result hashtable)

    .PARAMETER ResolveFunction
    Scriptblock that will be invoked to resolve specific token value.

    .PARAMETER Environment
    Environment name - will be used for selecting proper sub-hashtable from $AllEnvironments.

    .PARAMETER Node
    Node name - will be used for selecting proper sub-hashtable from $AllEnvironments and to resolve '${Node}' tokens.

    .PARAMETER ValidateExistence
    Whether to validate existence of the referenced token.

    .EXAMPLE
    Resolve-TokensPass -ResolvedTokens $resolvedTokens -Environment $Environment -Node $Node -ResolveFunction $resolveTokenFunction -ValidateExistence:$false
    #>

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]
        $ResolvedTokens,

        [Parameter(Mandatory=$true)]
        [scriptblock]
        $ResolveFunction,

        [Parameter(Mandatory=$true)]
        [string]
        $Environment,

        [Parameter(Mandatory=$false)]
        [string]
        $Node,

        [Parameter(Mandatory=$false)]
        [switch]
        $ValidateExistence
    )

    foreach ($category in $resolvedTokens.Keys) {
        $tokensCatKeys = @()
        $ResolvedTokens[$category].Keys | Foreach-Object { $tokensCatKeys += $_ }

        foreach ($tokenKey in $tokensCatKeys) {
            $tokenValue = $resolvedTokens[$category][$tokenKey]
            if (!$tokenValue) {
                continue
            }
            
            $params = @{
                TokenName = $tokenKey
                TokenCategory = $category
                TokenValue = $tokenValue
                ResolvedTokens = $ResolvedTokens
                ResolveFunction = $ResolveFunction
                Environment = $Environment
                Node = $Node
                ValidateExistence = $ValidateExistence
            }
            $resolvedTokens[$category][$tokenKey] = Resolve-SingleTokenRecursively @params
        }
    }
}

function Resolve-SingleTokenRecursively {

    <#
    .SYNOPSIS
    Helper function to resolve single token recursively (if it's a hashtable).

    .PARAMETER TokenName
    Token name.

    .PARAMETER TokenCategory
    Token category.

    .PARAMETER TokenValue
    Token value.

    .PARAMETER ResolvedTokens
    Resolved tokens (result hashtable)

    .PARAMETER ResolveFunction
    Scriptblock that will be invoked to resolve specific token value.

    .PARAMETER Environment
    Environment name - will be used for selecting proper sub-hashtable from $AllEnvironments.

    .PARAMETER Node
    Node name - will be used for selecting proper sub-hashtable from $AllEnvironments and to resolve '${Node}' tokens.

    .PARAMETER ValidateExistence
    Whether to validate existence of the referenced token.

    .EXAMPLE
    Resolve-SingleTokenRecursively @params
    #>

    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        $TokenName,

        [Parameter(Mandatory=$true)]
        [object]
        $TokenCategory,

        [Parameter(Mandatory=$true)]
        [object]
        $TokenValue,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $ResolvedTokens,

        [Parameter(Mandatory=$true)]
        [scriptblock]
        $ResolveFunction,

        [Parameter(Mandatory=$true)]
        [string]
        $Environment,

        [Parameter(Mandatory=$false)]
        [string]
        $Node,

        [Parameter(Mandatory=$false)]
        [switch]
        $ValidateExistence
    )
    
    if ($TokenValue -is [hashtable]) {
        $newHashTable = @{}
        $recursionParams = @{
            TokenCategory = $TokenCategory
            ResolvedTokens = $ResolvedTokens
            ResolveFunction = $ResolveFunction
            Environment = $Environment
            Node = $Node
            ValidateExistence = $ValidateExistence
        }
        foreach ($tokenValueEnumerator in $tokenValue.GetEnumerator()) {
            $recursionParams.TokenName = "$TokenName.$($tokenValueEnumerator.Key)"
            $recursionParams.TokenValue = $tokenValueEnumerator.Value
            $newHashTable[$tokenValueEnumerator.Key] = Resolve-SingleTokenRecursively @recursionParams
        }
        return $newHashTable
    } else {
        $params = @{
            TokenName = $TokenName
            TokenCategory = $TokenCategory
            TokenValue = $TokenValue
            ResolvedTokens = $ResolvedTokens
            Environment = $Environment
            Node = $Node
            ValidateExistence = $ValidateExistence
        }
        try { 
            $newValue = & $ResolveFunction @params 
        } catch {
            throw ("Cannot evaluate token '$Environment / $TokenCategory / $TokenName'. Error message: {0} / token value: {{ {1} }}" -f $_.Exception.Message, $TokenValue)
        }
        return $newValue
    }   
}