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

"${test_dir}/../watchdog.sh" \
    192.168.50.62 \
    5555 \
    com.laemcasa.remote_ha_wall \
    .MainActivity \
    0 \
    120 \
    2 \
    0

grep -q \
    'shell am start -W -n com.laemcasa.remote_ha_wall/.MainActivity' \
    "${WATCHDOG_FAKE_LOG}"

echo "watchdog recovery test passed"
