# Remote HA Wall Watchdog

Home Assistant app repository containing a conservative ADB watchdog for the
dedicated Remote HA Wall dashboard.

The watchdog reconnects to the Shelly Wall Display over the trusted household
LAN and starts the dashboard only when it has genuinely stopped. It will not
take over while Android Settings or another non-Shelly application is in the
foreground.

See the app's [documentation](remote_ha_wall_watchdog/DOCS.md) for installation
and configuration.
