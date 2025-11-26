# Windows System Repair Script

PowerShell script to automate running DISM and SFC for Windows system repairs.

## Overview

This script automates the common Windows repair sequence:
1. **DISM** (Deployment Image Servicing and Management) - Repairs the Windows component store
2. **SFC** (System File Checker) - Scans and repairs corrupted system files

Running DISM first is important because SFC relies on the component store that DISM repairs.

## Requirements

- Windows 10 or later
- PowerShell 5.1 or later
- **Administrator privileges** (required)

## Features

- Administrator privilege checking
- Comprehensive logging with timestamps
- Color-coded console output
- Progress indicators
- Exit code interpretation
- Optional reboot prompt
- Error handling
- Flexible operation (can skip DISM or SFC)

## Usage

### Basic Usage (Recommended)

Open PowerShell as Administrator and run:

```powershell
.\Windows-System-Repair.ps1
```

This will:
- Check for admin privileges
- Create a log directory on your Desktop
- Run DISM /RestoreHealth
- Run SFC /ScanNow
- Generate a timestamped log file
- Prompt for reboot if needed

### Custom Log Location

```powershell
.\Windows-System-Repair.ps1 -LogPath "C:\Repair\Logs"
```

### Skip DISM (Run Only SFC)

```powershell
.\Windows-System-Repair.ps1 -SkipDISM
```

### Skip SFC (Run Only DISM)

```powershell
.\Windows-System-Repair.ps1 -SkipSFC
```

### Get Help

```powershell
Get-Help .\Windows-System-Repair.ps1 -Full
```

## How to Run as Administrator

### Method 1: From Start Menu
1. Click Start
2. Type "PowerShell"
3. Right-click "Windows PowerShell"
4. Select "Run as Administrator"
5. Navigate to the script location: `cd "path\to\script"`
6. Run: `.\Windows-System-Repair.ps1`

### Method 2: From File Explorer
1. Hold Shift and right-click in the folder containing the script
2. Select "Open PowerShell window here as administrator"
3. Run: `.\Windows-System-Repair.ps1`

### Method 3: Bypass Execution Policy (if needed)
If you get an execution policy error:

```powershell
PowerShell.exe -ExecutionPolicy Bypass -File ".\Windows-System-Repair.ps1"
```

## Log Files

The script creates logs in: `%USERPROFILE%\Desktop\SystemRepairLogs\` (by default)

### Log File Types:
- `SystemRepair-YYYYMMDD-HHMMSS.log` - Main script log with timestamps
- `DISM-YYYYMMDD-HHMMSS.log` - Detailed DISM operation log
- CBS.log - SFC log (located at `C:\Windows\Logs\CBS\CBS.log`)

## Exit Codes

### DISM Exit Codes:
- `0` - Success, no errors
- `3010` - Success, but reboot required
- Other - Errors occurred (check DISM log)

### SFC Exit Codes:
- `0` - No integrity violations found
- `1` - Violations found and repaired
- `2` - Violations found but some could not be repaired
- `3` - Violations found but could not be repaired

## Typical Run Time

- **DISM**: 10-30 minutes (depending on system health)
- **SFC**: 10-20 minutes
- **Total**: 20-50 minutes

## When to Use This Script

Use this script when experiencing:
- Windows Update failures
- System file corruption errors
- Blue screen errors (BSOD)
- Windows Features not working correctly
- System instability
- "Windows Resource Protection" errors

## What Happens During Execution

1. **Pre-Flight Checks**
   - Verifies administrator privileges
   - Creates log directory
   - Shows operations to perform
   - Asks for confirmation

2. **DISM Execution**
   - Connects to Windows Update
   - Downloads replacement files if needed
   - Repairs component store
   - Creates detailed log

3. **SFC Execution**
   - Scans all protected system files
   - Compares against known good versions
   - Repairs corrupted files
   - Logs all findings

4. **Post-Execution**
   - Shows summary of results
   - Displays execution time
   - Recommends reboot if needed
   - Optionally triggers restart

## Troubleshooting

### "Running scripts is disabled on this system"
Set execution policy:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### DISM Fails to Connect to Windows Update
- Check internet connection
- Try running Windows Update manually first
- Check if Windows Update service is running

### SFC Cannot Repair Some Files
- This is normal if the component store is damaged
- Run DISM first (this script does this automatically)
- May need to perform an in-place upgrade repair

### Script Runs Very Slowly
- This is normal - repairs take time
- Do not interrupt the process
- Ensure sufficient free disk space (20GB+ recommended)

## Best Practices

1. **Create a System Restore Point First**
   ```powershell
   Checkpoint-Computer -Description "Before System Repair" -RestorePointType MODIFY_SETTINGS
   ```

2. **Close All Applications**
   - Save your work
   - Close unnecessary programs
   - Disable antivirus temporarily if it interferes

3. **Ensure Stable Power**
   - Plug in laptop (don't run on battery)
   - Ensure stable power supply

4. **Review Logs**
   - Always check logs after completion
   - Look for specific errors or warnings

5. **Reboot After Completion**
   - Recommended even if not prompted
   - Ensures repairs take effect

## Network Considerations

- DISM requires internet access to download repair files
- Large files may be downloaded (100MB - 1GB+)
- Consider running during off-peak hours if on metered connection

## Safe to Interrupt?

- **DISM**: Generally safe to cancel (Ctrl+C), but you'll need to run again
- **SFC**: Should not be interrupted - may leave system in inconsistent state

## Advanced Options

### Run Without Prompts (Silent Mode)
Modify the script to remove confirmation prompts for automation:
```powershell
# Comment out or remove the confirmation prompt lines
```

### Schedule Regular Maintenance
Create a scheduled task to run monthly:
```powershell
$action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument '-ExecutionPolicy Bypass -File "C:\Path\To\Windows-System-Repair.ps1"'
$trigger = New-ScheduledTaskTrigger -Weekly -At 2AM -DaysOfWeek Sunday
Register-ScheduledTask -TaskName "Monthly System Repair" -Action $action -Trigger $trigger -RunLevel Highest
```

## Version History

- **v1.0** (2025-11-24) - Initial release
  - DISM and SFC automation
  - Logging and error handling
  - Administrator checking
  - Color-coded output

## Author

SeaRipDev

## License

Free to use and modify for personal and commercial purposes.
