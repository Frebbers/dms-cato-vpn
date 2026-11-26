# Cato VPN – DMS widget

DankMaterialShell bar widget for the Cato SDP client (`cato-sdp`).

- Bar pill shows connection status (polls `cato-sdp status` every 5s)
- Popout: PoP, tunnel IP, uptime, and Connect/Reconnect, Disconnect, Update buttons
- Update runs `cato-sdp update; cato-sdp start`, since updating drops the tunnel

## Install

    git clone <repo-url> ~/.config/dms/plugins/catoVpn
    dms restart
    dms ipc call plugins enable catoVpn

Then add "Cato VPN" under Settings → Dank Bar → Widgets.

Requires `cato-sdp` in `PATH`.
