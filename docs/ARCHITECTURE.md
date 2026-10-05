# Architecture

`PetCore` contains the Codable archive, validated care/progression rules, daily calendar state, deterministic mini-game sessions, `CompanionWorld`, `PlaygroundProgress`, `FetchRound` and persistence store. It imports Foundation only. `TouchBarPet` provides native AppKit controls, original vector drawing, one desktop strip and real public `NSTouchBar` items. There are no external Swift packages.

The habitat and both `PetRailView` surfaces invoke `PetController.input`. The controller dispatches normalized positions to `CompanionWorld` at home and `GameSession` during the original mini games. Fetch Dash runs the same live companion with a separate active timer and captured throw target. All views render shared state. Care and toy popovers use the same handlers as desktop buttons; a completed world event is persisted through existing care rules. `SceneArt.swift` renders shared environments; `WorldPanel.swift` drives scene/purchase/quest transactions. `LivingArt.swift` draws the moving character and objects without raster dependencies. `NSTouchBar` belongs to the frontmost app's responder chain; private global replacement APIs are not used.

All archive changes are copy/validate/write/commit transactions. The UI keeps the old archive when persistence fails. Completed rounds and finished companion interactions remain available for settlement retry. Running rounds, walking positions and unfinished interactions are in memory only; version-2 saves add validated environment, ownership, lifetime counters, ordered chapter claims and bounded challenge receipts. A 30 Hz timer advances/paints the foreground world; background and minimized windows do not advance it. Focus loss pauses short games. Archive time catches up periodically and on actions/quit. No timer needs to run while the app is closed.

## Save and recovery

The native app opens Application Support/TouchBarPet for the signed-in macOS user. `pet.json` is the primary, `pet.previous.json` the prior valid revision. Writes are atomic and records use permission 0600 (directory 0700). This is local file access control, not encryption.

Loads and imports limit file size before reading, require a regular file, decode a known version and validate every field before use. Names, finite needs, timestamps, currency, calendar dates, bounded journals, reward receipts and known game keys are checked. A corrupt primary puts the app in protected mode. A valid previous revision can be previewed, but replacing the primary requires explicit recovery. Existing raw primary data is copied to a unique recovery file before replacement.

Import validates first and replaces the pet only after user confirmation. No merge semantics are implied. Portable JSON exports contain the same complete archive. Recent journal entries are bounded at 40; completed-round receipts at 100. Saves are editable local records, not a tamper-resistant economy.

Packaging compiles x86_64 and arm64 with a macOS 11 target, combines the executable with lipo, creates the shared vector icon, ad-hoc signs the bundle and runs its acceptance entry point before making a ZIP. ZIP metadata preserves Unix executable modes. Developer ID notarization is a separate future distribution step.

## Migration and completed fetch retry

A missing playground field is accepted only in a version-1 archive, then migrated in memory to a version-2 archive with zero new statistics. Existing pet fields retain their values. First saving rotates the exact legacy primary bytes into the previous revision. Version-2 missing/invalid world data and unknown versions are rejected. Migration is forward-only; older apps must be closed before opening the new one.

Challenge targets are captured when a throw launches. Only a completed return yields points; a replacement overwrites the attempt without an award. At the deadline unfinished travel is cancelled. A failed write keeps both the completed world event and scored candidate round; retries apply the archive and score together after a successful write, preserving a subsequent pause. Challenge and mini-game receipts are each bounded to 100. These local receipts prevent accidental repeated settlement of recent rounds, not tampering with editable saves.
