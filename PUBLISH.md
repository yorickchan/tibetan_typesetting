# Publishing a Release to GitHub

Releases are built and published automatically by
`.github/workflows/release.yml` when a `v*` tag is pushed. The macOS DMG is
signed with a Developer ID Application certificate and notarized (see
`RELEASE_GUIDE.md` for the required secrets), and the release body is taken
from the matching `## [X.Y.Z]` section of `RELEASE_NOTES.md`.

## Standard Release Flow

```bash
# 1. Bump the version in pubspec.yaml (e.g. 1.2.0+23)
# 2. Add a "## [X.Y.Z] - YYYY-MM-DD" section at the top of RELEASE_NOTES.md
# 3. Update README.md / README.zh-TW.md version badges if needed
# 4. Commit everything, then tag and push
git tag vX.Y.Z
git push origin master vX.Y.Z
```

The workflow builds macOS (DMG), Windows (ZIP), and Linux (tar.gz), then
creates the GitHub Release with the extracted notes. CI (`.github/workflows/ci.yml`)
runs `flutter analyze` and `flutter test` on every push to `master` and on
pull requests.

## Quick Manual Alternatives

### GitHub CLI

```bash
gh release create vX.Y.Z \
  tibetan-typesetting-macos.dmg \
  --title "Tibetan Typesetting vX.Y.Z" \
  --notes-file release_notes_body.md
```

### GitHub Web

1. Go to <https://github.com/yorickchan/tibetan_typesetting/releases/new>
2. Choose the existing `vX.Y.Z` tag (pushed above)
3. Paste the `## [X.Y.Z]` section from `RELEASE_NOTES.md`
4. Upload the artifacts and click **Publish release**

## After Publishing

- Point users at the release page:
  <https://github.com/yorickchan/tibetan_typesetting/releases/latest>
- Verify the macOS DMG signature if signing secrets changed:
  `codesign --verify --verbose=2 tibetan-typesetting-macos.dmg && xcrun stapler validate tibetan-typesetting-macos.dmg`

## Tips

- Tag format matters: always `vX.Y.Z`, matching the `pubspec.yaml` version.
- Use `--prerelease` (CLI) or the pre-release checkbox (web) for betas.
- Keep release notes user-focused; CI copies them verbatim into the release.
