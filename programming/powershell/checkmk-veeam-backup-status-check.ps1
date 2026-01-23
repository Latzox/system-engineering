param ([switch] $Debug)
$CMK_VERSION = "2.4.0p12"
## VEEAM Backups
## This powershell script needs to be run with the 64bit powershell
## and thus from a 64bit check_mk agent
## If a 64 bit check_mk agent is available it just needs to be renamed with
## the extension .ps1
## If only a 32bit  check_mk agent is available it needs to be relocated to a
## directory given in veeam_backup_status.bat and the .bat file needs to be
## started by the check_mk agent instead.

try {
    $pshost = Get-Host
    $pswindow = $pshost.ui.rawui
    $newsize = $pswindow.buffersize
    $newsize.height = 300
    $newsize.width = 150
    $pswindow.buffersize = $newsize
}
catch {
    # Buffer size setting not supported in this environment, ignore
}

# Get Information from veeam backup and replication in cmk-friendly format
# V0.9

# Load Veeam Backup and Replication Powershell Snapin
try {
    Import-Module Veeam.Backup.PowerShell -ErrorAction Stop -DisableNameChecking
}
catch {
    try {
        Add-PSSnapin VeeamPSSnapIn -ErrorAction Stop
    }
    catch {
        if ($Debug) {
            Write-Host "No Veeam powershell modules could be loaded"
        }
        Exit 1
    }
}


try {
    $tapeJobs = Get-VBRTapeJob
    write-host "<<<veeam_tapejobs:sep(124)>>>"
    write-host "JobName|JobID|LastResult|LastState"
    foreach ($tapeJob in $tapeJobs) {
        $jobName = $tapeJob.Name
        $jobID = $tapeJob.Id
        $lastResult = $tapeJob.LastResult
        $lastState = $tapeJob.LastState
        write-host "$jobName|$jobID|$lastResult|$lastState"
    }


    try {
        $cdpjobs = Get-VBRCDPPolicy | select-Object Name, NextRun, PolicyState
    }
    catch {
        write-host "CDP jobs not supported"
        $cdpjobs = $false
    }

    if ( $cdpjobs ) {
        $myCdpJobsText = "<<<veeam_cdp_jobs:sep(124)>>>`n"

        foreach ($mycdpjobs in $cdpjobs) {
            $MyCdpJobsName = $mycdpjobs.Name -replace "\'", "_" -replace " ", "_"

            $MyCdpJobsNextRun = $mycdpjobs.NextRun
            if ($MyCdpJobsNextRun -ne $null) {
                $MyCdpJobsNextRun = get-date -date $MyCdpJobsNextRun -Uformat %s 
            }
            else {
                $MyCdpJobsNextRun = "null" 
            }

            $MyCdpJobsPolicyState = $mycdpjobs.PolicyState

            $myCdpJobsText = "$myCdpJobsText" + "$MyCdpJobsName" + "|" + "$MyCdpJobsNextRun" + "|" + "$MyCdpJobsPolicyState" + "`n"
        }

        write-host $myCdpJobsText
    }

    $myJobsText = "<<<veeam_jobs:sep(9)>>>`n"
    $myTaskText = ""

    # Use Get-VBRComputerBackupJob (replacement for deprecated Get-VBRJob)
    $myBackupJobs = Get-VBRComputerBackupJob -WarningAction SilentlyContinue | Where-Object { $_.ScheduleEnabled -eq $true -and $_.JobEnabled -eq $true }

    foreach ($myJob in $myBackupJobs) {
        $myJobName = $myJob.Name -replace "\'", "_" -replace " ", "_"

        $myJobType = $myJob.Type

        # Get the last session for this computer backup job (pipeline input from job object)
        $myJobLastSession = $myJob | Get-VBRComputerBackupJobSession -WarningAction SilentlyContinue | Sort-Object CreationTime -Descending | Select-Object -First 1

        if ($myJobLastSession) {
            $myJobLastState = $myJobLastSession.State
            $myJobLastResult = $myJobLastSession.Result

            $myJobCreationTime = $myJobLastSession.CreationTime | Get-Date -Format "dd.MM.yyyy HH\:mm\:ss" -ErrorAction SilentlyContinue
            $myJobEndTime = $myJobLastSession.EndTime | Get-Date -Format "dd.MM.yyyy HH\:mm\:ss" -ErrorAction SilentlyContinue

            # Collect warning and error messages from task sessions
            $warningMessages = @()
            $errorMessages = @()

            $taskSessions = Get-VBRTaskSession -Session $myJobLastSession -ErrorAction SilentlyContinue
            foreach ($task in $taskSessions) {
                if ($task.Status -eq "Warning" -and $task.Info.Reason) {
                    $warningMessages += "$($task.Name): $($task.Info.Reason)"
                }
                elseif ($task.Status -eq "Failed" -and $task.Info.Reason) {
                    $errorMessages += "$($task.Name): $($task.Info.Reason)"
                }
            }

            # Also check session log for additional warnings/errors
            try {
                $sessionLogs = $myJobLastSession.Logger.GetLog() | Where-Object { $_.Status -eq 'EWarning' -or $_.Status -eq 'EFailed' }
                foreach ($logEntry in $sessionLogs) {
                    if ($logEntry.Status -eq 'EWarning') {
                        $warningMessages += $logEntry.Title
                    }
                    elseif ($logEntry.Status -eq 'EFailed') {
                        $errorMessages += $logEntry.Title
                    }
                }
            }
            catch {
                # Logger might not be available, continue without it
            }

            # Join messages with semicolon, escape tabs
            $warningText = ($warningMessages | Select-Object -Unique | ForEach-Object { $_ -replace "`t", " " }) -join "; "
            $errorText = ($errorMessages | Select-Object -Unique | ForEach-Object { $_ -replace "`t", " " }) -join "; "

            if ([string]::IsNullOrEmpty($warningText)) { $warningText = "" }
            if ([string]::IsNullOrEmpty($errorText)) { $errorText = "" }
        }
        else {
            $myJobLastState = "NoSession"
            $myJobLastResult = "None"
            $myJobCreationTime = ""
            $myJobEndTime = ""
            $warningText = ""
            $errorText = ""
        }

        $myJobsText = "$myJobsText" + "$myJobName" + "`t" + "$myJobType" + "`t" + "$myJobLastState" + "`t" + "$myJobLastResult" + "`t" + "$myJobCreationTime" + "`t" + "$myJobEndTime" + "`t" + "$warningText" + "`t" + "$errorText" + "`n"

        # Get task details for backup jobs
        if ($myJobLastSession) {
            # Get all sessions including retries
            $sessions = @($myJobLastSession)
            try {
                if ($myJobLastSession.IsRetryMode) {
                    $sessions = $myJobLastSession.GetOriginalAndRetrySessions($TRUE)
                }
            }
            catch {
                # Retry mode check might fail, continue with single session
            }

            $myJobLastSessionTasks = $sessions | Get-VBRTaskSession -ErrorAction SilentlyContinue

            foreach ($myTask in $myJobLastSessionTasks) {
                $myTaskName = $myTask.Name -replace "[^ -x7e]" -replace " ", "_"

                $myTaskText = "$myTaskText" + "<<<<" + "$myTaskName" + ">>>>" + "`n"

                $myTaskText = "$myTaskText" + "<<<" + "veeam_client:sep(9)" + ">>>" + "`n"

                $myTaskStatus = $myTask.Status

                $myTaskText = "$myTaskText" + "Status" + "`t" + "$myTaskStatus" + "`n"

                $myTaskText = "$myTaskText" + "JobName" + "`t" + "$myJobName" + "`n"

                # Get task warning/error reason if available
                if ($myTask.Info.Reason) {
                    $myTaskReason = $myTask.Info.Reason -replace "`t", " " -replace "`n", " " -replace "`r", ""
                    $myTaskText = "$myTaskText" + "Reason" + "`t" + "$myTaskReason" + "`n"
                }

                $myTaskTotalSize = $myTask.Progress.TotalSize

                $myTaskText = "$myTaskText" + "TotalSizeByte" + "`t" + "$myTaskTotalSize" + "`n"

                $myTaskReadSize = $myTask.Progress.ReadSize

                $myTaskText = "$myTaskText" + "ReadSizeByte" + "`t" + "$myTaskReadSize" + "`n"

                $myTaskTransferedSize = $myTask.Progress.TransferedSize

                $myTaskText = "$myTaskText" + "TransferedSizeByte" + "`t" + "$myTaskTransferedSize" + "`n"

                # Starting from Version 9.5U3 StartTime is not supported anymore
                If ($myTask.Progress.StartTime -eq $Null) {
                    $myTaskStartTime = $myTask.Progress.StartTimeLocal
                }
                Else {
                    $myTaskStartTime = $myTask.Progress.StartTime
                }
                $myTaskStartTime = $myTaskStartTime | Get-Date -Format "dd.MM.yyyy HH\:mm\:ss" -ErrorAction SilentlyContinue

                $myTaskText = "$myTaskText" + "StartTime" + "`t" + "$myTaskStartTime" + "`n"

                # Starting from Version 9.5U3 StopTime is not supported anymore
                If ($myTask.Progress.StopTime -eq $Null) {
                    $myTaskStopTime = $myTask.Progress.StopTimeLocal
                }
                Else {
                    $myTaskStopTime = $myTask.Progress.StopTime
                }
                $lastBackupAge = New-TimeSpan -Start $myTaskStopTime -End (Get-Date) -ErrorAction SilentlyContinue

                $myTaskText = "$myTaskText" + "LastBackupAge" + "`t" + "$($lastBackupAge.TotalSeconds)" + "`n"

                # Result is a value of type System.TimeStamp. I'm sure there is a more elegant way of formatting the output:
                $myTaskDuration = "" + "{0:D2}" -f $myTask.Progress.duration.Days + ":" + "{0:D2}" -f $myTask.Progress.duration.Hours + ":" + "{0:D2}" -f $myTask.Progress.duration.Minutes + ":" + "{0:D2}" -f $myTask.Progress.duration.Seconds

                $myTaskText = "$myTaskText" + "DurationDDHHMMSS" + "`t" + "$myTaskDuration" + "`n"

                $myTaskAvgSpeed = $myTask.Progress.AvgSpeed

                $myTaskText = "$myTaskText" + "AvgSpeedBps" + "`t" + "$myTaskAvgSpeed" + "`n"

                $myTaskDisplayName = $myTask.Progress.DisplayName

                $myTaskText = "$myTaskText" + "DisplayName" + "`t" + "$myTaskDisplayName" + "`n"

                $myBackupHost = Hostname

                $myTaskText = "$myTaskText" + "BackupServer" + "`t" + "$myBackupHost" + "`n"

                $myTaskText = "$myTaskText" + "<<<<" + ">>>>" + "`n"

            }
        }

    }

    write-host $myJobsText
    write-host $myTaskText
}

catch {
    $errMsg = $_.Exception.Message
    $errItem = $_.Exception.ItemName
    Write-Error "Totally unexpected and unhandled error occured:`n Item: $errItem`n Error Message: $errMsg"
    Break
}
