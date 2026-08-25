# Changelog

## 1.1.2 - 2026-08-25

- Removed the full double-click wait from single-click speech; the first click now responds immediately.
- Relayed owned drag gestures back through Codex's native pointer pipeline so running-left/right animation follows the mouse.
- Coalesced relayed drag moves to a 60 Hz cadence to prevent pointer-message backlog and release-time snapping.
- Added explicit drag-complete events and immediate drag dialogue while retaining bounded lost-release protection.

## 1.1.1 - 2026-08-25

- Fixed fast physical clicks being discarded when low-level hook down/up records landed in adjacent polling batches.
- Kept lost-release protection with a bounded 250 ms hook-native pairing window and runtime diagnostics.
- Made the status probe portable across Codex-bundled PowerShell and standard Windows PowerShell hosts.

## 1.1.0 - 2026-08-25

- Added 20 short film- and meme-inspired lines; fixed dialogue count is now 100.
- Replaced the basketball emoji with a font-stable 牛 badge.
- Rebuilt the speech UI as a warm “牛来签” note card with category labels.
- Added per-monitor work-area and DPI-aware width, type size, height, and placement.
- Matched the native hook and fallback click jitter threshold for touchpads and high-DPI laptops.
- Added portable GitHub metadata and runtime-state exclusions.

## 1.0.0 - 2026-08-21

- Initial Codex v2 pet, animated 8 × 11 atlas, click bridge, speech overlay, installer, and 80 fixed lines.
