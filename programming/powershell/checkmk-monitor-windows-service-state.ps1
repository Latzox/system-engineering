$ServiceName = "PBIEgwService"

try {
    $service = Get-Service -Name $ServiceName -ErrorAction Stop

    if ($service.Status -eq 'Running') {
        # OK
        $status = 0
        $description = "Service '$ServiceName' is running (OK)"
    }
    else {
        # CRITICAL
        $status = 2
        $description = "Service '$ServiceName' is NOT running (CRITICAL)"
    }
}
catch {
    $status = 2
    $description = "Service '$ServiceName' not found (CRITICAL)"
}

Write-Output "$status $ServiceName - $description"
