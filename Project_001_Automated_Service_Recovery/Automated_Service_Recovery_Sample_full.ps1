# Automated Service Recovery Solution
# Portfolio Version (Sanitized)

$successLog = "C:\Automation\Logs\restart_success_log.txt"
$failureLog = "C:\Automation\Logs\restart_failed_log.txt"

$coreService = "DatabaseService"
$applicationService = "CriticalApplicationService"

# Get application service safely
$applicationStatus = Get-Service -Name $applicationService -ErrorAction SilentlyContinue

# Get core service
$coreServiceStatus = Get-Service -Name $coreService

# Capture dependencies before restart
$dependentServices = $coreServiceStatus.DependentServices

# Services intentionally excluded from restart
$IgnoredServices = @(
    "AuxiliaryServiceA",
    "AuxiliaryServiceB",
    "BackgroundProcessingService"
)

# Ensure log folders exist
$successLogFolder = Split-Path $successLog
$failureLogFolder = Split-Path $failureLog

if (!(Test-Path $successLogFolder)) {
    New-Item -ItemType Directory -Path $successLogFolder -Force
}

if (!(Test-Path $failureLogFolder)) {
    New-Item -ItemType Directory -Path $failureLogFolder -Force
}

# Proceed only if the application service is unavailable
if (-not $applicationStatus -or $applicationStatus.Status -ne "Running") {

    try {

        # Restart core infrastructure services
        Restart-Service -Name "ManagementService" -Force -ErrorAction Stop
        Restart-Service -Name $coreService -Force -ErrorAction Stop

        Add-Content $successLog @"
$(Get-Date)
Response: Core infrastructure services restarted successfully.
--------------------------------------------------
"@

    }
    catch {

        Add-Content $failureLog @"
$(Get-Date)
Service: Core Infrastructure Services
Error: $($_.Exception.Message)
Line: $($_.InvocationInfo.ScriptLineNumber)
--------------------------------------------------
"@
    }

    # Restore dependent services
    foreach ($svc in $dependentServices) {

        if ($IgnoredServices -contains $svc.Name) {
            continue
        }

        try {

            $currentStatus = Get-Service $svc.Name

            if ($currentStatus.Status -ne "Running") {

                Start-Service -Name $svc.Name -ErrorAction Stop

                Add-Content $successLog @"
$(Get-Date)
Service: $($svc.Name)
Status: Started Successfully
--------------------------------------------------
"@
            }

        }
        catch {

            Add-Content $failureLog @"
$(Get-Date)
Service: $($svc.Name)
Error: $($_.Exception.Message)
Line: $($_.InvocationInfo.ScriptLineNumber)
--------------------------------------------------
"@
        }
    }

    Add-Content $successLog @"
$(Get-Date)
Response: Automated recovery workflow completed successfully.
--------------------------------------------------
"@

}
else {

    Add-Content $successLog @"
$(Get-Date)
Response: All monitored services are healthy. No action required.
--------------------------------------------------
"@
}