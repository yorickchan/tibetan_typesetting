# Release Guide

This guide explains how to create and publish releases for Tibetan Typesetting.

## Quick Release Process

### Option 1: Automatic Multi-Platform Build (Recommended)

The GitHub Actions workflow will automatically build for all platforms when you create a tag:

```bash
# 1. Commit all changes
git add .
git commit -m "Prepare release v1.0.0"

# 2. Create and push a version tag
git tag v1.0.0
git push origin main
git push origin v1.0.0
```

The workflow will:
- Build macOS, Windows, and Linux versions
- Create a GitHub release automatically
- Attach all build artifacts

### Option 2: Manual Release (Current Platform Only)

If you want to create a release manually for macOS only:

```bash
# 1. Build the macOS release
flutter build macos --release

# 2. Package as ZIP
cd build/macos/Build/Products/Release
zip -r ../../../../../tibetan-typesetting-macos-v1.0.0.zip tibetan_typesetting.app
cd ../../../../../

# 3. Create a GitHub release manually
# - Go to your repository on GitHub
# - Click "Releases" → "Create a new release"
# - Create a new tag (e.g., v1.0.0)
# - Upload the ZIP file
# - Copy content from RELEASE_NOTES.md
```

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
- You push a tag starting with `v` (e.g., `v1.0.0`)
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
# Output: build/macos/Build/Products/Release/tibetan_typesetting.app
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

## Code Signing (Optional)

For production releases, consider:
- **macOS**: Sign with Apple Developer certificate, notarize for Gatekeeper
- **Windows**: Sign with code signing certificate
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
- Users may need to right-click → Open on first launch
- Consider notarizing the app for smoother user experience
