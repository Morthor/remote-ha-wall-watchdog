#!/usr/bin/env bash
set -u -o pipefail

if [[ "$#" -ne 8 ]]; then
    echo "Usage: watchdog.sh HOST PORT PACKAGE ACTIVITY INTERVAL STARTUP_GRACE FAILED_CHECKS COOLDOWN" >&2
    exit 64
fi

panel_host="$1"
panel_port="$2"
package_name="$3"
activity_name="$4"
check_interval="$5"
startup_grace="$6"
failed_checks_before_launch="$7"
launch_cooldown="$8"

adb_bin="${WATCHDOG_ADB_BIN:-adb}"
data_dir="${WATCHDOG_DATA_DIR:-/data}"
max_checks="${WATCHDOG_MAX_CHECKS:-0}"
serial="${panel_host}:${panel_port}"
component="${package_name}/${activity_name}"
adb_key="${data_dir}/adbkey"

mkdir -p "${data_dir}"
if [[ ! -f "${adb_key}" ]]; then
    "${adb_bin}" keygen "${adb_key}" >/dev/null 2>&1 || true
fi
export ADB_VENDOR_KEYS="${adb_key}"

log() {
    printf '%s %s\n' "$(date -Iseconds)" "$*"
}

adb_device() {
    "${adb_bin}" -s "${serial}" "$@"
}

connect_panel() {
    "${adb_bin}" connect "${serial}" >/dev/null 2>&1 || true
    [[ "$(adb_device get-state 2>/dev/null || true)" == "device" ]]
}

foreground_component() {
    adb_device shell dumpsys activity activities 2>/dev/null |
        awk '/mResumedActivity/ {
            for (field_index = 1; field_index <= NF; field_index++) {
                if ($field_index ~ /\//) {
                    gsub(/[{}]/, "", $field_index)
                    print $field_index
                    exit
                }
            }
        }' |
        tr -d '\r'
}

foreground_allows_recovery() {
    case "$1" in
        cloud.shelly.stargate/* | cloud.shelly.placeholder/* | "") return 0 ;;
        *) return 1 ;;
    esac
}

package_stopped_state() {
    adb_device shell dumpsys package "${package_name}" 2>/dev/null |
        sed -n 's/.*stopped=\([^ ]*\).*/\1/p' |
        head -n 1 |
        tr -d '\r'
}

panel_uptime_seconds() {
    adb_device shell cat /proc/uptime 2>/dev/null |
        awk '{print int($1)}' |
        tr -d '\r'
}

"${adb_bin}" start-server >/dev/null 2>&1 || true

failed_checks=0
last_launch_epoch=0
checks=0
last_reported_state=""

while true; do
    checks=$((checks + 1))
    state="healthy"

    if ! connect_panel; then
        state="panel-unreachable"
        failed_checks=0
    elif [[ -z "$(adb_device shell pm path "${package_name}" 2>/dev/null || true)" ]]; then
        state="package-not-installed"
        failed_checks=0
    else
        panel_uptime="$(panel_uptime_seconds)"
        panel_uptime="${panel_uptime:-0}"
        process_id="$(adb_device shell pidof "${package_name}" 2>/dev/null | tr -d '\r' || true)"

        if [[ -n "${process_id}" ]]; then
            failed_checks=0
        elif ((panel_uptime < startup_grace)); then
            state="panel-starting"
            failed_checks=0
        else
            foreground="$(foreground_component)"
            stopped="$(package_stopped_state)"
            if ! foreground_allows_recovery "${foreground}"; then
                state="waiting-for-safe-foreground:${foreground}"
                failed_checks=0
            else
                state="dashboard-missing:stopped=${stopped:-unknown}"
                failed_checks=$((failed_checks + 1))
                now_epoch="$(date +%s)"
                since_last_launch=$((now_epoch - last_launch_epoch))
                if ((failed_checks >= failed_checks_before_launch)) &&
                    ((since_last_launch >= launch_cooldown)); then
                    log "Launching ${component}; ${state}."
                    if adb_device shell am start -W -n "${component}" >/dev/null 2>&1; then
                        last_launch_epoch="${now_epoch}"
                        failed_checks=0
                        state="launch-requested"
                    else
                        state="launch-failed"
                    fi
                fi
            fi
        fi
    fi

    if [[ "${state}" != "${last_reported_state}" ]]; then
        log "State: ${state}."
        last_reported_state="${state}"
    fi

    if ((max_checks > 0 && checks >= max_checks)); then
        exit 0
    fi
    sleep "${check_interval}"
done
