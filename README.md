# StikJITVPN

StikJITVPN is an integration patch for StikDebug. It requests that an **already installed and configured** StosVPN Network Extension connect before a StikDebug JIT/debug session starts.

## What this repository builds

The GitHub Actions workflow checks out upstream StikDebug, applies `patch_stikdebug.py`, builds an **unsigned IPA**, and uploads it as a workflow artifact. It runs on a GitHub repository that contains this repository's files. A GitLab repository alone does not execute GitHub Actions; mirror/push these files to GitHub to use that workflow.

## Device setup and limitations

- Install and configure a compatible StosVPN app/profile on the device first.
- The patch searches saved VPN profiles for a provider bundle ID containing `StosVPN` or `TunnelProv`, and waits briefly for connection before proceeding.
- This repository does **not** embed or provision StosVPN's Network Extension. iOS requires a correctly signed extension, Network Extension entitlements, and provisioning. An unsigned IPA is a build artifact, not directly installable/usable as a VPN-enabled app until it is signed appropriately.
- If no profile is available or the VPN fails to connect, StikDebug logs a warning and continues with its regular debug flow.
- This automation has not been confirmed on a physical device; a successful CI build does not prove that the VPN tunnel or JIT works on-device.

## Build from GitHub

1. Put this repository on GitHub (or mirror it there).
2. Open **Actions → Build StikJITVPN IPA → Run workflow**. Pushes to `main` also trigger a build.
3. Download the `StikJITVPN-unsigned-ipa` artifact from the completed run.
4. Sign it using your normal iOS sideloading workflow. For VPN functionality, signing/provisioning must also satisfy Apple's Network Extension requirements.

## Manual patch use

Clone upstream StikDebug, then run this repository's patch script against the cloned source root:

```sh
python3 patch_stikdebug.py /path/to/StikDebug
```

Then build the modified `StikDebug.xcodeproj` with Xcode.

## Licenses

StikDebug is AGPL-3.0. StosVPN is MIT-licensed. Preserve upstream license files and notices when redistributing modified source or builds.
