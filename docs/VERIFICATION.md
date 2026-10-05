# Verification record

The release is checked using deterministic core rules, native AppKit controls, local save reopen, corrupt-record recovery and packaged-app acceptance. The acceptance harness uses temporary fictional records and never opens or replaces the live user's pet archive.

Local Intel validation for 1.2.0: 180 core checks and 73 AppKit integration checks passed. The screenshot harness exports Turkish/English desktop and Paw World views, five environment snapshots, a live challenge strip, a 360-frame living playground GIF and a 300-frame five-world GIF. Test counts describe exercised assertions, not device coverage.

Core coverage: adoption/name validation; free care, optional treat and bounded rewards; no-death catch-up and backward clocks; rest/level/accessories; once-per-day gift and once-per-round payout; all three mini games, pause/input/time bounds; complete JSON reopen, size limits, regular-file restrictions, previous revision, explicit raw recovery and failed write behavior.

Interactive coverage: gradual touch following, walk/run selection, facing, coordinate/time bounds, autonomous roaming, reduced-motion behavior, toy flight/chase/pickup/return, eating before settlement, once-only completion, cancellation and sleeping. AppKit coverage adds physical toy-menu callbacks, synchronized habitat/strip positions, real fetch/food handlers, delayed saving, failed-save retry and retry deduplication to existing native control/game/save checks. Screenshots and animation are rendered from these actual views with fictional records.

Native CI runs on Intel and arm64 Mac hosts. Universal packaging verifies both executable slices, the ad-hoc signature, bundle launch, PNG icon assets, ZIP paths/permissions and checksum. The public release download is verified after publication.

Version-2 coverage adds byte-preserving version-1 migration, rejection of missing/ambiguous new fields, cosmetic purchase rollback and free re-equipping, ordered one-time adventure claims, lifetime/badge continuity, bounded challenge input/time, completion-only aim scoring, pause, deadline cancellation, persistent best scores/receipts, synchronized scene selectors, actual Touch Bar world/challenge callbacks and completed-return retry after storage repair. The retry check also verifies that a pause occurring after a failed write is preserved.

Physical finger sensitivity, complete VoiceOver operation and every older macOS/device combination remain manual checks. Cross-compiling arm64 alone is not treated as native arm64 acceptance. This release is ad-hoc signed, not Apple notarized.
