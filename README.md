# Cato VPN – DMS widget

DankMaterialShell bar widget for the Cato SDP client (`cato-sdp`).

- Bar pill shows connection status (polls `cato-sdp status` every 5s)
- Popout: PoP, tunnel IP, uptime, and Connect/Reconnect, Disconnect, Update buttons
- Update runs `cato-sdp update; cato-sdp start`, since updating drops the tunnel

## Install

Clone the repo anywhere, then link (or copy) it into the DMS plugins directory:

    git clone https://github.com/Frebbers/dms-cato-vpn && cd dms-cato-vpn
    ln -s . ~/.config/dms/plugins/catoVpn   # or: cp -r
    dms restart
    dms ipc call plugins enable catoVpn

The plugin directory must be readable as `catoVpn` (matching the plugin `id`).
With a symlink, `git pull` updates the plugin; reload it with
`dms ipc call plugins reload catoVpn`.

Then add "Cato VPN" under Settings → Dank Bar → Widgets.

Requires `cato-sdp` in `PATH`.
