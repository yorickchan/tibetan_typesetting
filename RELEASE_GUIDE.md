# Release Guide

This guide explains how to create and publish releases for Tibetan Typesetting.
Publishing steps live in `PUBLISH.md`; this page covers the workflow, signing,
and troubleshooting.

## Quick Release Process

```bash
# 1. Bump the version in pubspec.yaml (e.g. 1.2.0+23)
# 2. Add a "## [X.Y.Z] - YYYY-MM-DD" section at the top of RELEASE_NOTES.md
# 3. Commit all changes, then tag and push
git tag vX.Y.Z
git push origin master vX.Y.Z
```

The workflow will:
- Build macOS (signed + notarized DMG), Windows (ZIP), and Linux (tar.gz)
- Extract the matching `## [X.Y.Z]` section of `RELEASE_NOTES.md` into the
  GitHub Release body
- Attach all build artifacts

CI (`.github/workflows/ci.yml`) runs `flutter analyze` and `flutter test` on
every push to `master` and on pull requests.

## Version Numbering

We use Semantic Versioning (semver): MAJOR.MINOR.PATCH

- **MAJOR**: Breaking changes (e.g., 2.0.0)
- **MINOR**: New features, backwards compatible (e.g., 1.1.0)
- **PATCH**: Bug fixes, backwards compatible (e.g., 1.0.1)

Update the version in `pubspec.yaml` before building:

```yaml
version: 1.0.0+1  # version+build_number
```

## GitHub Actions Workflow

The workflow file (`.github/workflows/release.yml`) handles:

1. **macOS Build**: Creates DMG/ZIP on macOS runner
2. **Windows Build**: Creates ZIP on Windows runner
3. **Linux Build**: Creates TAR.GZ on Linux runner
4. **Release Creation**: Automatically uploads all artifacts

### Triggering the Workflow

The workflow runs when:
- You push a tag starting with `v` (e.g., `v1.2.0`)
- You manually trigger it from GitHub Actions tab

### Manual Workflow Trigger

1. Go to your repository on GitHub
2. Click "Actions" tab
3. Select "Build and Release" workflow
4. Click "Run workflow"
5. Select branch and click "Run workflow"

## macOS Code Signing & Notarization (CI)

The macOS job signs the app with a **Developer ID Application** certificate and
notarizes the DMG when these repository secrets are configured. If
`MACOS_CERTIFICATE_P12` is absent, the job falls back to the existing unsigned
build, so forks and local runs still work.

| Secret | Value |
|---|---|
| `MACOS_CERTIFICATE_P12` | Base64-encoded `.p12` containing the Developer ID Application certificate **and private key** |
| `MACOS_CERTIFICATE_PASSWORD` | Password used when exporting the `.p12` |
| `MACOS_SIGNING_IDENTITY` | Optional. Exact identity, e.g. `Developer ID Application: Your Name (TEAMID)`. If omitted, the workflow uses the first Developer ID Application identity in the temporary keychain |
| `APPLE_ID` | Apple ID used for notarization |
| `APPLE_APP_SPECIFIC_PASSWORD` | App-specific password generated at appleid.apple.com |
| `APPLE_TEAM_ID` | Apple Developer team ID that owns the Developer ID certificate |

### Prepare the certificate

1. In [Apple Developer](https://developer.apple.com/account/resources/certificates)
   create a **Developer ID Application** certificate for the distributing team.
   An **Apple Development** certificate will not work for distribution or
   notarization.
2. Install the certificate in Keychain Access, then export the certificate
   **together with its private key** as `DeveloperID.p12` with a password.
3. Base64-encode it:

   ```bash
   base64 -i DeveloperID.p12 | pbcopy
   ```

4. In GitHub → **Settings → Secrets and variables → Actions**, add the secrets
   from the table above. `MACOS_SIGNING_IDENTITY` is optional but recommended;
   the workflow signs manually, so the Xcode project's `DEVELOPMENT_TEAM` is
   not used for the final signature.
5. Push a `v*` tag (or run the workflow manually). The macOS job:

   1. imports the `.p12` into a temporary `build.keychain`,
   2. re-signs the `.app` with hardened runtime and
      `macos/Runner/Release.entitlements`,
   3. signs the DMG,
   4. submits the DMG to `notarytool` and staples the ticket.

If the three notarization secrets are absent, the DMG is signed but not
notarized. Without any signing secrets, the workflow produces the same unsigned
DMG as before.

## Building Locally

### macOS
```bash
flutter build macos --release
# Output: build/macos/Build/Products/Release/Tibetan Typesetting.app
```

### Windows (Windows only)
```bash
flutter build windows --release
# Output: build/windows/x64/runner/Release/
```

### Linux (Linux only)
```bash
flutter build linux --release
# Output: build/linux/x64/release/bundle/
```

## Pre-Release Checklist

- [ ] Update version in `pubspec.yaml`
- [ ] Update `RELEASE_NOTES.md` with changes
- [ ] Test the app on target platform(s)
- [ ] Commit all changes
- [ ] Create and push version tag
- [ ] Verify GitHub Actions workflow completes
- [ ] Test downloaded artifacts
- [ ] Update README.md if needed

## Release Notes Template

See `RELEASE_NOTES.md` for the current release notes template. Update this file with:
- New features
- Bug fixes
- Breaking changes
- Known issues

## Distribution

### macOS
- **DMG** (preferred): Double-click installer
- **ZIP**: Extract and drag to Applications

### Windows
- **ZIP**: Extract and run `.exe`

### Linux
- **TAR.GZ**: Extract and run binary

## Code Signing

macOS signing and notarization run automatically when the secrets above are
configured. Optional further hardening:
- **Windows**: Sign with a code signing certificate
- **Linux**: Create packages (.deb, .rpm, AppImage)

## Troubleshooting

### GitHub Actions fails
- Check the Actions tab for error logs
- Ensure Flutter version is compatible
- Verify dependencies are correctly specified

### Build size too large
- Check for unnecessary assets
- Use `flutter build --release --split-debug-info=./debug-info --obfuscate`

### Permission issues on macOS
- Signed and notarized DMGs open without warnings; verify with
  `codesign --verify --verbose=2 app.dmg && xcrun stapler validate app.dmg`
- Unsigned builds require right-click → Open on first launch
