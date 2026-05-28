# Free Text Block Design

## Goal

Add a new block format for small, multiline Chinese or English free text without changing the existing `smallText` behavior.

## Behavior

The new block format is separate from `TextBlock.smallText`. Existing normal and small blocks continue to load, edit, preview, and export as they do today.

Free text blocks use the existing main text field as their content source. Pronunciation and translation inputs are ignored for editing, dictionary auto-fill, preview, and PDF export. The free text may contain multiple lines and is rendered using the same small Chinese output size currently used by small blocks.

## Model

`TextBlock` gains a persisted format field. Missing format values default to normal so existing saved projects stay compatible.

## UI

The block toolbar gains a separate free-text format toggle. When a selected block is free text, the editor shows one multiline free-text input instead of Tibetan, pronunciation, and translation inputs.

## Rendering

Preview and PDF rendering skip Tibetan PNG generation for free text blocks and render only the main text content with the resolved translation font and small Chinese font size.

## Testing

Tests cover JSON round-trip compatibility, layout width estimation based on free text content, and row-height behavior for compact free-text rows.
