<#
.SYNOPSIS
    Windows System Repair Script - Runs DISM and SFC to repair system issues

.DESCRIPTION
    This script automates the process of running DISM (Deployment Image Servicing and Management)
    followed by SFC (System File Checker) to repair common Windows system issues.

    DISM is run first to repair the Windows component store, which SFC relies on.
    Then SFC scans and repairs corrupted system files.

.PARAMETER LogPath
    Optional path for log files. Defaults to Desktop\SystemRepairLogs

.PARAMETER SkipDISM
    Skip the DISM repair and only run SFC

.PARAMETER SkipSFC
    Skip the SFC scan and only run DISM

.EXAMPLE
    .\Windows-System-Repair.ps1
    Runs both DISM and SFC with default logging

.EXAMPLE
    .\Windows-System-Repair.ps1 -LogPath "C:\Logs"
    Runs both repairs with custom log location

.EXAMPLE
    .\Windows-System-Repair.ps1 -SkipDISM
    Runs only SFC scan

.NOTES
    Author: SeaRipDev
    Requires: Administrator privileges
    Version: 1.0
    Date: 2025-11-24
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$LogPath = "$env:USERPROFILE\Desktop\SystemRepairLogs",

    [Parameter(Mandatory=$false)]
    [switch]$SkipDISM,

    [Parameter(Mandatory=$false)]
    [switch]$SkipSFC
)

####################################################################################################
# Configuration
####################################################################################################

$ErrorActionPreference = "Continue"
$Script:StartTime = Get-Date
$Script:LogFile = ""
$Script:DismSuccess = $false
$Script:SfcSuccess = $false

####################################################################################################
# Functions
####################################################################################################

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White",
        [switch]$NoNewline
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"

    # Write to console with color
    if ($NoNewline) {
        Write-Host $Message -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $Message -ForegroundColor $Color
    }

    # Write to log file
    if ($Script:LogFile) {
        Add-Content -Path $Script:LogFile -Value $logMessage
    }
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Initialize-Logging {
    # Create log directory if it doesn't exist
    if (-not (Test-Path -Path $LogPath)) {
        try {
            New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
            Write-ColorOutput "Created log directory: $LogPath" -Color Green
        } catch {
            Write-ColorOutput "WARNING: Could not create log directory: $LogPath" -Color Yellow
            Write-ColorOutput "Logs will only be displayed on screen." -Color Yellow
            return
        }
    }

    # Create log file with timestamp
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $Script:LogFile = Join-Path -Path $LogPath -ChildPath "SystemRepair-$timestamp.log"

    try {
        # Create the log file
        New-Item -Path $Script:LogFile -ItemType File -Force | Out-Null
        Write-ColorOutput "Log file created: $Script:LogFile" -Color Green
    } catch {
        Write-ColorOutput "WARNING: Could not create log file: $Script:LogFile" -Color Yellow
        $Script:LogFile = ""
    }
}

function Invoke-DISM {
    Write-ColorOutput "`n========================================" -Color Cyan
    Write-ColorOutput "Running DISM System Repair" -Color Cyan
    Write-ColorOutput "========================================" -Color Cyan
    Write-ColorOutput "This may take 10-30 minutes depending on system health..." -Color Yellow
    Write-ColorOutput ""

    $dismLogPath = Join-Path -Path $LogPath -ChildPath "DISM-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

    try {
        # Run DISM with output capture
        Write-ColorOutput "Executing: dism.exe /online /cleanup-image /restorehealth" -Color White

        $dismProcess = Start-Process -FilePath "dism.exe" `
                                      -ArgumentList "/online", "/cleanup-image", "/restorehealth", "/logpath:$dismLogPath" `
                                      -Wait `
                                      -NoNewWindow `
                                      -PassThru

        $exitCode = $dismProcess.ExitCode

        Write-ColorOutput "`nDISM Exit Code: $exitCode" -Color $(if ($exitCode -eq 0) { "Green" } else { "Yellow" })

        if ($exitCode -eq 0) {
            Write-ColorOutput "DISM completed successfully!" -Color Green
            Write-ColorOutput "DISM log saved to: $dismLogPath" -Color Gray
            $Script:DismSuccess = $true
            return $true
        } elseif ($exitCode -eq 3010) {
            Write-ColorOutput "DISM completed successfully but requires a reboot." -Color Yellow
            $Script:DismSuccess = $true
            return $true
        } else {
            Write-ColorOutput "DISM completed with warnings or errors. Check log for details." -Color Yellow
            Write-ColorOutput "DISM log saved to: $dismLogPath" -Color Gray
            return $false
        }
    } catch {
        Write-ColorOutput "ERROR: Failed to run DISM" -Color Red
        Write-ColorOutput "Error details: $($_.Exception.Message)" -Color Red
        return $false
    }
}

function Invoke-SFC {
    Write-ColorOutput "`n========================================" -Color Cyan
    Write-ColorOutput "Running System File Checker (SFC)" -Color Cyan
    Write-ColorOutput "========================================" -Color Cyan
    Write-ColorOutput "This may take 10-20 minutes..." -Color Yellow
    Write-ColorOutput ""

    try {
        # Run SFC with output capture
        Write-ColorOutput "Executing: sfc /scannow" -Color White

        $sfcProcess = Start-Process -FilePath "sfc.exe" `
                                     -ArgumentList "/scannow" `
                                     -Wait `
                                     -NoNewWindow `
                                     -PassThru

        $exitCode = $sfcProcess.ExitCode

        Write-ColorOutput "`nSFC Exit Code: $exitCode" -Color $(if ($exitCode -eq 0) { "Green" } else { "Yellow" })

        # Parse CBS.log for SFC results
        $cbsLog = "$env:SystemRoot\Logs\CBS\CBS.log"
        if (Test-Path $cbsLog) {
            $sfcResults = Get-Content $cbsLog -Tail 50 | Select-String -Pattern "Verification.*complete"
            if ($sfcResults) {
                Write-ColorOutput "`nSFC Results:" -Color Cyan
                $sfcResults | ForEach-Object { Write-ColorOutput $_.Line -Color Gray }
            }
        }

        if ($exitCode -eq 0) {
            Write-ColorOutput "SFC completed successfully!" -Color Green
            $Script:SfcSuccess = $true
            return $true
        } else {
            Write-ColorOutput "SFC completed with warnings or errors." -Color Yellow
            Write-ColorOutput "Check CBS.log for details: $cbsLog" -Color Gray
            return $false
        }
    } catch {
        Write-ColorOutput "ERROR: Failed to run SFC" -Color Red
        Write-ColorOutput "Error details: $($_.Exception.Message)" -Color Red
        return $false
    }
}

function Show-Summary {
    $endTime = Get-Date
    $duration = $endTime - $Script:StartTime

    Write-ColorOutput "`n========================================" -Color Cyan
    Write-ColorOutput "System Repair Summary" -Color Cyan
    Write-ColorOutput "========================================" -Color Cyan

    if (-not $SkipDISM) {
        $dismStatus = if ($Script:DismSuccess) { "SUCCESS" } else { "FAILED/WARNINGS" }
        $dismColor = if ($Script:DismSuccess) { "Green" } else { "Yellow" }
        Write-ColorOutput "DISM Status: $dismStatus" -Color $dismColor
    }

    if (-not $SkipSFC) {
        $sfcStatus = if ($Script:SfcSuccess) { "SUCCESS" } else { "FAILED/WARNINGS" }
        $sfcColor = if ($Script:SfcSuccess) { "Green" } else { "Yellow" }
        Write-ColorOutput "SFC Status: $sfcStatus" -Color $sfcColor
    }

    Write-ColorOutput "`nTotal Duration: $($duration.Hours)h $($duration.Minutes)m $($duration.Seconds)s" -Color White

    if ($Script:LogFile) {
        Write-ColorOutput "Log File: $Script:LogFile" -Color Gray
    }

    Write-ColorOutput "`n========================================" -Color Cyan

    # Check if reboot is recommended
    if ($Script:DismSuccess -or $Script:SfcSuccess) {
        Write-ColorOutput "`nRECOMMENDATION: Restart your computer to complete the repairs." -Color Yellow

        $response = Read-Host "`nWould you like to restart now? (Y/N)"
        if ($response -eq 'Y' -or $response -eq 'y') {
            Write-ColorOutput "Restarting computer in 30 seconds..." -Color Yellow
            Write-ColorOutput "Press Ctrl+C to cancel" -Color Yellow
            Start-Sleep -Seconds 5
            Restart-Computer -Force
        }
    }
}

####################################################################################################
# Main Script
####################################################################################################

# Display banner
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Windows System Repair Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check for administrator privileges
if (-not (Test-Administrator)) {
    Write-Host "ERROR: This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-ColorOutput "Running with Administrator privileges" -Color Green

# Validate parameters
if ($SkipDISM -and $SkipSFC) {
    Write-ColorOutput "ERROR: Cannot skip both DISM and SFC. Nothing to do!" -Color Red
    exit 1
}

# Initialize logging
Initialize-Logging

# Display what will be run
Write-ColorOutput "`nOperations to perform:" -Color White
if (-not $SkipDISM) { Write-ColorOutput "  - DISM /RestoreHealth" -Color White }
if (-not $SkipSFC) { Write-ColorOutput "  - SFC /ScanNow" -Color White }
Write-ColorOutput ""

# Confirmation prompt
$confirmation = Read-Host "Do you want to proceed? (Y/N)"
if ($confirmation -ne 'Y' -and $confirmation -ne 'y') {
    Write-ColorOutput "Operation cancelled by user." -Color Yellow
    exit 0
}

# Run DISM
if (-not $SkipDISM) {
    $dismResult = Invoke-DISM

    if (-not $dismResult) {
        Write-ColorOutput "`nWARNING: DISM encountered issues. SFC may not work correctly." -Color Yellow
        $continue = Read-Host "Continue with SFC anyway? (Y/N)"
        if ($continue -ne 'Y' -and $continue -ne 'y') {
            Write-ColorOutput "Operation cancelled." -Color Yellow
            Show-Summary
            exit 0
        }
    }
}

# Run SFC
if (-not $SkipSFC) {
    # Small delay between operations
    Start-Sleep -Seconds 2
    $sfcResult = Invoke-SFC
}

# Show summary
Show-Summary

Write-ColorOutput "`nScript completed." -Color Green
