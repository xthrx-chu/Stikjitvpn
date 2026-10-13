# StikJITVPN

This repository contains a rootless Theos jailbreak tweak package for StikDebug and a GitHub Actions workflow that builds a `.deb`.

## What it does

When the tweak is injected into the StikDebug app (`com.stik.stikdebug`), it looks for an already-installed Network Extension profile whose provider bundle ID contains `StosVPN` or `TunnelProv` and asks iOS to start that VPN profile.

**Important:** the current tweak triggers on StikDebug app launch, not at the exact instant JIT is requested. This is a practical first integration point; it does not hook StikDebug's private Swift JIT method. Logs are available in the device system log with the `[StikJITVPN]` prefix.

## Build the .deb on GitHub

1. Push or mirror this repository to GitHub.
2. Open **Actions → Build StikJITVPN Debian Package**.
3. Run the workflow, or push a commit to `main`.
4. Download the `StikJITVPN-deb` artifact from the completed run.

The workflow uses Theos and builds a **rootless** package for arm64/arm64e. A successful workflow is required before treating the package as build-verified.

## Install requirements

- A jailbroken iPhone/iPad compatible with rootless tweaks.
- Substitute or another compatible tweak injection system.
- StikDebug installed with bundle ID `com.stik.stikdebug`.
- StosVPN installed and its VPN configuration/profile already saved and enabled.

A `.deb` is **not** installable through ordinary SideStore on a non-jailbroken device. This tweak does not bundle StosVPN or bypass Apple's Network Extension signing, profile, or user-approval requirements.

## Source layout

- `Tweak.x`: Objective-C/Logos hook.
- `Makefile`: Theos build configuration.
- `control`: Debian package metadata.
- `StikJITVPNAutoStart.plist`: injection filter.
- `.github/workflows/build-deb.yml`: GitHub Actions build.

## License and upstream notices

StikDebug is AGPL-3.0 and StosVPN is MIT-licensed. This repository's tweak code is an integration layer and does not include upstream StikDebug or StosVPN source. Preserve relevant upstream notices when redistributing either upstream project.
