#!/usr/bin/with-contenv bash
set -euo pipefail

LOOPMI_APP_DIR="/app"
LOOPMI_BINARY="${LOOPMI_APP_DIR}/LoopMi.Edge"
LOG_DIR="/data/logs"
LOG_FILE="${LOG_DIR}/loopmi-edge.log"
CONFIG_DIR="/config/loopmi"
CONFIG_FILE="${CONFIG_DIR}/appsettings.json"
APPSETTINGS_FILE="${LOOPMI_APP_DIR}/appsettings.json"
PIPE_FILE="/tmp/loopmi-log.pipe"

mkdir -p /data "${LOG_DIR}" "${CONFIG_DIR}"

if [ ! -f "${LOOPMI_BINARY}" ]; then
    echo "LoopMi binary not found at ${LOOPMI_BINARY}. Stage published artifacts before building the add-on image."
    exit 1
fi

if [ ! -f "${CONFIG_FILE}" ] && [ -f "${APPSETTINGS_FILE}" ]; then
    cp "${APPSETTINGS_FILE}" "${CONFIG_FILE}"
fi

if [ -f "${CONFIG_FILE}" ]; then
    ln -sf "${CONFIG_FILE}" "${APPSETTINGS_FILE}"
fi

export ASPNETCORE_URLS="http://0.0.0.0:5034"
export Measurements__DatabasePath="/data/loopmi-edge.db"

if [ -p "${PIPE_FILE}" ]; then
    rm -f "${PIPE_FILE}"
fi

mkfifo "${PIPE_FILE}"
tee -a "${LOG_FILE}" < "${PIPE_FILE}" &

exec "${LOOPMI_BINARY}" > "${PIPE_FILE}" 2>&1
