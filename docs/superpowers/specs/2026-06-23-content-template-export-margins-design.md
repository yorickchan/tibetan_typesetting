# Content Template Export Margins Design

## Goal

Make PDF exports use the same content rectangle as the content-template
preview when page margins and template insets differ.

## Layout Contract

Content-page settings have two independent geometries:

- The page margin defines the rectangle available to text blocks.
- The template inset defines where the custom SVG template is placed and how
  large it is.

The preview already follows this contract. PDF export must follow it for both
the first content page and subsequent content pages. Adding a template must
not replace the selected page margin with the template inset.

## Implementation

In `PdfService`, retain the zero PDF page margin required to draw the SVG over
the full physical page. Pass the configured content-page margin into the
content layout calculation, independently of the SVG template inset.

Use the page margin to calculate the content padding and grid width and height.
Use the template inset only to position and size `pw.SvgImage`. Do not apply
the legacy fixed two-millimeter vertical inset to templated content; the
content height must be exactly the page height less its configured top and
bottom margins.

## Validation

Extract or add a small pure layout helper that exposes the content and template
rectangles in PDF points. Unit-test a case where page margins and template
insets are intentionally different, proving that the content rectangle follows
the page margins while the SVG rectangle follows the template inset. Cover both
first-page and subsequent-page configurations through the same helper contract.

Run the focused test, the full Flutter test suite, and static analysis.
