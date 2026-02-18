$PackageName = "HP-Printer-EG"
$Date = Get-Date -Format yyyyMMdd

# Druckerinformationen
$DriverPath = ".\Driver\HPOneDriver_V4_x64.inf"
$DriverName = "HP Smart Universal Printing"
$PrinterName = "HP Color MFP E78625 EG"
$PortName = "IP_192.168.5.148"
$PortIP = "192.168.5.148"

# Start Log
Start-Transcript -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\$PackageName-install-$Date.log" -Force

# Download printer driver from swp-packages
Write-Host "Downloading driver package..."
Invoke-WebRequest -Uri "" -OutFile Driver.zip -Verbose

# Expand zip archive
Write-Host "Expanding zip archive..."
Expand-Archive -Path .\Driver.zip -DestinationPath Driver -Verbose

# Install driver with pnputil
$pnputilargs = @(
    "/add-driver"
    "$DriverPath"
)

Start-Process -FilePath "c:\windows\sysnative\Pnputil.exe" -ArgumentList $pnputilargs -wait -passthru

# Check and install driver
$DriverExist = Get-PrinterDriver -Name $DriverName -ErrorAction SilentlyContinue
if (-not $DriverExist) {
    Write-Host "Adding Printer Driver ""$($DriverName)"""
    Add-PrinterDriver -Name $DriverName -Confirm:$false
} else {
    Write-Host "Print Driver ""$($DriverName)"" already exists. Skipping driver installation."
}

# Check and install printer port
$PortExist = Get-Printerport -Name $PortName -ErrorAction SilentlyContinue
if (-not $PortExist) {
    Write-Host "Adding Port ""$($PortName)"""
    Add-PrinterPort -Name $PortName -PrinterHostAddress $PortIP -Confirm:$false
} else {
    Write-Host "Port $($PortName) already exists. Skipping Printer Port installation."
}

# Check and add printer or remove old
$PrinterExist = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
if (-not $PrinterExist) {
    Write-Host "Adding Printer ""$($PrinterName)"""
    Add-Printer -Name $PrinterName -DriverName $DriverName -PortName $PortName -Confirm:$false
} else {
    Write-Host "Printer ""$($PrinterName)"" already exists. Removing old printer..."
    Remove-Printer -Name $PrinterName -Confirm:$false
    Write-Host "Adding Printer ""$($PrinterName)"""
    Add-Printer -Name $PrinterName -DriverName $DriverName -PortName $PortName -Confirm:$false
}

# Add printer again after deletion
$PrinterExist2 = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
if ($PrinterExist2) {
    Write-Host "Printer ""$($PrinterName)"" added successfully"
} else {
    Write-Host "Error creating printer ""$($PrinterName)"""
}

# Stop Log
Stop-Transcript