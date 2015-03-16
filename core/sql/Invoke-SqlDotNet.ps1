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

function Invoke-SqlDotNet {
    <# 
    .SYNOPSIS 
    Runs a T-SQL script using .NET SqlCommand. 
    
    .DESCRIPTION 
    Useful especially when neither SMO nor sqlcmd are available.
    
    .PARAMETER ConnectionStringBuilder
    SqlConnectionStringBuilder object.
    
    .PARAMETER Query
    Sql query to run.
        
    .PARAMETER IgnoreErrors
    If set ignore errors when sqlcmd.exe is running.
    
    .PARAMETER QueryTimeoutInSeconds
    Query timeout.

    .PARAMETER ConnectTimeoutInSeconds
    Connect timeout.

    .PARAMETER Mode
    Determines whether to use ExecuteNonQuery or ExecuteReader method.
    
    .PARAMETER SqlCmdVariables
    Hashtable containing sqlcmd variables.

    .PARAMETER Credential
    Credential to impersonate in Integrated Security mode.

    .EXAMPLE
    Invoke-SqlDotNet -ConnectionString $connectionString -Sql $Query -SqlCmdVariables $param
    #> 

    [CmdletBinding()] 
    [OutputType([object])]
    param( 
        [Parameter(Mandatory=$true)] 
        [object]
        $ConnectionStringBuilder, 
    
        [Parameter(Mandatory=$false)] 
        [string]
        $Query,
        
        [Parameter(Mandatory=$false)] 
        [bool]
        $IgnoreErrors,
    
        [Parameter(Mandatory=$true)] 
        [int]
        $QueryTimeoutInSeconds,

        [Parameter(Mandatory=$true)] 
        [int]
        $ConnectTimeoutInSeconds,

        [Parameter(Mandatory=$false)]
        [ValidateSet($null, 'NonQuery', 'Scalar', 'Dataset')]
        [string]
        $Mode = 'Dataset',
    
        [Parameter(Mandatory=$false)] 
        [hashtable]
        $SqlCmdVariables,

        [Parameter(Mandatory=$false)]
        [PSCredential] 
        $Credential
    ) 

    #TODO: handle $Credential

    # Replace SqlCmdVariables in $Query
    if ($SqlCmdVariables) {
        foreach ($var in $SqlCmdVariables.GetEnumerator()) {
            $regex = '\$\({0}\)' -f $var.Key
            $Query = [System.Text.RegularExpressions.Regex]::Replace($Query, $regex, $var.Value, `
                        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        }
    }

    # Split queries per each 'GO' instance - see http://stackoverflow.com/questions/18596876/go-statements-blowing-up-sql-execution-in-net/18597052#18597052
    $queriesSplit = [System.Text.RegularExpressions.Regex]::Split($Query, '^\s*GO\s* ($ | \-\- .*$)', `
        [System.Text.RegularExpressions.RegexOptions]::Multiline -bor `
        [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace -bor `
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    $queriesSplit = $queriesSplit | Where-Object { ![System.String]::IsNullOrWhiteSpace($_) }

    $ConnectionStringBuilder.set_ConnectTimeout($ConnectTimeoutInSeconds)

    foreach ($q in $queriesSplit) { 
        try { 
            $connection = New-Object -TypeName System.Data.SqlClient.SQLConnection -ArgumentList ($ConnectionStringBuilder.ToString())
            $connection.FireInfoMessageEventOnUserErrors = $true
            $errorOccurred = @{ Error = $false }
            $infoEventHandler = [System.Data.SqlClient.SqlInfoMessageEventHandler] { 
                foreach ($err in $_.Errors) { 
                    if ($err.Class -le 10) { 
                        Write-Log -Info $err.Message
                    } else { 
                        Write-Log -Error $err.Message
                        if (!$IgnoreErrors) {
                            $errorOccurred.Error = $true
                        }
                    }
                }
                
            } 
            $connection.add_InfoMessage($infoEventHandler)
            $connection.Open()

            $command = New-Object -TypeName System.Data.SqlClient.SqlCommand -ArgumentList $q, $connection
            $command.CommandTimeout = $QueryTimeoutInSeconds

            if ($Mode -eq 'Dataset') { 
                $dataset = New-Object -TypeName System.Data.DataSet 
                $dataAdapter = New-Object -TypeName System.Data.SqlClient.SqlDataAdapter -ArgumentList $command
            
                [void]$dataAdapter.fill($dataset) 

                $dataset
            } elseif ($Mode -eq 'NonQuery') {
                [void]($command.ExecuteNonQuery())
            } elseif ($Mode -eq 'Scalar') {
                $command.ExecuteScalar()
            } else {
                Write-Log -Critical "Unsupported mode: ${Mode}."
            }

            if ($errorOccurred.Error) {
                Write-Log -Critical "SQL error(s) occurred."
            }
    
            $connection.Close();
        } finally {
            if ($connection) {
                $connection.Dispose();
            }
        }
    }
    
}