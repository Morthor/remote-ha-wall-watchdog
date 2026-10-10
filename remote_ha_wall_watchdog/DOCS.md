# Remote HA Wall Watchdog

This app watches the dedicated Shelly Wall Display over ADB and restores the
Remote HA Wall dashboard if Shelly's own software force-stops it.

## Requirements

- Home Assistant Green or another `aarch64` Home Assistant OS installation.
- The panel and Home Assistant must be on the same trusted LAN.
- Wireless ADB must remain enabled on the panel.
- Do not expose TCP port 5555 outside the trusted LAN.

## Behaviour

The watchdog never force-stops applications and never installs APKs. It waits
for the panel's boot grace period, confirms that the dashboard process is
missing for multiple checks, and launches it only while the Shelly launcher or
placeholder is in the foreground. Android Settings and other foreground apps
are left alone.

Recovery attempts are rate-limited. Logs are available from the app's Home
Assistant page.

## Default configuration

```yaml
panel_host: 192.168.50.62
panel_port: 5555
package_name: com.laemcasa.remote_ha_wall
activity_name: .MainActivity
check_interval_seconds: 30
panel_startup_grace_seconds: 120
failed_checks_before_launch: 2
launch_cooldown_seconds: 300
```

After installation, enable **Start on boot** and **Watchdog** on the app's Info
page. The first connection may require accepting an ADB authorization prompt on
the panel if wireless ADB authentication is enabled.
