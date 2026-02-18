$PackageName = "Hyper-V"
$Date = Get-Date -Format "yyyyMMdd"
$User = $Env:USERDOMAIN+"\"+$Env:USERNAME

function Write-Log {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$true)]
        [ValidateSet("Info", "Warning", "Error")]
        [string]$Severity
    )

    $LogPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\$PackageName-install-$Date.log"

    # Create Log folder if not exist
    $LogFolder = Split-Path -Path $LogPath -Parent
    if (-not (Test-Path -Path $LogFolder)) {
        New-Item -ItemType Directory -Path $LogFolder
    }

    # Add timestamp and severity
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "$Timestamp [$Severity] - $Message"

    # Write log message to file
    Add-Content -Path $LogPath -Value $LogMessage
}

Write-Log -Message "Starting Hyper-V install process..." -Severity Info

$Features = Get-WindowsOptionalFeature -Online -FeatureName "*Hyper-V*"

ForEach ($Feature in $Features) {

	$FeatureName = $Feature.FeatureName
	$FeatureState = $Feature.State

    If ($FeatureState -ne "Enabled") {
        Try {
			Write-Log -Message "Trying to install $FeatureName..." -Severity Info
            Enable-WindowsOptionalFeature -FeatureName $FeatureName -Online -NoRestart -ErrorAction SilentlyContinue | Out-Null
        }
        Catch {
            Write-Log -Message "Failed to install feature: $FeatureName - Error: $_" -Severity Error
        }
    }
	else {
		Write-Log -Message "Feature $FeatureName already installed. Continue." -Severity Info
	}
}

# Check if user is in hyper-v admin group
Write-Log -Message "Checking if $User is part of local hyper-v admin group..." -Severity Info
$GroupMembers = Get-LocalGroupMember -Name "Hyper-V-Administratoren"

if ($GroupMembers.Name -Like "*$User") { 
    Write-Log -Message "User $User is already member of hyper-v admin group. Continue..." -Severity Info
} else {
    Write-Log -Message "Trying to add $User to local hyper-v admin group..." -Severity Info
    try {
        Add-LocalGroupMember -Group "Hyper-V-Administratoren" -Member $User
    }
    catch {
        Write-Log -Message "Failed to add user to group - Error: $_" -Severity Error
    }
}

# Add reg keys to add option to start quick-create without admin privileges
Write-Log -Message "Trying to import reg keys to run hyper-v quick create as invoker..." -Severity Info

try {
    Start-Process -filepath "C:\WINDOWS\system32\reg.exe" -argumentlist "import .\Keys.reg"
}
catch {
    Write-Log -Message "Failed to import reg keys - Error: $_" -Severity Error
}

Write-Log -Message "Hyper-V installation process completed" -Severity Info