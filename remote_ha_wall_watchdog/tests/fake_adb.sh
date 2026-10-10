#!/usr/bin/env bash
set -u

args="$*"
case "${args}" in
    keygen*) touch "$2" ;;
    start-server) ;;
    connect*) ;;
    *get-state*) echo device ;;
    *"shell pm path"*) echo "package:/data/app/example/base.apk" ;;
    *"shell pidof cloud.shelly.stargate"*) echo 1000 ;;
    *"shell pidof"*) ;;
    *"shell cat /proc/uptime"*) echo "600.00 100.00" ;;
    *"shell dumpsys activity activities"*)
        foreground="${WATCHDOG_FAKE_FOREGROUND-cloud.shelly.stargate/.activities.MainActivity}"
        if [[ -n "${foreground}" ]]; then
            echo "mResumedActivity: ActivityRecord{abc u0 ${foreground} t1}"
        fi
        ;;
    *"shell dumpsys package"*)
        echo "User 0: installed=true hidden=false stopped=true enabled=0"
        ;;
    *"shell am start"*)
        printf '%s\n' "${args}" >>"${WATCHDOG_FAKE_LOG}"
        ;;
    *)
        echo "Unexpected fake adb invocation: ${args}" >&2
        exit 1
        ;;
esac
