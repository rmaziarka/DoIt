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

function Start-SqlServerAgentJob {
    <#
    .SYNOPSIS
    Starts a SQL Server Agent job, synchronously or asynchronously.

    .PARAMETER JobName
    Name of the job to run.

    .PARAMETER ConnectionString
    Connection string that will be used to connect to the destination database.

    .PARAMETER StepName
    The name of the step at which to begin execution of the job. If empty, job will start at first step.

    .PARAMETER Synchronous
    If $true, job will be run synchronously (will wait until it ends).

    .PARAMETER SleepIntervalInSeconds
    Sleep interval when Synchronous is $true.

    .PARAMETER TimeoutInSeconds
    If specified and Synchronous is $true, function will fail after TimeoutInSeconds seconds.

    .PARAMETER ValidateRunOutcome
    If $true and Synchronous if $true, function will check job outcome and fail if it's not 'succeeded' or timeout occurs.

    .PARAMETER Credential
    Credential to use when opening connection to SQL Server (only if using Windows Authentication).

    .PARAMETER QueryTimeoutInSeconds
    Sql query timeout in seconds.

    .EXAMPLE
    Start-SqlServerAgentJob -JobName 'MyJob' -ConnectionString $Tokens.DatabaseConfig.DatabaseDeploymentConnectionString
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string] 
        $JobName, 

        [Parameter(Mandatory=$true)]
        [string] 
        $ConnectionString,

        [Parameter(Mandatory=$false)]
        [string] 
        $StepName,

        [Parameter(Mandatory=$false)]
        [switch] 
        $Synchronous = $true,

        [Parameter(Mandatory=$false)]
        [int] 
        $SleepIntervalInSeconds = 1,

        [Parameter(Mandatory=$false)]
        [int] 
        $TimeoutInSeconds,

        [Parameter(Mandatory=$false)]
        [switch] 
        $ValidateRunOutcome = $true,

        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential] 
        $Credential,
		
		[Parameter(Mandatory=$false)]
        [int] 
        $QueryTimeoutInSeconds
    )

    if ($Synchronous) {
        $syncLog = 'synchronously'
    } else {
        $syncLog = 'asynchronously'
    }

    Write-Log -Info "Running SQL Server Agent job named '$JobName' $syncLog using connectionString '$ConnectionString'" -Emphasize

    $sqlParams = @{ 
        ConnectionString = $ConnectionString
        IgnoreInitialCatalog = $true
        SqlCommandMode = 'Scalar'
        Mode = '.net'
    }

    $jobId = Invoke-Sql @sqlParams -Query "select job_id from msdb.dbo.sysjobs where name = '$JobName'"
    if (!$jobId) {
        Write-Log -Critical "Cannot find job named '$JobName' in msdb.dbo.sysjobs table."
    }

    $sql = "DECLARE @output int; EXEC @output = msdb.dbo.sp_start_job @job_name=N'$JobName'"
    if ($StepName) {
        $sql += ", @step_name=N'$StepName'"
    }
    $sql += "; SELECT @output"

    $result = Invoke-Sql @sqlParams -Query $sql
    if ($result -ne 0) {
        Write-Log -Critical "Failed to start job '$JobName' - sp_start_job failed with result code $result"
    }

    if (!$Synchronous) {
        Write-Log -Info "Job '$JobName' has been started."
        return
    }

    $sqlParams.SqlCommandMode = 'Dataset'
    $runningSeconds = 0
    do {

        $statusDataSet = (Invoke-Sql @sqlParams -Query "exec msdb.dbo.sp_help_job @job_name = '$JobName', @job_aspect = 'job'").Tables[0]
        if (!$statusDataSet) {
            Write-Log -Critical "sp_help_job did not return a dataset for job '$JobName'. Please investigate."
        }
        $status = $statusDataSet.current_execution_status
        $runOutcome = $statusDataSet.last_run_outcome
        $runDate = $statusDataset.last_run_date
        $runTime = $statusDataset.last_run_time
        $statusName = switch ($status) {
            1 { 'executing'; break; }
            2 { 'waiting for thread'; break; }
            3 { 'between retries'; break; }
            4 { 'idle'; break; }
            5 { 'suspended'; break; }
            7 { 'performing completion actions'; break; }
            default { 'unknown' }
        }
        $runOutcomeName = switch ($runOutcome) {
            0 { 'failed'; break; }
            1 { 'succeeded'; break; }
            3 { 'canceled'; break; }
            default { 'unknown' }
        }
        if ($status -eq 4) {
            break
        }
        Write-Log -_Debug "Job '$JobName' is running with status '$statusName'."
        Start-Sleep -Seconds $SleepIntervalInSeconds
        $runningSeconds += $SleepIntervalInSeconds
    } while (!$TimeoutInSeconds -or $runningSeconds -lt $TimeoutInSeconds)

    if (!$ValidateRunOutcome) {
        Write-Log -Info "Job '$JobName' has finished. Run outcome has not been checked."
        return
    }
    if ($runOutcome -ne 1) {
        $historyInfo = Invoke-Sql @sqlParams -Query "select step_id, step_name, message from msdb.dbo.sysjobhistory where job_id = '$jobId' and run_date = $runDate and run_time = $runTime order by step_id"

        $log = "Job '$JobName' has failed (outcome '$runOutcomeName'). Run history:`r`n"
        foreach ($historyEntry in $historyInfo.Tables[0]) {
            $log += "Step $($historyEntry.step_id). '$($historyEntry.step_name)': $($historyEntry.message)`r`n"
        }
        Write-Log -Warn $log
        Write-Log -Critical "Job '$JobName' has failed - see messages above for details."
    }
    Write-Log -Info "Job '$JobName' has finished successfully."
}