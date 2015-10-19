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

configuration PSCIScheduledTask {

    <#
    .SYNOPSIS
    Ensures specific Scheduled Tasks are configured in Task Scheduler.

    .DESCRIPTION
    It uses following common tokens:
    - **TaskName** - (Mandatory) Scheduled Task name
    - **PowershellCommandToRun** - powershell command to run (puts powershell.exe to Execute and command to Argument)
    - **Execute** - path to executable to run
    - **Argument** - argument for executable to run
    - **WorkingDirectory** - working directory
    - **Credential** - credential under which the Scheduled Task will run (if not specified, SYSTEM will be used)
    - **RunLevel** - Highest (administrator - default) or Limited
    - **Compatibility** - At, V1, Vista, Win7 or Win8 (default)
    - **Description** - description of the Scheduled Task
    - **TaskPath** - path where the task will be created in Scheduled Task tree. 

    And following tokens for settings the schedule:
    - **ScheduledAt** - first time when the task should run (datetime)
    - **Daily** - whether to run it daily (true/false)

    Or:
    - **ScheduledAt** - first time when the task should run (datetime)
    - **ScheduledTimeSpanDay** - run it every n days
    - **ScheduledTimeSpanHour** - run it every n hours
    - **ScheduledTimeSpanMin** - run it every n minutes
    
    See [https://github.com/guitarrapc/DSCResources/tree/master/Custom/GraniResource/DSCResources/Grani_ScheduleTask] for description of DSC resource used in this step.

    .EXAMPLE
    ```
    Import-Module "$PSScriptRoot\..\PSCI\PSCI.psd1" -Force

    Environment Local { 
        ServerConnection WebServer -Nodes localhost
        ServerRole Web -Steps 'PSCIScheduledTask' -ServerConnection WebServer

        Tokens Web @{
            ScheduledTasks = @{
                TaskName = 'MyTask'
                Credential = { ConvertTo-PSCredential -User $($Tokens.Credentials.ScheduledTaskUser) -Password $Tokens.Credentials.ScheduledTaskPassword }
                PowershellCommandToRun = @(
                    'Set-Content -Path "c:\test.txt" -Value "test" -Force',
                    'Write-Host "test"'
                    ) -join ' '
                ScheduledAt = [datetime]'2015-08-25 20:00:00'
                ScheduledTimeSpanDay = 0
                ScheduledTimeSpanHour = 0
                ScheduledTimeSpanMin = 15
            }
        }
    }

    Install-DscResources -ModuleNames GraniResource

    Start-Deployment -Environment Local -NoConfigFiles
    ```
    Installs specified scheduled task.

    #>

    Import-DscResource -ModuleName GraniResource

    Node $AllNodes.NodeName {

        $scheduledTasks = Get-TokenValue -Name 'ScheduledTasks'

        if (!$scheduledTasks) {
            Write-Log -Info "No scheduled tasks to deploy"
            return
        }

        foreach ($task in $scheduledTasks) {
            if ($task -isnot [hashtable]) {
                throw "ScheduledTasks token must be a hashtable or array of hashtables."
            }

            if ($task.PowershellCommandToRun) {
                $task.Execute = 'powershell.exe'
                $task.Argument = '-Command "{0}"' -f $task.PowershellCommandToRun
            }

            if ($task.ScheduledTimeSpanDay -or $task.ScheduledTimeSpanHour -or $task.ScheduledTimeSpanMin) { 
                cScheduleTask "TaskSchedule_$taskName" {
                    Ensure = 'Present'
                    TaskName = $task.TaskName
                    TaskPath = if ($task.TaskPath) { $task.TaskPath } else { '\' }
                    Description = $task.Description
                    Execute = $task.Execute
                    Argument = $task.Argument
                    WorkingDirectory = $task.WorkingDirectory
                    Credential = $task.Credential
                    RunLevel = if ($task.RunLevel) { $task.RunLevel } else { 'Highest' }
                    Compatibility = if ($task.Compatibility) { $task.Compatibility } else { 'Win8' }
                    ScheduledAt = $task.ScheduledAt
                    ScheduledTimeSpanDay = $task.ScheduledTimeSpanDay
                    ScheduledTimeSpanHour = $task.ScheduledTimeSpanHour
                    ScheduledTimeSpanMin = $task.ScheduledTimeSpanMin
                    ScheduledDurationDay = 0
                    ScheduledDurationHour = 0
                    ScheduledDurationMin = 0
                    Disable = $false
                    Hidden = $false               

                }
            } else {
                cScheduleTask "TaskSchedule_$taskName" {
                    Ensure = 'Present'
                    TaskName = $task.TaskName
                    TaskPath = if ($task.TaskPath) { $task.TaskPath } else { '\' }
                    Description = $task.Description
                    Execute = $task.Execute
                    Argument = $task.Argument
                    WorkingDirectory = $task.WorkingDirectory
                    Credential = $task.Credential
                    RunLevel = if ($task.RunLevel) { $task.RunLevel } else { 'Highest' }
                    Compatibility = if ($task.Compatibility) { $task.Compatibility } else { 'Win8' }
                    ScheduledAt = $task.ScheduledAt
                    Daily = $task.Daily
                    Disable = $false
                    Hidden = $false               
                }
            }
        }
    }
}