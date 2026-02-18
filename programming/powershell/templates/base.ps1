<#
.SYNOPSIS
    This script removes a specified user from a list of predefined distribution groups.
.DESCRIPTION
    The script takes a user account and removes it from a set of distribution groups related to the GRE organizational structure. 
.PARAMETER User
    (Mandatory) The email address of the user to remove
.PARAMETER LogFile
    (Optional) The path of the logfile. If empty, the execution will be console only.
.EXAMPLE
    ./Remove-UserFromDG.ps1 -User "john.doe@example.com"
.NOTES
    - Author: Marco Platzer
    - Version: 1.0
    - Last Updated: September 2024
#>

# Parameter declaration
param (
    [Parameter(Mandatory = $true, HelpMessage = "Email address of the user to remove.")]
    [ValidatePattern('^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')]
    [string]$User,

    [Parameter(Mandatory = $false, HelpMessage = "Path of the log file.")]
    [string]$LogFile
)

# Set strict mode and define error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Functions
function Write-Log {
    param (
        [string]$Message,

        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$LogLevel = "Info"
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "$Timestamp [$LogLevel] $Message"

    if ($LogFile) {
        try {
            Add-Content -Path $LogFile -Value $LogEntry
        }
        catch {
            Write-Host "$Timestamp [Error] Error writing to log file: $_" -ForegroundColor DarkRed
        }
    }
    
    if ($LogLevel -eq "Error") {
        Write-Host $LogEntry -ForegroundColor DarkRed
    }
    elseif ($LogLevel -eq "Warning") {
        Write-Host $LogEntry -ForegroundColor DarkYellow
    }
    elseif ($LogLevel -eq "Success") {
        Write-Host $LogEntry -ForegroundColor DarkGreen
    }
    else {
        Write-Host $LogEntry
    }
}

function Connect-Exchange {
    Write-Log -Message "Trying to connect to Exchange Online..."
    $attempts = 0
    $maxAttempts = 3
    while ($attempts -lt $maxAttempts) {
        try {
            Connect-ExchangeOnline -ShowBanner:$false
            Write-Log -Message "Exchange connection established" -LogLevel Success
            break
        }
        catch {
            $attempts++
            Write-Log -Message "Failed to connect, attempt $attempts/${maxAttempts}: $_" -LogLevel Warning
            if ($attempts -eq $maxAttempts) {
                Write-Log -Message "Max attempts reached, exiting." -LogLevel Error
                Exit 1
            }
        }
    }
}

# Begin logging
Write-Log -Message "Execution started" -LogLevel Success

# Enforce TLS 1.2 for secure network communication
if ([Net.ServicePointManager]::SecurityProtocol -ne [Net.SecurityProtocolType]::Tls12) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Write-Log -Message "TLS 1.2 enforced for secure communication." -LogLevel Success
} else {
    Write-Log -Message "TLS 1.2 already enforced." -LogLevel Info
}

# Import/Install modules
$modules = @(
    "ExchangeOnlineManagement"
)

Write-Log -Message "Install and import required modules..."
foreach ($module in $modules) {
    $installedModule = Get-InstalledModule -Name $module -ErrorAction SilentlyContinue
    $loadedModule = Get-Module -Name $module -ListAvailable -ErrorAction SilentlyContinue

    if (-Not $installedModule) {
        try {
            Install-Module -Name $module -Scope CurrentUser -Force -ErrorAction Stop
            Write-Log -Message "Installed module: $module" -LogLevel Success
        }
        catch {
            Write-Log -Message "Failed to install module ${module}: $_" -LogLevel Error
            Exit 1
        }
    }

    if (-Not $loadedModule) {
        try {
            Import-Module -Name $module -ErrorAction Stop
            Write-Log -Message "Imported module: $module" -LogLevel Success
        }
        catch {
            Write-Log -Message "Failed to import module ${module}: $_" -LogLevel Error
            Exit 1
        }
    }
}

# Main script logic
try {
    Write-Log -Message "Logfile path: $(if ($LogFile) {(Get-ChildItem -Path $LogFile).FullName} else {"Console only"})"
    Write-Log -Message "Submitted parameters: $User"

    # Connect to Exchange Online
    Connect-Exchange

    # Main script functionality
    Write-Log -Message "User: $User"
}
catch {
    Write-Log -Message $_ -LogLevel "Error"
}
finally {
    Write-Log -Message "Execution finished" -LogLevel Success
    Disconnect-ExchangeOnline -Confirm:$false
}
