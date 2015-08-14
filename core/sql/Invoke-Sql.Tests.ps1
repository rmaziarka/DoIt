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

Import-Module -Name "$PSScriptRoot\..\..\PSCI.psd1" -Force

Describe -Tag "PSCI.unit" "Invoke-Sql" {
    InModuleScope PSCI.core {
        Mock Write-Log { 
            if ($Critical) {
                throw $Message
            } else {
                Write-Host $Message
            }
        }

        Mock Start-ExternalProcess -MockWith { $Output.Value = "command_executed" }
        
            
        Context "When Invoke-Sql Is called with mode sqlcmd" {
            Mock Test-Path -MockWith { if ($LiteralPath -match 'sqlcmd|Binn') { return $true } }
            $connectionString = "data source=localhost;integrated security=True"
            $sql = "SELECT * FROM Categories"
            $param = @{"dummy"="param"; "anotherdummy"="parameter"}

            It "should return command_executed result when all parameters are given" {
                Invoke-Sql -ConnectionString $connectionString -Query $sql -QueryTimeoutInSeconds 65030 -SqlCmdVariables $param -Mode sqlcmd | Should Be "command_executed"
            }

            It "should return command_executed result when all mandatory parameters are given" {
                Invoke-Sql -ConnectionString $connectionString -Query $sql -Mode sqlcmd | Should Be "command_executed"
            }

        }
        <# These are integration tests #>
        <#
        Context "When Invoke-Sql Is called with mode .net" {
            $connectionString = "data source=localhost;integrated security=True"

            It "should fail when query fails and IgnoreErrors = $false" {
                try { 
                    $fail = $false
                    Invoke-Sql -ConnectionString $connectionString -Query 'select * from Dummytable'
                    $fail = $true
                } catch {
                }
                $fail | should be $false
                
            } 

            It "should not fail when query fails and IgnoreErrors = $true" {
                Invoke-Sql -ConnectionString $connectionString -Query 'select * from Dummytable' -IgnoreErrors $true
            } 

            It "should not fail when query prints output" {
                Invoke-Sql -ConnectionString $connectionString -Query "print 'test'"                
            } 

            It "should return rows" {
                $result = Invoke-Sql -ConnectionString $connectionString -Query "select * from ObjPSCITest.dbo.changelog`nselect * from ObjPSCITest.dbo.changelog"
                $result.Count | Should be 1
                $result.Tables.Count | Should be 2
            }

            It "should return rows when InputFile is specified" {
                Set-Content -Path 'input.txt' -Value 'select * from ObjPSCITest.dbo.changelog' -Force
                $result = Invoke-Sql -ConnectionString $connectionString -InputFile 'input.txt'
                $result.Count | Should be 1
                $result.Tables.Count | Should be 1
            }

            It "should run multiple commands when they are separated with GO" {
                $result = Invoke-Sql -ConnectionString $connectionString -Query "select * from ObjPSCITest.dbo.changelog`nGO`nselect * from ObjPSCITest.dbo.changelog"
                $result.Count | should be 2
                $result[0].Tables.Count | Should be 1
                $result[1].Tables.Count | Should be 1
            }

            It "should substitute sqlcmd variables" {
                $result = Invoke-Sql -ConnectionString $connectionString -Query "select * from `$(param).dbo.changelog" -SqlCmdVariables @{ 'param' = 'ObjPSCITest' }
                $result.Count | Should be 1
                $result.Tables.Count | Should be 1
            }

        }
        #>
        
    }
}

 