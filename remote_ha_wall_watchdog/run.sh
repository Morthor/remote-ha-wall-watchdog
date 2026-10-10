#!/usr/bin/with-contenv bashio
set -u -o pipefail

panel_host="$(bashio::config panel_host)"
panel_port="$(bashio::config panel_port)"
package_name="$(bashio::config package_name)"
activity_name="$(bashio::config activity_name)"
check_interval="$(bashio::config check_interval_seconds)"
startup_grace="$(bashio::config panel_startup_grace_seconds)"
failed_checks="$(bashio::config failed_checks_before_launch)"
launch_cooldown="$(bashio::config launch_cooldown_seconds)"

bashio::log.info "Monitoring ${package_name} on ${panel_host}:${panel_port}."

exec /watchdog.sh \
    "${panel_host}" \
    "${panel_port}" \
    "${package_name}" \
    "${activity_name}" \
    "${check_interval}" \
    "${startup_grace}" \
    "${failed_checks}" \
    "${launch_cooldown}"
