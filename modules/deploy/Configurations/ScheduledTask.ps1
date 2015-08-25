configuration ScheduledTask {

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