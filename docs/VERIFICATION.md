# Verification record

The release is checked using deterministic core rules, native AppKit controls, local save reopen, corrupt-record recovery and packaged-app acceptance. The acceptance harness uses temporary fictional records and never opens or replaces the live user's pet archive.

Local Intel validation: 90 core checks and 27 AppKit integration checks passed. The screenshot harness exports Turkish/English desktop views and four real Touch Bar view previews. Test counts describe exercised assertions, not device coverage.

Core coverage: adoption/name validation; free care, optional treat and bounded rewards; no-death catch-up and backward clocks; rest/level/accessories; once-per-day gift and once-per-round payout; all three mini games, pause/input/time bounds; complete JSON reopen, size limits, regular-file restrictions, previous revision, explicit raw recovery and failed write behavior.

AppKit coverage: native Touch Bar creation, real feed/wash/game callbacks, shared strip state, round completion, automatic reward saving, daily button, sleeping/wake behavior, language preference, full progress reopen and guarded corrupt/failed writes. Screenshots are rendered from these actual views.

Native CI runs on Intel and arm64 Mac hosts. Universal packaging verifies both executable slices, the ad-hoc signature, bundle launch, PNG icon assets, ZIP paths/permissions and checksum. The public release download is verified after publication.

Physical finger sensitivity, complete VoiceOver operation and every older macOS/device combination remain manual checks. Cross-compiling arm64 alone is not treated as native arm64 acceptance. This release is ad-hoc signed, not Apple notarized.
