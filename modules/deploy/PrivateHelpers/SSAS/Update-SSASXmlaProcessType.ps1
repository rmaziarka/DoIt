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

function Update-SSASXmlaProcessType {
    <#
    .SYNOPSIS
    Replaces process type in the .xmla file with the one specified in $ProcessType parameter.

    .PARAMETER GeneratedXmlaFilePath
    Output file that will be created by this cmdlet.

    .PARAMETER DeploymentXmlaFilePath
    Input file that will be converted by this cmdlet.

    .PARAMETER ProcessType
    Name of the type of processing that will be applied during deployment.

    .PARAMETER Force
    If $true then $DeploymentXmlaFilePath will be overwritten

    .EXAMPLE
    Update-SSASXmlaProcessType -GeneratedXmlaFilePath $generatedXmlaFilePath -DeploymentXmlaFilePath $deploymentXmlaFilePath -ProcessType $ProcessType

    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $GeneratedXmlaFilePath,

        [Parameter(Mandatory=$true)]
        [string] 
        $DeploymentXmlaFilePath,

        [Parameter(Mandatory=$true)]
        [ValidateSet("ProcessDefault", "ProcessFull")]
        [string]
        $ProcessType = "ProcessFull",

        [Switch]
        $Force
    )

    $xmlaXdtTranformation = @"
<Batch Transaction="false" xmlns="http://schemas.microsoft.com/analysisservices/2003/engine" xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
  <Process>
    <Type xdt:Transform="Replace">$ProcessType</Type>
  </Process>
</Batch>
"@

    [void](Convert-XmlUsingXdt -Path $GeneratedXmlaFilePath -XdtXml $xmlaXdtTranformation -Destination $DeploymentXmlaFilePath -Force:$Force)
}