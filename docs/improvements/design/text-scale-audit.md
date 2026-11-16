# Text scale audit (Finding 8)

Date: 2026-11-16
Method: widget tests pumping HomeScope / login at EN+AR, scales **1.3** and **1.6**, widths **320** and **400**.

## Results

| Surface | EN 1.3 | EN 1.6 | AR 1.3 | AR 1.6 |
| --- | --- | --- | --- | --- |
| Home + bottom nav (320/400) | Pass | Pass | Pass | Pass* |
| Approvals | Pass | Pass | Pass | **Fail @320** → fixed |
| History | Pass | Pass | Pass | Pass |
| Profile | Pass | Pass | Pass | **Fail @320** → fixed |
| Login (320) | Pass | Pass | Pass | Pass |
| Portal large-text smoke (existing) | — | Pass | Pass | — |

\*Home itself did not throw at AR 1.6 / 320; action buttons sit below the fold and need `ensureVisible` (scroll), then remain hit-testable. Not treated as an overflow defect.

## Verified defects

1. **Approvals `_Header` Row** (`approvals_page.dart`)
   - **Repro:** AR, scale 1.6, width 320, open Approvals with pending items.
   - **Error:** `RenderFlex overflowed by 34 pixels on the right`.
   - **Cause:** Title `Expanded` + unconstrained `pendingCount` trailing `Text` (`"{count} قيد الانتظار"`). Trailing intrinsic width exceeded 280px content width.
   - **Fix:** Use existing `SplitRow` so the count is width-capped and can scale down; keep `pending-count` key.

2. **Profile `_BadgeField` Row** (`profile_page.dart`)
   - **Repro:** AR, scale 1.6, width 320, open Profile.
   - **Error:** `RenderFlex overflowed by 8.0 pixels on the right` (constraints width 232).
   - **Cause:** Unconstrained label `Text` beside `Expanded` value; long Arabic labels exceeded remaining width.
   - **Fix:** Give label and value shared flex (`Expanded` 2 / 3) with ellipsis; preserve end-aligned values.

## Hardening (no overflow thrown, accessibility)

3. **Approvals filter chips** — add `overflow: TextOverflow.ellipsis` on chip labels (chips already live in a horizontal scroller).

## Reverted during final verification

- **Home `_ActionLabel` maxLines: 2** — not required by a verified overflow (Home passed at 1.6). It broke `home_header_test` (“action labels stay complete…”, Record Expense must stay one line via `_recordExpenseLabelStyle`). Reverted to `maxLines: 1`.

## Global clamp

**Not applied.** After the Approvals header fix, audited screens pass at **1.6** without `MaterialApp` `textScaler.clamp`. No remaining overflow justified a product-wide accessibility restriction.

## Remaining limitations

- Very long translated strings in dense controls may still ellipsize (chips, badges); that is clipping by design, not a flex overflow.
- Physical-device checks at the OS largest text size (especially foldables / unusual fonts) are still recommended.
- Unused `PendingApprovalsSection` was not modified (not in the live Home tree).
