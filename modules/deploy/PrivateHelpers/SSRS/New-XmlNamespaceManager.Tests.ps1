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

Import-Module -Name "$PSScriptRoot\..\..\..\..\DoIt.psd1"

Describe -Tag "DoIt.unit" "New-XmlNamespaceManager" {
    InModuleScope DoIt.deploy {
        Context "when used with existing namespaces" { 
            It "should define default namespace" {
                $doc = [xml] @"
<?xml version="1.0" encoding="windows-1250"?>
<Report xmlns:rd="http://schemas.microsoft.com/SQLServer/reporting/reportdesigner" xmlns:cl="http://schemas.microsoft.com/sqlserver/reporting/2010/01/componentdefinition" xmlns="http://schemas.microsoft.com/sqlserver/reporting/2010/01/reportdefinition">
</Report>
"@

                $nsmgr = New-XmlNamespaceManager -XmlDocument $doc -DefaultNamespacePrefix 'd'

                $nsmgr.HasNamespace('d') | Should Be $true
            }
        }
    }
}