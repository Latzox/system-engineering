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
    # Use Get-VBRComputerBackupJob (replacement for deprecated Get-VBRJob)
    $myBackupJobs = Get-VBRComputerBackupJob -WarningAction SilentlyContinue | Where-Object { $_.ScheduleEnabled -eq $true -and $_.JobEnabled -eq $true }

    foreach ($myJob in $myBackupJobs) {
        # Service name: no spaces allowed
        $serviceName = "Veeam_Backup_" + ($myJob.Name -replace "\'", "_" -replace " ", "_")
        $myJobName = $myJob.Name -replace "\'", "_" -replace " ", "_"

        $myJobType = $myJob.Type

        # Get the last session for this computer backup job
        $myJobLastSession = $myJob | Get-VBRComputerBackupJobSession -WarningAction SilentlyContinue | Sort-Object CreationTime -Descending | Select-Object -First 1

        if ($myJobLastSession) {
            $myJobLastState = $myJobLastSession.State
            $myJobLastResult = $myJobLastSession.Result
            $myJobCreationTime = $myJobLastSession.CreationTime | Get-Date -Format "dd.MM.yyyy HH:mm:ss" -ErrorAction SilentlyContinue
            $myJobEndTime = $myJobLastSession.EndTime | Get-Date -Format "dd.MM.yyyy HH:mm:ss" -ErrorAction SilentlyContinue

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

            # Join messages with semicolon
            $warningText = ($warningMessages | Select-Object -Unique) -join "; "
            $errorText = ($errorMessages | Select-Object -Unique) -join "; "

            # Determine CheckMK status based on Veeam result
            # 0=OK, 1=WARNING, 2=CRITICAL, 3=UNKNOWN
            switch ($myJobLastResult.ToString()) {
                "Success" { $status = 0 }
                "Warning" { $status = 1 }
                "Failed"  { $status = 2 }
                default   { $status = 3 }
            }

            # Build description
            $description = "State: $myJobLastState, Result: $myJobLastResult, Start: $myJobCreationTime, End: $myJobEndTime"
            if (-not [string]::IsNullOrEmpty($warningText)) {
                $description += ", Warning: $warningText"
            }
            if (-not [string]::IsNullOrEmpty($errorText)) {
                $description += ", Error: $errorText"
            }
        }
        else {
            $status = 3
            $description = "No backup session found"
        }

        # Output in CheckMK local check format: <status> <service_name> <perfdata> <description>
        Write-Host "$status $serviceName - $description"
    }
}

catch {
    $errMsg = $_.Exception.Message
    $errItem = $_.Exception.ItemName
    Write-Error "Totally unexpected and unhandled error occured:`n Item: $errItem`n Error Message: $errMsg"
    Break
}
