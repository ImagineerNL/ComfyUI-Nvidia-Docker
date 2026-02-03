#!/bin/bash

# https://github.com/mmaitre314/picklescan
# Security scanner detecting Python Pickle files performing suspicious actions.
#
# Installs picklescan and runs a scan.
# Outputs result to console and with commented info to a logfile in `dockerscripts` dir (overwrites)
#

set -e

error_exit() {
  echo -n "!! ERROR: "
  echo $*
  echo "!! Exiting script (ID: $$)"
  exit 1
}

source /comfy/mnt/venv/bin/activate || error_exit "Failed to activate virtualenv"

# We need both uv and the cache directory to enable build with uv
use_uv=true
uv="/comfy/mnt/venv/bin/uv"
uv_cache="/comfy/mnt/uv_cache"
if [ ! -x "$uv" ] || [ ! -d "$uv_cache" ]; then use_uv=false; fi

echo "== PIP3_CMD: \"${PIP3_CMD}\""
if [ "A$use_uv" == "Atrue" ]; then
  echo "== Using uv"
  echo " - uv: $uv"
  echo " - uv_cache: $uv_cache"
else
  echo "== Using pip"
fi

# 1. Install picklescan
CMD="${PIP3_CMD} picklescan"
echo "CMD: \"${CMD}\""
${CMD} || error_exit "Failed to install picklescan"

# 2. Run picklescan and log output
# Scanning entire /basedir due to some custom nodes putting models in their own custom_node app directory
# Modify `TARGET_DIR` as wished. Scan is quick enough to not cause noticable downtime.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/picklescan_output.txt"
TARGET_DIR="/basedir"

echo "== Running picklescan..."
echo " - Target: ${TARGET_DIR}"
echo " - Log: ${LOG_FILE}"

# --- Write Header to Log File ---
cat <<EOF > "${LOG_FILE}"
# Picklescan by MMaitre314 
# Security scanner detecting Python Pickle files performing suspicious actions.
# More info: https://github.com/mmaitre314/picklescan
# Default Scanning entire basedir due to some custom nodes putting models in their own custom_node app directory
# Modify as wished. Scan is quick enough to not cause noticable downtime.
# -------------------------------------
# Scan results; Scroll to end for summary:
#
EOF

# --- Run Scan , log to console and File ---
picklescan --path "${TARGET_DIR}" | tee -a "${LOG_FILE}" || error_exit "Failed to run picklescan"

# --- Append Footer to Log File ---
cat <<EOF >> "${LOG_FILE}"
# ------------------------
# You can (probably) safely ignore 'Warning: could not parse ...' messages.
# You shouldnt ignore 'infected' or 'dangerous globals' messages.
# No support given on this scan script; for scan issues visit the picklescan github
EOF

echo "saved scan results to ${LOG_FILE}"

exit 0