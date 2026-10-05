# Contributing

Use Swift 5.7+ with a macOS SDK. Run `swift run PetRulesTests`, `swift run TouchBarPet --smoke-test --screenshots output/verification`, then `bash scripts/package.sh 1.0.0` for packaging changes.

Keep persistence and game rules independently testable. Any change to archive version or fields needs a compatible migration and real reopen/recovery checks. Never test corruption on a live pet. Preserve public Touch Bar APIs, both Mac CPU families, the window input alternative and honest hardware coverage.

For a bug report include the app version, Mac model/CPU, macOS version, steps and expected/actual result. Remove personal pet details from a shared backup. Do not claim adoption, user benefit or device coverage that was not measured.
