#!/bin/bash
####################################################################################################
#
# Test Suite for Windows-System-Repair.ps1
#
# Purpose: Validates the PowerShell script structure and content
# Usage: bash test_Windows_System_Repair.sh
#
# Note: This script runs on macOS/Linux to validate the PowerShell script structure.
#       To test actual PowerShell syntax, run on Windows with: Test-Path and Get-Command
#
####################################################################################################

# Test configuration
SCRIPT_PATH="/Users/cwripley/Desktop/Ripley Scripts/Windows-System-Repair.ps1"
TEST_RESULTS=()
TESTS_PASSED=0
TESTS_FAILED=0

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

####################################################################################################
# Test Helper Functions
####################################################################################################

print_result() {
    local test_name=$1
    local result=$2
    local message=$3

    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}[PASS]${NC} $test_name"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}[FAIL]${NC} $test_name: $message"
        ((TESTS_FAILED++))
    fi
    TEST_RESULTS+=("$result: $test_name")
}

####################################################################################################
# Basic Script Tests
####################################################################################################

test_script_exists() {
    if [ -f "$SCRIPT_PATH" ]; then
        print_result "Script file exists" "PASS" ""
        return 0
    else
        print_result "Script file exists" "FAIL" "Script not found at $SCRIPT_PATH"
        return 1
    fi
}

test_powershell_extension() {
    if [[ "$SCRIPT_PATH" == *.ps1 ]]; then
        print_result "PowerShell file extension (.ps1)" "PASS" ""
        return 0
    else
        print_result "PowerShell file extension (.ps1)" "FAIL" "Not a .ps1 file"
        return 1
    fi
}

test_synopsis_present() {
    if grep -q "\.SYNOPSIS" "$SCRIPT_PATH"; then
        print_result "Synopsis documentation present" "PASS" ""
        return 0
    else
        print_result "Synopsis documentation present" "FAIL" "No .SYNOPSIS found"
        return 1
    fi
}

test_description_present() {
    if grep -q "\.DESCRIPTION" "$SCRIPT_PATH"; then
        print_result "Description documentation present" "PASS" ""
        return 0
    else
        print_result "Description documentation present" "FAIL" "No .DESCRIPTION found"
        return 1
    fi
}

test_examples_present() {
    if grep -q "\.EXAMPLE" "$SCRIPT_PATH"; then
        print_result "Example usage present" "PASS" ""
        return 0
    else
        print_result "Example usage present" "FAIL" "No .EXAMPLE found"
        return 1
    fi
}

####################################################################################################
# Parameter Tests
####################################################################################################

test_cmdletbinding() {
    if grep -q "\[CmdletBinding()\]" "$SCRIPT_PATH"; then
        print_result "CmdletBinding attribute present" "PASS" ""
        return 0
    else
        print_result "CmdletBinding attribute present" "FAIL" "No [CmdletBinding()] found"
        return 1
    fi
}

test_parameters_defined() {
    if grep -q "param(" "$SCRIPT_PATH"; then
        print_result "Parameters defined" "PASS" ""
        return 0
    else
        print_result "Parameters defined" "FAIL" "No param() block found"
        return 1
    fi
}

test_logpath_parameter() {
    if grep -q "LogPath" "$SCRIPT_PATH"; then
        print_result "LogPath parameter exists" "PASS" ""
        return 0
    else
        print_result "LogPath parameter exists" "FAIL" "LogPath parameter not found"
        return 1
    fi
}

####################################################################################################
# Function Tests
####################################################################################################

test_administrator_check_function() {
    if grep -q "function Test-Administrator" "$SCRIPT_PATH"; then
        print_result "Administrator check function exists" "PASS" ""
        return 0
    else
        print_result "Administrator check function exists" "FAIL" "Test-Administrator function not found"
        return 1
    fi
}

test_logging_function() {
    if grep -q "function Initialize-Logging" "$SCRIPT_PATH"; then
        print_result "Logging initialization function exists" "PASS" ""
        return 0
    else
        print_result "Logging initialization function exists" "FAIL" "Initialize-Logging function not found"
        return 1
    fi
}

test_dism_function() {
    if grep -q "function Invoke-DISM" "$SCRIPT_PATH"; then
        print_result "DISM execution function exists" "PASS" ""
        return 0
    else
        print_result "DISM execution function exists" "FAIL" "Invoke-DISM function not found"
        return 1
    fi
}

test_sfc_function() {
    if grep -q "function Invoke-SFC" "$SCRIPT_PATH"; then
        print_result "SFC execution function exists" "PASS" ""
        return 0
    else
        print_result "SFC execution function exists" "FAIL" "Invoke-SFC function not found"
        return 1
    fi
}

test_summary_function() {
    if grep -q "function Show-Summary" "$SCRIPT_PATH"; then
        print_result "Summary display function exists" "PASS" ""
        return 0
    else
        print_result "Summary display function exists" "FAIL" "Show-Summary function not found"
        return 1
    fi
}

test_color_output_function() {
    if grep -q "function Write-ColorOutput" "$SCRIPT_PATH"; then
        print_result "Color output function exists" "PASS" ""
        return 0
    else
        print_result "Color output function exists" "FAIL" "Write-ColorOutput function not found"
        return 1
    fi
}

####################################################################################################
# Command Tests
####################################################################################################

test_dism_command() {
    if grep -q "dism.exe" "$SCRIPT_PATH"; then
        print_result "DISM command present" "PASS" ""
        return 0
    else
        print_result "DISM command present" "FAIL" "dism.exe not found"
        return 1
    fi
}

test_dism_arguments() {
    if grep -q "/online.*cleanup-image.*restorehealth" "$SCRIPT_PATH"; then
        print_result "DISM arguments correct" "PASS" ""
        return 0
    else
        print_result "DISM arguments correct" "FAIL" "DISM arguments not found or incorrect"
        return 1
    fi
}

test_sfc_command() {
    if grep -q "sfc.exe" "$SCRIPT_PATH"; then
        print_result "SFC command present" "PASS" ""
        return 0
    else
        print_result "SFC command present" "FAIL" "sfc.exe not found"
        return 1
    fi
}

test_sfc_arguments() {
    if grep -q "/scannow" "$SCRIPT_PATH"; then
        print_result "SFC arguments correct" "PASS" ""
        return 0
    else
        print_result "SFC arguments correct" "FAIL" "/scannow argument not found"
        return 1
    fi
}

####################################################################################################
# Error Handling Tests
####################################################################################################

test_error_action_preference() {
    if grep -q "ErrorActionPreference" "$SCRIPT_PATH"; then
        print_result "Error action preference set" "PASS" ""
        return 0
    else
        print_result "Error action preference set" "FAIL" "ErrorActionPreference not found"
        return 1
    fi
}

test_try_catch_blocks() {
    if grep -q "try {" "$SCRIPT_PATH" && grep -q "catch {" "$SCRIPT_PATH"; then
        print_result "Try-catch error handling present" "PASS" ""
        return 0
    else
        print_result "Try-catch error handling present" "FAIL" "No try-catch blocks found"
        return 1
    fi
}

test_exit_code_checking() {
    if grep -q "ExitCode" "$SCRIPT_PATH" || grep -q "LASTEXITCODE" "$SCRIPT_PATH"; then
        print_result "Exit code checking present" "PASS" ""
        return 0
    else
        print_result "Exit code checking present" "FAIL" "No exit code checking found"
        return 1
    fi
}

####################################################################################################
# Logging Tests
####################################################################################################

test_log_file_creation() {
    if grep -qi "New-Item.*LogFile\|New-Item.*\.log" "$SCRIPT_PATH"; then
        print_result "Log file creation logic present" "PASS" ""
        return 0
    else
        print_result "Log file creation logic present" "FAIL" "No log file creation found"
        return 1
    fi
}

test_timestamp_logging() {
    if grep -q "Get-Date.*Format" "$SCRIPT_PATH"; then
        print_result "Timestamp formatting present" "PASS" ""
        return 0
    else
        print_result "Timestamp formatting present" "FAIL" "No timestamp formatting found"
        return 1
    fi
}

test_add_content_logging() {
    if grep -q "Add-Content" "$SCRIPT_PATH"; then
        print_result "Log writing (Add-Content) present" "PASS" ""
        return 0
    else
        print_result "Log writing (Add-Content) present" "FAIL" "No Add-Content found"
        return 1
    fi
}

####################################################################################################
# User Interaction Tests
####################################################################################################

test_confirmation_prompt() {
    if grep -q "Read-Host" "$SCRIPT_PATH"; then
        print_result "User confirmation prompt present" "PASS" ""
        return 0
    else
        print_result "User confirmation prompt present" "FAIL" "No Read-Host found"
        return 1
    fi
}

test_write_host_output() {
    if grep -q "Write-Host" "$SCRIPT_PATH"; then
        print_result "Console output (Write-Host) present" "PASS" ""
        return 0
    else
        print_result "Console output (Write-Host) present" "FAIL" "No Write-Host found"
        return 1
    fi
}

test_color_coding() {
    if grep -q "ForegroundColor" "$SCRIPT_PATH"; then
        print_result "Color-coded output present" "PASS" ""
        return 0
    else
        print_result "Color-coded output present" "FAIL" "No color coding found"
        return 1
    fi
}

####################################################################################################
# Security Tests
####################################################################################################

test_admin_privilege_check() {
    if grep -q "Administrator" "$SCRIPT_PATH" && grep -q "WindowsIdentity" "$SCRIPT_PATH"; then
        print_result "Administrator privilege check present" "PASS" ""
        return 0
    else
        print_result "Administrator privilege check present" "FAIL" "No admin check found"
        return 1
    fi
}

test_requires_elevation() {
    if grep -q "Run as Administrator" "$SCRIPT_PATH"; then
        print_result "Elevation requirement documented" "PASS" ""
        return 0
    else
        print_result "Elevation requirement documented" "FAIL" "No elevation requirement mentioned"
        return 1
    fi
}

####################################################################################################
# Feature Tests
####################################################################################################

test_skip_dism_option() {
    if grep -q "SkipDISM" "$SCRIPT_PATH"; then
        print_result "SkipDISM parameter exists" "PASS" ""
        return 0
    else
        print_result "SkipDISM parameter exists" "FAIL" "SkipDISM not found"
        return 1
    fi
}

test_skip_sfc_option() {
    if grep -q "SkipSFC" "$SCRIPT_PATH"; then
        print_result "SkipSFC parameter exists" "PASS" ""
        return 0
    else
        print_result "SkipSFC parameter exists" "FAIL" "SkipSFC not found"
        return 1
    fi
}

test_reboot_prompt() {
    if grep -q "Restart-Computer" "$SCRIPT_PATH"; then
        print_result "Reboot functionality present" "PASS" ""
        return 0
    else
        print_result "Reboot functionality present" "FAIL" "No Restart-Computer found"
        return 1
    fi
}

####################################################################################################
# Run All Tests
####################################################################################################

echo "=========================================="
echo "Windows-System-Repair.ps1 Test Suite"
echo "=========================================="
echo ""

echo -e "${BLUE}Running Basic Script Tests...${NC}"
test_script_exists
test_powershell_extension
test_synopsis_present
test_description_present
test_examples_present
echo ""

echo -e "${BLUE}Running Parameter Tests...${NC}"
test_cmdletbinding
test_parameters_defined
test_logpath_parameter
echo ""

echo -e "${BLUE}Running Function Tests...${NC}"
test_administrator_check_function
test_logging_function
test_dism_function
test_sfc_function
test_summary_function
test_color_output_function
echo ""

echo -e "${BLUE}Running Command Tests...${NC}"
test_dism_command
test_dism_arguments
test_sfc_command
test_sfc_arguments
echo ""

echo -e "${BLUE}Running Error Handling Tests...${NC}"
test_error_action_preference
test_try_catch_blocks
test_exit_code_checking
echo ""

echo -e "${BLUE}Running Logging Tests...${NC}"
test_log_file_creation
test_timestamp_logging
test_add_content_logging
echo ""

echo -e "${BLUE}Running User Interaction Tests...${NC}"
test_confirmation_prompt
test_write_host_output
test_color_coding
echo ""

echo -e "${BLUE}Running Security Tests...${NC}"
test_admin_privilege_check
test_requires_elevation
echo ""

echo -e "${BLUE}Running Feature Tests...${NC}"
test_skip_dism_option
test_skip_sfc_option
test_reboot_prompt
echo ""

# Print summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
echo "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"
echo ""

# Exit with appropriate code
if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    echo ""
    echo -e "${YELLOW}NOTE: This validates script structure only.${NC}"
    echo -e "${YELLOW}To test PowerShell syntax on Windows, run:${NC}"
    echo -e "${YELLOW}  PowerShell -Command \"Get-Command -Syntax -Name .\\Windows-System-Repair.ps1\"${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
