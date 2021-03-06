function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.Boolean]
        $Enable
    )

    try
    {
        $instance = ScheduledTaskLogInstance
        $instance.IsEnabled = $Enable
        $instance.SaveChanges()
    }
    finally
    {
        $instance.Dispose() > $null
    }

}

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.Boolean]
        $Enable
    )

    try
    {
        $instance = ScheduledTaskLogInstance
    }
    finally
    {
        $instance
        $instance.Dispose() > $null
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.Boolean]
        $Enable
    )

    try
    {
        $instance = ScheduledTaskLogInstance
        $result = $instance.IsEnabled -eq $Enable
    }
    finally
    {
        $instance.Dispose() > $null
    }

    return $result
}

function ScheduledTaskLogInstance
{
    $logName = 'Microsoft-Windows-TaskScheduler/Operational'
    $instance = New-Object System.Diagnostics.Eventing.Reader.EventLogConfiguration $logName
    return $instance
}

Export-ModuleMember -Function *-TargetResource