#!/usr/bin/env python3
"""
Ricoh Bulk Configuration Script
================================
Logs into multiple Ricoh printers via Web UI and applies a configuration change.

Requirements:
    Python 3.8+  —  https://www.python.org/downloads/
    requests     —  run once: pip install requests

Usage:
    1. Fill in the CONFIGURATION block below.
    2. Create printer_ips.csv (one IP per line, see example below).
    3. Open a terminal / PowerShell and run:
           python ricoh_bulk_config.py
    4. Review ricoh_results.csv when complete.

CSV format (printer_ips.csv):
    192.168.1.10
    192.168.1.11
    192.168.1.12
"""

import requests
import csv
import logging
import time
import urllib3
from datetime import datetime

# Suppress SSL warnings (not used here since HTTP, but safe to have)
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

###############################################################################
# !! CONFIGURATION — FILL IN BEFORE RUNNING !!
###############################################################################

# --- Credentials ---
ADMIN_USERNAME  = "[ADMIN_USERNAME]"    # Ricoh web UI admin username
ADMIN_PASSWORD  = "[ADMIN_PASSWORD]"    # Ricoh web UI admin password

# --- Printer IP List ---
IP_LIST_FILE    = "printer_ips.csv"     # One IP address per line

# --- Target Setting ---
# The URL path and form data for the setting you want to change.
#
# HOW TO FIND THESE VALUES (takes ~2 minutes on any one printer):
#   1. Open Chrome/Edge and log into one printer: http://[PRINTER-IP]
#   2. Navigate to the page with the setting you want to change.
#   3. Press F12 to open Developer Tools → click the Network tab.
#   4. Make the change and click Save/Apply on the printer page.
#   5. In the Network tab, click the POST request that appears.
#   6. Under "Payload" or "Form Data" you'll see the field names and values.
#   7. Copy the path (e.g. /web/entry.cgi) → paste into SETTINGS_ENDPOINT below.
#   8. Copy the field names and values → paste into SETTINGS_PAYLOAD below.
#
SETTINGS_ENDPOINT = "[SETTINGS_ENDPOINT]"
# Example: "/web/entry.cgi"
# Example: "/setting/airprint.cgi"

SETTINGS_PAYLOAD = {
    "[FIELD_NAME_1]": "[NEW_VALUE_1]",
    "[FIELD_NAME_2]": "[NEW_VALUE_2]",
    # Add as many fields as the form requires.
    # Example:
    #   "dns_primary":   "10.0.0.1",
    #   "dns_secondary": "10.0.0.2",
    #   "apply":         "Apply",       # most Ricoh forms need a submit button field
}

# --- Timing ---
DELAY_BETWEEN_PRINTERS = 2      # Seconds to wait between printers (be gentle on the network)
REQUEST_TIMEOUT        = 15     # Seconds before giving up on a request

# --- Output ---
RESULTS_FILE = "ricoh_results.csv"

###############################################################################
# LOGIN PATHS — usually the same across Ricoh models, change if needed
###############################################################################

LOGIN_ENDPOINT  = "/web/entry.cgi"      # Standard Ricoh login path

LOGIN_PAYLOAD = {
    "userid":   ADMIN_USERNAME,
    "password": ADMIN_PASSWORD,
    "lang":     "en",                   # Language (en = English)
    "func":     "sys_login",            # Ricoh login action key
}

LOGOUT_ENDPOINT = "/web/entry.cgi"
LOGOUT_PAYLOAD  = {
    "func": "sys_logout",
}

###############################################################################
# LOGGING
###############################################################################

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[
        logging.FileHandler("ricoh_bulk_config.log"),
        logging.StreamHandler()
    ]
)
log = logging.getLogger(__name__)

###############################################################################
# CORE FUNCTIONS
###############################################################################

def validate_config():
    """Catch unfilled placeholders before running against 100+ printers."""
    errors = []
    if "[ADMIN_USERNAME]" in ADMIN_USERNAME:
        errors.append("ADMIN_USERNAME not set")
    if "[ADMIN_PASSWORD]" in ADMIN_PASSWORD:
        errors.append("ADMIN_PASSWORD not set")
    if "[SETTINGS_ENDPOINT]" in SETTINGS_ENDPOINT:
        errors.append("SETTINGS_ENDPOINT not set")
    for k, v in SETTINGS_PAYLOAD.items():
        if "[FIELD_NAME" in k or "[NEW_VALUE" in k:
            errors.append(f"SETTINGS_PAYLOAD still has placeholder: {k} = {v}")
    if errors:
        log.error("Configuration incomplete — fix these before running:")
        for e in errors:
            log.error(f"  !! {e}")
        return False
    return True


def load_ips(filepath):
    """Load printer IPs from CSV file (one IP per line, blank lines skipped)."""
    ips = []
    try:
        with open(filepath, newline="") as f:
            reader = csv.reader(f)
            for row in reader:
                if row and row[0].strip() and not row[0].strip().startswith("#"):
                    ips.append(row[0].strip())
        log.info(f"Loaded {len(ips)} printer IPs from {filepath}")
    except FileNotFoundError:
        log.error(f"IP list file not found: {filepath}")
    return ips


def process_printer(ip):
    """
    Log into one printer, apply the setting, log out.
    Returns: (success: bool, message: str)
    """
    base_url = f"http://{ip}"
    session  = requests.Session()
    session.headers.update({"User-Agent": "Mozilla/5.0"})

    # -- Step 1: Login --
    try:
        login_resp = session.post(
            f"{base_url}{LOGIN_ENDPOINT}",
            data=LOGIN_PAYLOAD,
            timeout=REQUEST_TIMEOUT,
            allow_redirects=True
        )
        login_resp.raise_for_status()
    except requests.exceptions.ConnectTimeout:
        return False, "Connection timed out — printer unreachable or wrong IP"
    except requests.exceptions.ConnectionError:
        return False, "Connection refused — printer offline or IP incorrect"
    except requests.exceptions.HTTPError as e:
        return False, f"HTTP error on login: {e}"
    except Exception as e:
        return False, f"Unexpected error on login: {e}"

    # Verify login succeeded (Ricoh redirects to main page, or returns error text)
    if "invalid" in login_resp.text.lower() or "error" in login_resp.text.lower():
        log.warning(f"  [{ip}] Login may have failed — check credentials")

    log.info(f"  [{ip}] Logged in")

    # -- Step 2: Apply setting --
    try:
        setting_resp = session.post(
            f"{base_url}{SETTINGS_ENDPOINT}",
            data=SETTINGS_PAYLOAD,
            timeout=REQUEST_TIMEOUT,
            allow_redirects=True
        )
        setting_resp.raise_for_status()
    except requests.exceptions.HTTPError as e:
        return False, f"HTTP error applying setting: {e}"
    except Exception as e:
        return False, f"Unexpected error applying setting: {e}"

    log.info(f"  [{ip}] Setting applied")

    # -- Step 3: Logout --
    try:
        session.post(
            f"{base_url}{LOGOUT_ENDPOINT}",
            data=LOGOUT_PAYLOAD,
            timeout=REQUEST_TIMEOUT
        )
    except Exception:
        pass    # Logout failure is non-critical

    session.close()
    return True, "Success"


def write_results(results):
    """Write per-printer results to CSV for the technician's records."""
    with open(RESULTS_FILE, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["IP Address", "Status", "Message", "Timestamp"])
        for row in results:
            writer.writerow(row)
    log.info(f"Results written to {RESULTS_FILE}")

###############################################################################
# MAIN
###############################################################################

def main():
    log.info("=" * 60)
    log.info("Ricoh Bulk Configuration Script")
    log.info(f"Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    log.info("=" * 60)

    # Validate config before touching any printers
    if not validate_config():
        log.error("Aborting — fix configuration and re-run.")
        return

    # Load IPs
    ips = load_ips(IP_LIST_FILE)
    if not ips:
        log.error(f"No IPs loaded from {IP_LIST_FILE}. Aborting.")
        return

    total   = len(ips)
    passed  = 0
    failed  = 0
    results = []

    # Process each printer
    for idx, ip in enumerate(ips, start=1):
        log.info(f"[{idx}/{total}] Processing {ip} ...")
        success, message = process_printer(ip)

        status = "SUCCESS" if success else "FAILED"
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        results.append([ip, status, message, timestamp])

        if success:
            passed += 1
            log.info(f"  [{ip}] ✓ {message}")
        else:
            failed += 1
            log.error(f"  [{ip}] ✗ {message}")

        # Brief pause between printers
        if idx < total:
            time.sleep(DELAY_BETWEEN_PRINTERS)

    # Summary
    log.info("=" * 60)
    log.info(f"Complete — {passed}/{total} succeeded, {failed}/{total} failed")
    log.info("=" * 60)

    write_results(results)

    if failed > 0:
        log.warning(f"{failed} printer(s) failed — review {RESULTS_FILE} for details")


if __name__ == "__main__":
    main()
