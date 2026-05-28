# Free Text Block Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a separate free-text block format that renders small multiline Chinese or English content while leaving existing small blocks unchanged.

**Architecture:** Add a persisted block format enum to `TextBlock`, then branch editor, layout, preview, and PDF behavior from that format. Existing `smallText` remains a legacy-independent display toggle for Tibetan blocks.

**Tech Stack:** Flutter, Dart model serialization, Flutter widget preview, `pdf` package export, existing `flutter test` coverage.

---

### Task 1: Model and Layout Tests

**Files:**
- Modify: `test/widget_test.dart`
- Modify: `lib/models/project.dart`
- Modify: `lib/utils/sample_layout.dart`

- [ ] Add failing tests for `TextBlockFormat.freeText` JSON round-trip, missing-format default, width estimation from `tibetan`, and compact row eligibility.
- [ ] Run `flutter test test/widget_test.dart --name TextBlock` and confirm the new format test fails before implementation.
- [ ] Implement `TextBlockFormat`, serialization, `isFreeText`, layout scoring, and compact-row handling.
- [ ] Re-run the focused tests and confirm they pass.

### Task 2: Editor UI

**Files:**
- Modify: `lib/pages/editor_page.dart`
- Modify: `lib/widgets/block_editor.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_zh.arb`
- Modify: `lib/l10n/app_zh_TW.arb`
- Modify: generated localization Dart files checked into `lib/l10n/`

- [ ] Add a toolbar toggle for free text that updates the selected block format.
- [ ] Show a single multiline free-text input for free-text blocks.
- [ ] Ensure pronunciation auto-fill and dictionary save still skip free-text blocks.

### Task 3: Preview and PDF Export

**Files:**
- Modify: `lib/widgets/sample_page.dart`
- Modify: `lib/services/pdf_service.dart`

- [ ] Render free text in preview with the translation font and small Chinese sizing.
- [ ] Skip Tibetan PNG rendering for free-text blocks during PDF pre-rendering.
- [ ] Render free text in PDF with the translation font and small Chinese sizing.

### Task 4: Verification

**Files:**
- Run-only verification

- [ ] Run `flutter test`.
- [ ] Run `flutter analyze`.
- [ ] Fix any issues introduced by the change and rerun failing commands.
