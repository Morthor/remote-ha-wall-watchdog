#!/usr/bin/env bash
set -euo pipefail

test_dir="$(cd "$(dirname "$0")" && pwd)"
work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT

chmod 0755 "${test_dir}/fake_adb.sh"
export WATCHDOG_ADB_BIN="${test_dir}/fake_adb.sh"
export WATCHDOG_DATA_DIR="${work_dir}/data"
export WATCHDOG_FAKE_LOG="${work_dir}/launches.log"
export WATCHDOG_MAX_CHECKS=2
export WATCHDOG_SHELLY_HANDOFF_DELAY_SECONDS=0

"${test_dir}/../watchdog.sh" \
    192.0.2.10 \
    5555 \
    com.laemcasa.remote_ha_wall \
    .MainActivity \
    0 \
    120 \
    2 \
    0

grep -q \
    'shell am start -W -n cloud.shelly.stargate/.activities.SplashActivity' \
    "${WATCHDOG_FAKE_LOG}"
grep -q \
    'shell am start -W -n com.laemcasa.remote_ha_wall/.MainActivity' \
    "${WATCHDOG_FAKE_LOG}"

test "$(sed -n '1p' "${WATCHDOG_FAKE_LOG}")" = \
    '-s 192.0.2.10:5555 shell am start -W -n cloud.shelly.stargate/.activities.SplashActivity'
test "$(sed -n '2p' "${WATCHDOG_FAKE_LOG}")" = \
    '-s 192.0.2.10:5555 shell am start -W -n com.laemcasa.remote_ha_wall/.MainActivity'

echo "watchdog recovery test passed"

: >"${WATCHDOG_FAKE_LOG}"
export WATCHDOG_FAKE_FOREGROUND="com.android.settings/.Settings"
"${test_dir}/../watchdog.sh" \
    192.0.2.10 \
    5555 \
    com.laemcasa.remote_ha_wall \
    .MainActivity \
    0 \
    120 \
    2 \
    0
test ! -s "${WATCHDOG_FAKE_LOG}"
echo "settings foreground safety test passed"

: >"${WATCHDOG_FAKE_LOG}"
export WATCHDOG_FAKE_FOREGROUND=""
"${test_dir}/../watchdog.sh" \
    192.0.2.10 \
    5555 \
    com.laemcasa.remote_ha_wall \
    .MainActivity \
    0 \
    120 \
    2 \
    0
test ! -s "${WATCHDOG_FAKE_LOG}"
echo "unknown foreground safety test passed"
