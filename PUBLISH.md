# Publishing a Release to GitHub

## Current Status

✅ **macOS build ready**: `tibetan-typesetting-macos-v1.0.0.zip` (59MB)  
✅ **GitHub Actions configured**: Automated multi-platform builds  
✅ **Release notes prepared**: `RELEASE_NOTES.md`

## Publishing Your Release

### Method 1: Using GitHub CLI (Fastest)

If you have GitHub CLI installed:

```bash
# Create a release with the macOS build
gh release create v1.0.0 \
  tibetan-typesetting-macos-v1.0.0.zip \
  --title "Tibetan Typesetting v1.0.0" \
  --notes-file RELEASE_NOTES.md
```

### Method 2: Using Git Tags + GitHub Actions (All Platforms)

This will automatically build all platforms:

```bash
# 1. Make sure all changes are committed
git add .
git commit -m "Release v1.0.0"

# 2. Create and push the tag
git tag v1.0.0
git push origin main
git push origin v1.0.0
```

Then:
1. Go to your repository: https://github.com/yorickchan/tibetan_typesetting
2. Click "Actions" tab
3. Wait for "Build and Release" workflow to complete (~10 minutes)
4. Go to "Releases" and edit the auto-created release to add description

### Method 3: Manual Upload via GitHub Web

1. Go to: https://github.com/yorickchan/tibetan_typesetting/releases/new
2. Click "Choose a tag" → Type `v1.0.0` → "Create new tag"
3. Set release title: `Tibetan Typesetting v1.0.0`
4. Copy content from `RELEASE_NOTES.md` into description
5. Drag and drop `tibetan-typesetting-macos-v1.0.0.zip`
6. Click "Publish release"

## After Publishing

### Update README.md

Add installation instructions linking to the latest release:

```markdown
## Download

Download the latest release for your platform:
- [macOS](https://github.com/yorickchan/tibetan_typesetting/releases/latest)
- [Windows](https://github.com/yorickchan/tibetan_typesetting/releases/latest)
- [Linux](https://github.com/yorickchan/tibetan_typesetting/releases/latest)
```

### Announce

Consider announcing your release:
- Repository README
- Project website/blog
- Social media
- Relevant communities

## Future Releases

For subsequent releases:

1. Update version in `pubspec.yaml`
2. Update `RELEASE_NOTES.md` with changes
3. Follow one of the methods above with new version number
4. Consider keeping old releases available for users

## Tips

- Use **pre-releases** for beta testing: Add `--prerelease` flag to gh command
- Create **draft releases** to prepare before publishing
- Tag format matters: Always use `vX.Y.Z` format for auto-trigger
- Keep release notes clear and user-focused
