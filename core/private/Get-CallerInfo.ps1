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

function Get-CallerInfo() {
    <#
    .SYNOPSIS
    Gets information about caller. Helper function.

    .PARAMETER InvocationInfo
    Custom InvocationInfo object, if not defined Get-PSCallStack will be used.

    .PARAMETER StackLevel
    Stack level, only used if InvocationInfo is not defined.

    .EXAMPLE
    Get-CallerInfo
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
    [Parameter(Mandatory=$false)]
        [object]
        $InvocationInfo,

        [Parameter(Mandatory=$false)]
        [int]
        $StackLevel = 2
    )

    if (!$InvocationInfo) { 
        $callerInfo = (Get-PSCallStack)[$StackLevel]
        $callerCommandName = $callerInfo.InvocationInfo.MyCommand.Name
    } else {
        $callerInfo = $InvocationInfo
        $callerCommandName = $InvocationInfo.MyCommand.Name
    }
    
    if ($callerInfo.ScriptName) {
        $callerScriptName = Split-Path -Leaf $callerInfo.ScriptName
    }
    $callerLineNumber = $callerInfo.ScriptLineNumber
    return "$callerScriptName/$callerCommandName/$callerLineNumber"
}