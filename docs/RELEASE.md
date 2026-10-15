# Release preparation

## Validation record

On 2026-10-15, the project owner reported passing all 15 manual feature checks, including Google Docs and pointer scanning. The macOS/browser versions, zoom and display arrangement were not recorded in that report. This is a user-reported result, not a compatibility guarantee for every system.

Retain the [English](TESTING.md) and [Chinese](TESTING.zh-CN.md) checklists for regression testing after future code changes. Their blank checkboxes are reusable templates, not a record contradicting the reported pass.

## Before the first public upload

- MIT selected for code, documentation and the included AI-generated sprite atlas; see LICENSE.
- The owner confirmed permission to distribute and license the AI-generated sprites under MIT; see [artwork provenance](../ARTWORK.md). Reference files are excluded from Git.
- Review the proposed files for personal data. Build output, runtime state and dependencies are ignored.
- Record a version and the tested environment in the release description.
- Check the repository preview, setup links and both documentation languages.

The starter HTML pages work locally and can be served by GitHub Pages from the main branch root. Releases distribute source code; no signed or notarized app installer is included.

Clean-source validation: the source copy built successfully on macOS 26.6.2 (Apple Silicon). Native self-tests passed, including spelling, OCR coordinate mapping, target movement and returning home. This build check is separate from the owner’s manual feature results.
