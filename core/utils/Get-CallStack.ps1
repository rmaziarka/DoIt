function Get-CallStack() {
    <#
    .SYNOPSIS
    Gets call stack. Helper function.

    .EXAMPLE
    Get-CallStack
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param()

    $psStack = Get-PSCallStack
    if ($psStack.Length -lt 3) {
        return "No stack trace."
    }
    $msg = ""
    for ($i = 2; $i -lt $psStack.Length; $i++) {
        $msg += ("Stack trace {0}: location={1}, command={2}, arguments={3}`r`n " -f ($i-1), $psStack[$i].Location, $psStack[$i].Command, $psStack[$i].Arguments)
    }
    return $msg
}