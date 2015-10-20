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

Describe -Tag "PSCI.unit" "Convert-HashtableToString" {
    InModuleScope PSCI.core {

        Context "When invoked for flat ordered hashtable" {
            $hash = [ordered]@{ 'testStr' = 'testValue1'; 'testInt' = 3 }
            $result = Convert-HashtableToString -Hashtable $hash
            
            It "should return proper hashtable" {
                $result | Should Be "@{'testStr'='testValue1'; 'testInt'='3'; }"
            }

        }

        Context "When invoked for nested ordered hashtable" {
            $hash = [ordered]@{ 'testStr' = 'testValue1'; 'testNested' = [ordered]@{ 'nest1' = 'abc'; 'nest2' = [ordered]@{ 'nest21' = 'abc'; 'nest22' = 'def' } } }
            $result = Convert-HashtableToString -Hashtable $hash
            
            It "should return proper hashtable" {
                $result | Should Be "@{'testStr'='testValue1'; 'testNested'=@{'nest1'='abc'; 'nest2'=@{'nest21'='abc'; 'nest22'='def'; }; }; }"
            }

        }

        Context "When invoked for nested hashtable" {
            $hash = [ordered]@{ 'test1' = @{ 'test2' = 'abc' } }
            $result = Convert-HashtableToString -Hashtable $hash
            
            It "should return proper hashtable" {
                $result | Should Be "@{'test1'=@{'test2'='abc'; }; }"
            }

        }
    }
}