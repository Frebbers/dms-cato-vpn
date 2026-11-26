import QtQuick
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.DCommon.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    layerNamespacePlugin: "cato-vpn"

    // "connected" | "disconnected" | "other" | "unknown"
    property string vpnState: "unknown"
    property string rawState: ""
    // "" | "connecting" | "disconnecting" | "updating"
    property string busy: ""
    property var info: ({})
    property string lastError: ""

    readonly property bool connected: vpnState === "connected"
    readonly property string statusText: {
        if (busy === "connecting") return "Connecting…";
        if (busy === "disconnecting") return "Disconnecting…";
        if (busy === "updating") return "Updating…";
        if (connected) return "Connected";
        if (vpnState === "disconnected") return "Disconnected";
        if (vpnState === "other") return rawState.replace("STATE_", "").toLowerCase();
        return "Unknown";
    }
    readonly property string statusIcon: busy !== "" ? "sync" : (connected ? "vpn_lock" : (vpnState === "disconnected" ? "vpn_key_off" : "help"))
    readonly property color statusColor: busy !== "" ? Theme.warning : (connected ? Theme.primary : (vpnState === "disconnected" ? Theme.error : Theme.surfaceVariantText))

    function parseStatus(text) {
        const kv = {};
        for (const line of text.split("\n")) {
            const m = line.match(/^\s*([\w ]+?)\s*=\s*(.*?)\s*$/);
            if (m) kv[m[1]] = m[2].replace(/^"|"$/g, "");
        }
        info = kv;
        if (/disconnected/i.test(text)) {
            vpnState = "disconnected";
        } else if (kv["state"] === "STATE_AUTHENTICATED") {
            vpnState = "connected";
        } else if (kv["state"]) {
            vpnState = "other";
            rawState = kv["state"];
        } else {
            vpnState = "unknown";
        }
    }

    function refresh() {
        if (!statusProc.running) statusProc.running = true;
    }

    function run(kind, script) {
        if (busy !== "") return;
        busy = kind;
        lastError = "";
        actionProc.command = ["sh", "-c", script];
        actionProc.running = true;
    }

    function connect() { run("connecting", "cato-sdp start"); }
    function reconnect() { run("connecting", "cato-sdp stop; cato-sdp start"); }
    function disconnect() { run("disconnecting", "cato-sdp stop"); }
    // update drops the tunnel, so always bring it back up afterwards
    function update() { run("updating", "cato-sdp update; cato-sdp start"); }

    Process {
        id: statusProc
        command: ["cato-sdp", "status"]
        stdout: StdioCollector {
            onStreamFinished: root.parseStatus(text)
        }
    }

    Process {
        id: actionProc
        stdout: StdioCollector {
            id: actionOut
        }
        stderr: StdioCollector {
            id: actionErr
        }
        onExited: exitCode => {
            const kind = root.busy;
            root.busy = "";
            if (exitCode !== 0) {
                root.lastError = (actionErr.text || actionOut.text).trim().split("\n").slice(-2).join(" ");
                ToastService.showError("Cato VPN: " + kind + " failed");
            }
            root.refresh();
        }
    }

    Timer {
        interval: 5000
        running: root.surfaceLive
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DIcon {
                name: root.statusIcon
                size: root.iconSize
                color: root.statusColor
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.statusText
                font.pixelSize: root.textSize
                color: root.statusColor
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        DIcon {
            name: root.statusIcon
            size: root.iconSize
            color: root.statusColor
        }
    }

    popoutWidth: 380
    popoutHeight: 0

    popoutContent: Component {
        PopoutComponent {
            headerText: "Cato VPN"
            detailsText: root.statusText
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingM

                Column {
                    width: parent.width
                    spacing: Theme.spacingXS
                    visible: root.connected

                    Repeater {
                        model: [
                            { k: "PoP", v: root.info["pop name"] },
                            { k: "Tunnel IP", v: root.info["tunnel ip"] },
                            { k: "Uptime", v: root.info["duration"] }
                        ]
                        delegate: Row {
                            required property var modelData
                            visible: !!modelData.v
                            width: parent.width
                            spacing: Theme.spacingS

                            StyledText {
                                width: 90
                                text: modelData.k
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                            }
                            StyledText {
                                text: modelData.v || ""
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                            }
                        }
                    }
                }

                StyledText {
                    width: parent.width
                    visible: root.lastError !== ""
                    text: root.lastError
                    wrapMode: Text.WordWrap
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.error
                }

                Flow {
                    width: parent.width
                    spacing: Theme.spacingS

                    DButton {
                        text: root.connected ? "Reconnect" : "Connect"
                        iconName: root.connected ? "refresh" : "power_settings_new"
                        enabled: root.busy === ""
                        onClicked: root.connected ? root.reconnect() : root.connect()
                    }

                    DButton {
                        text: "Disconnect"
                        iconName: "link_off"
                        variant: "tonal"
                        enabled: root.busy === "" && root.vpnState !== "disconnected"
                        onClicked: root.disconnect()
                    }

                    DButton {
                        text: "Update"
                        iconName: "system_update_alt"
                        variant: "tonal"
                        enabled: root.busy === ""
                        onClicked: root.update()
                    }
                }
            }
        }
    }
}
