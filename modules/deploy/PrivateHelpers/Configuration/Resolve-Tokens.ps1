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

function Resolve-Tokens {
    <#
    .SYNOPSIS
    Resolves tokens for given Environment and Node.

    .DESCRIPTION
    It reads global Environments hashtable, e.g.:
    $Environments = @{ 
        Default = @{
            Tokens = @{
               Category1 = @{
                    LDAPServer = '192.168.0.1'
                    ADConnectionString = 'LDAP://${LDAPServer}:389/OU=User'
                    User = 'User'
                    Pass = 'Pass'
               }
               Category2 = @{
                    DatabaseConnectionString = 'Server=${Node};Database=YourDB;Integrated Security=True;MultipleActiveResultSets=True'
                    Credentials = $null
               }
            }
        }
        Dev = @{
            Tokens = @{
                Category2 = @{
                    Credentials = { ConvertTo-PSCredential -User "$($Tokens.Category1.User)" -Password $Tokens.Category1.Password }
               }
            }
        }
    }

    And creates following structure (for 'Dev' environment, Node 'LOCALHOST'):
    $Tokens = @{ 
        Category1 = @{
            LDAPServer = '192.168.0.1'
            ADConnectionString = 'LDAP://192.168.0.1:389/OU=User'
            User = 'User'
            Pass = 'Pass'
        }
        Category2 = @{
            DatabaseConnectionString = 'Server=LOCALHOST;Database=YourDB;Integrated Security=True;MultipleActiveResultSets=True'
            Credentials = [PSCredential object with user = 'User', pass = 'Pass']
        }
        All = @{ <all tokens from every category> }
        Common = @{ 
            Node = 'LOCALHOST'; 
            Environment = 'Dev'
        }
    }

    Apart from resolving Tokens based on Environment/Node, it additionally does the following:
    1) Adds 'All' category containing all tokens from every category (a flat hashtable of tokens)
    2) Adds 'Common' category containing Node name and Environment.
    3) Resolves all occurrences of '${tokenCat.tokenName}' or '${tokenName}' in token values which are strings (see '${LDAPServer}' in the example above).
       Note categories cannot be used in the string (e.g. '${Category1.LDAPServer}' will not work).
       Note that additional tokens named 'Node' and 'Environment' are available for substitution (see point 2 and example above).
    4) Evaluates all script blocks in token values, making resolved $Tokens variable available (Credentials in the example above).

    .PARAMETER AllEnvironments
    Hashtable containing all environment definitions.

    .PARAMETER Environment
    Environment name - will be used for selecting proper sub-hashtable from $AllEnvironments.

    .PARAMETER Node
    Node name - will be used for selecting proper sub-hashtable from $AllEnvironments and to resolve '${Node}' tokens.

    .PARAMETER TokensOverride
    A list of tokens to override. Token defined in the configuration files will be overrided with values specified in this array 
    (tokens will be matched by name, ignoring categories).

    .EXAMPLE
    $resolvedTokens = Resolve-Tokens -AllEnvironments $AllEnvironments -Environment $Environment -Node $Node
    #>

    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]
        $AllEnvironments,

        [Parameter(Mandatory=$true)]
        [string]
        $Environment,

        [Parameter(Mandatory=$false)]
        [string]
        $Node,

        [Parameter(Mandatory=$false)]
        [hashtable]
        $TokensOverride
    )

    $resolvedTokens = @{}

    $envHierarchy = Resolve-BasedOnHierarchy -AllElements $AllEnvironments -SelectedElement $Environment -ConfigElementName 'Environment'

    # get tokens from specific environments
    foreach ($env in $envHierarchy) {
        Resolve-TokensForEnvironment -Tokens $AllEnvironments[$env].Tokens -ResolvedTokens $resolvedTokens -TokensOverride $TokensOverride
        $tokensChildren = $AllEnvironments[$env].TokensChildren
        if ($tokensChildren.ContainsKey($node)) {
            Resolve-TokensForEnvironment -Tokens $tokensChildren[$node] -ResolvedTokens $resolvedTokens -TokensOverride $TokensOverride
        }
    }

    # add 'node' and 'environment'
    if (!$resolvedTokens.ContainsKey('Common')) {
        $resolvedTokens.Common = @{}
    }
    $resolvedTokens.Common.Node = $Node
    $resolvedTokens.Common.Environment = $Environment

    $resolveTokenFunction = { 
        param($TokenName, $TokenCategory, $TokenValue, $ResolvedTokens, $Node, $Environment, $ValidateExistence)    
        Resolve-Token -Name $TokenName -Value $TokenValue -Category $TokenCategory -ResolvedTokens $ResolvedTokens -ValidateExistence:$ValidateExistence
    }

    $resolveScriptedTokenFunction = { 
        param($TokenName, $TokenCategory, $TokenValue, $ResolvedTokens, $Node, $Environment, $ValidateExistence)
        Resolve-ScriptedToken -TokenName $TokenName -ScriptedToken $TokenValue -TokenCategory $TokenCategory -ResolvedTokens $ResolvedTokens -Node $Node -Environment $Environment
    }

    $params = @{
        ResolvedTokens = $resolvedTokens
        Environment = $Environment
        Node = $Node
    }

    # 1st pass resolve each string token (apart from ones with [scriptblock] value).
    Resolve-TokensPass @params -ResolveFunction $resolveTokenFunction -ValidateExistence:$false

    # 2st pass - resolve each scriptblock token
    Resolve-TokensPass @params -ResolveFunction $resolveScriptedTokenFunction -ValidateExistence:$false

    # 3st pass - resolve each string token again
    Resolve-TokensPass @params -ResolveFunction $resolveTokenFunction -ValidateExistence:$true

    # add 'All' category that contains flat hashtable of all tokens
    Add-AllTokensCategory -Tokens $resolvedTokens

    return $resolvedTokens
}

function Resolve-TokensPass {

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
        $resolvedTokens[$category].Keys | Foreach-Object { $tokensCatKeys += $_ }

        foreach ($tokenKey in $tokensCatKeys) {
            $tokenValue = $resolvedTokens[$category][$tokenKey]
            if (!$tokenValue) {
                continue
            }
            try { 
                if ($tokenValue -is [hashtable]) {
                    $newHashTable = @{}
                    foreach ($tokenValueEnumerator in $tokenValue.GetEnumerator()) {
                        $params = @{
                            TokenName = "${tokenKey}.$($tokenValueEnumerator.Key)"
                            TokenCategory = $category
                            TokenValue = $tokenValueEnumerator.Value
                            ResolvedTokens = $ResolvedTokens
                            Environment = $Environment
                            Node = $Node
                            ValidateExistence = $ValidateExistence
                        }
                        $newValue = & $ResolveFunction @params                   
                        $newHashTable[$tokenValueEnumerator.Key] = $newValue
                    }
                    $resolvedTokens[$category][$tokenKey] = $newHashTable
                } else {
                    $params = @{
                        TokenName = $tokenKey
                        TokenCategory = $category
                        TokenValue = $tokenValue
                        ResolvedTokens = $ResolvedTokens
                        Environment = $Environment
                        Node = $Node
                        ValidateExistence = $ValidateExistence
                    }
                    $newValue = & $ResolveFunction @params 
                    $resolvedTokens[$category][$tokenKey] = $newValue
                }
            } catch {
                throw ("Cannot evaluate token '$Environment / $category / $tokenKey'. Error message: {0} / token value: {{ {1} }}" -f $_.Exception.Message, $tokenValue)
            }
        }
    }
}


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

function Add-AllTokensCategory {
    
    <#
    .SYNOPSIS
    Helper function to add 'All' category containing all tokens without hierarchy.

    .PARAMETER Tokens
    Tokens hashtable.

    .EXAMPLE
    Add-AllTokensCategory -Tokens $Tokens
    #>

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]
        $Tokens
    )
    $keysEnum = @()
    foreach ($key in $Tokens.Keys) {
        # SuppressScriptCop - adding small arrays is ok
        $keysEnum += $key
    }

    $Tokens["All"] = @{}
    foreach ($category in $keysEnum) {
        foreach ($token in $Tokens[$category].GetEnumerator()) {
            $Tokens["All"][$token.Key] = $token.Value
        }      
    }
}