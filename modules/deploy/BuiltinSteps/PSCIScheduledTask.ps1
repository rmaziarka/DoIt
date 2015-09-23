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

    param ($NodeName, $Tokens) 

    Import-DscResource -ModuleName GraniResource

    if (!$Tokens.ScheduledTasks) {
        return
    }

    Node $NodeName {

        foreach ($task in $Tokens.ScheduledTasks.GetEnumerator()) {
            $taskName = $task.Key
            $taskSettings = $task.Value

            if ($taskSettings.PowershellCommandToRun) {
                $taskSettings.Execute = 'powershell.exe'
                $taskSettings.Argument = '-Command "{0}"' -f $taskSettings.PowershellCommandToRun
            }

            if ($taskSettings.ScheduledTimeSpanDay -or $taskSettings.ScheduledTimeSpanHour -or $taskSettings.ScheduledTimeSpanMin) { 
                cScheduleTask "TaskSchedule_$taskName" {
                    Ensure = 'Present'
                    TaskName = $taskSettings.TaskName
                    TaskPath = '\'
                    Description = $taskSettings.Description
                    Execute = $taskSettings.Execute
                    Argument = $taskSettings.Argument
                    WorkingDirectory = $taskSettings.WorkingDirectory
                    Credential = $taskSettings.Credential
                    RunLevel = if ($taskSettings.RunLevel) { $taskSettings.RunLevel } else { 'Highest' }
                    Compatibility = if ($taskSettings.Compatibility) { $taskSettings.Compatibility } else { 'Win8' }
                    ScheduledAt = $taskSettings.ScheduledAt
                    ScheduledTimeSpanDay = $taskSettings.ScheduledTimeSpanDay
                    ScheduledTimeSpanHour = $taskSettings.ScheduledTimeSpanHour
                    ScheduledTimeSpanMin = $taskSettings.ScheduledTimeSpanMin
                    ScheduledDurationDay = 0
                    ScheduledDurationHour = 0
                    ScheduledDurationMin = 0
                    Disable = $false
                    Hidden = $false               

                }
            } else {
                cScheduleTask "TaskSchedule_$taskName" {
                    Ensure = 'Present'
                    TaskName = $taskSettings.TaskName
                    TaskPath = '\'
                    Description = $taskSettings.Description
                    Execute = $taskSettings.Execute
                    Argument = $taskSettings.Argument
                    WorkingDirectory = $taskSettings.WorkingDirectory
                    Credential = $taskSettings.Credential
                    RunLevel = if ($taskSettings.RunLevel) { $taskSettings.RunLevel } else { 'Highest' }
                    Compatibility = if ($taskSettings.Compatibility) { $taskSettings.Compatibility } else { 'Win8' }
                    ScheduledAt = $taskSettings.ScheduledAt
                    Daily = $taskSettings.Daily
                    Disable = $false
                    Hidden = $false               
                }
            }

        }
    }

    
}