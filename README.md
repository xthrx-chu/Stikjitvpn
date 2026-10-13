# StikJITVPN

A source overlay for StikDebug that requests the installed StosVPN tunnel automatically before a JIT debug session starts.

## Important limitation

This repository is an integration/patch layer, not a complete copy of StikDebug or StosVPN. iOS VPNs require a signed Network Extension embedded in an app and a provisioned VPN profile. The patch **does not install or provision StosVPN by itself**. Install and configure a compatible StosVPN build on the device first; its VPN profile must be visible to the app. The default upstream StosVPN provider bundle ID is `com.stossy11.StosVPN.TunnelProv`, but your signed build may use a different ID.

## Apply the patch

On a Mac with Xcode (required to build iOS apps):

```sh
git clone https://github.com/StikDebug/StikDebug.git
cd StikDebug
python3 ../stikjitvpn/patch_stikdebug.py .
```

Replace `../stikjitvpn` with the path to this repository. The script edits `StikDebug/Device/JITEnableContext.swift` in place and is safe to rerun. Build/sign the resulting Xcode project as usual.

## Behaviour

- Before a JIT debug session, it looks for an enabled saved VPN configuration whose provider bundle ID identifies StosVPN.
- If the tunnel is disconnected, it calls `startVPNTunnel()` and waits briefly for the status to change.
- If the profile is missing, disabled, or cannot start, it logs a clear warning and continues with the normal StikDebug flow; the VPN issue will likely cause the JIT connection to fail.
- It never creates a VPN profile or bypasses iOS signing/entitlement requirements.

## CI

GitLab CI checks that the patch script compiles and its expected insertion points remain valid. A real iOS build still requires a macOS/Xcode environment and valid signing/provisioning for the Network Extension.

## Licensing

StikDebug is AGPL-3.0. StosVPN is MIT-licensed. Review and preserve the upstream licenses and notices when redistributing modified builds.
