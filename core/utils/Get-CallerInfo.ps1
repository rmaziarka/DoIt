function Get-CallerInfo() {
    <#
    .SYNOPSIS
    Gets information about caller. Helper function.

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