#!/usr/bin/env python3
"""Patch StikDebug to start an already-installed StosVPN profile before JIT."""

from pathlib import Path
import sys

BRIDGE = r'''
    /// Starts an already-installed StosVPN profile before opening a JIT debug session.
    /// Network Extension profiles must be installed and provisioned separately.
    private func ensureStosVPN(logger: LogFunc?) {
        let semaphore = DispatchSemaphore(value: 0)
        var managers: [NETunnelProviderManager] = []
        var loadError: Error?
        NETunnelProviderManager.loadAllFromPreferences { loaded, error in
            managers = loaded ?? []
            loadError = error
            semaphore.signal()
        }
        guard semaphore.wait(timeout: .now() + .seconds(4)) == .success else {
            emitLog("StosVPN warning: timed out loading VPN profiles; continuing without auto-start.", logger: logger)
            return
        }
        if let loadError {
            emitLog("StosVPN warning: could not load VPN profiles: \(loadError.localizedDescription)", logger: logger)
            return
        }

        guard let manager = managers.first(where: {
            let identifier = $0.protocolConfiguration as? NETunnelProviderProtocol
            let bundleID = identifier?.providerBundleIdentifier ?? ""
            return bundleID.localizedCaseInsensitiveContains("StosVPN")
                || bundleID.localizedCaseInsensitiveContains("TunnelProv")
        }) else {
            emitLog("StosVPN warning: no StosVPN VPN profile found. Install and configure StosVPN first.", logger: logger)
            return
        }
        guard manager.isEnabled else {
            emitLog("StosVPN warning: the saved StosVPN profile is disabled. Enable it in Settings and retry.", logger: logger)
            return
        }
        if manager.connection.status == .connected || manager.connection.status == .connecting {
            emitLog("StosVPN is already connected/connecting.", logger: logger)
            return
        }
        do {
            try manager.connection.startVPNTunnel()
            emitLog("StosVPN start requested before JIT.", logger: logger)
        } catch {
            emitLog("StosVPN warning: failed to start VPN: \(error.localizedDescription)", logger: logger)
        }
    }
'''

def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: patch_stikdebug.py /path/to/StikDebug", file=sys.stderr)
        return 2
    root = Path(sys.argv[1]).resolve()
    source = root / "StikDebug" / "Device" / "JITEnableContext.swift"
    if not source.is_file():
        print(f"Cannot find {source}. Pass the StikDebug repository root.", file=sys.stderr)
        return 2

    text = source.read_text()
    if "private func ensureStosVPN(logger: LogFunc?)" in text:
        print("StosVPN integration already present; no changes made.")
        return 0
    if "import NetworkExtension" not in text:
        marker = "import Foundation\n"
        if marker not in text:
            print("Could not find Foundation import insertion point.", file=sys.stderr)
            return 1
        text = text.replace(marker, marker + "import NetworkExtension\n", 1)

    marker = "    private func runDebugSession(\n"
    if marker not in text:
        print("Could not find runDebugSession insertion point; upstream source may have changed.", file=sys.stderr)
        return 1
    text = text.replace(marker, BRIDGE + "\n" + marker, 1)

    body_marker = "        do {\n            try withConnectedDebugSession { remoteServer, debugProxy in"
    if body_marker not in text:
        print("Could not find runDebugSession body insertion point; no file written.", file=sys.stderr)
        return 1
    text = text.replace(
        body_marker,
        "        ensureStosVPN(logger: logger)\n" + body_marker,
        1
    )
    source.write_text(text)
    print(f"Patched {source}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
