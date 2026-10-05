# Manual device acceptance

Record the actual Mac model, CPU family, macOS version, release ZIP checksum and result. The automated acceptance path creates real Touch Bar items and calls their native handlers; it does not synthesize fingers.

- [ ] Download/extract the release, inspect first-open behavior and launch the app.
- [ ] Adopt/rename a pet, care, finish a round, quit and reopen; check identity, XP, coins, accessory and best score.
- [ ] Set Touch Bar to App Controls; bring this app to the foreground. Confirm the normal Control Strip remains usable.
- [ ] Open the Pati popover; use feed/wash/cuddle/rest and select each mini game.
- [ ] Touch/drag across the full playable width. Confirm target coordinates match the finger location and edges remain reachable.
- [ ] Choose Follow; tap near/far destinations and drag continuously. Verify walk/run, direction, animated paws and full-width travel.
- [ ] Choose Ball/Bone; tap or drag-release a throw. Verify flight, chase, pickup, visible carrying and return to the launch point.
- [ ] Choose Place food; tap both strip edges. Verify arrival, lowered eating head, diminishing food and a single saved meal after eating.
- [ ] Cancel a pending meal/fetch using Escape or Rest; confirm no meal/reward was saved.
- [ ] Catch stars, time rally input and repeat memory pads on physical hardware. Check debounce and small target readability.
- [ ] Switch apps/minimize while a round runs; ensure it pauses and explicitly resumes without a timer jump.
- [ ] Cycle all five worlds from the Touch Bar; choose lighting/weather/decor in Paw World. Confirm the matching scenes and readable targets.
- [ ] Run Fetch Dash with ball and bone, replace an unfinished throw, pause/resume and hit the deadline. Verify completion-only +3/+5 scoring.
- [ ] Earn an adventure reward, buy/equip decor, quit/reopen and confirm world, wallet, ownership, chapter and badge continuity.
- [ ] With an exported version-1 fixture, close the old app, migrate in 1.2 and verify old progress plus raw previous revision.
- [ ] Rest, quit, wait and reopen. Confirm bounded catch-up and retained progress.
- [ ] Export JSON, restore into a temporary macOS user profile and reopen. Avoid destructive tests on a real save.
- [ ] With a backed-up temporary test save, corrupt the primary; explicitly recover and verify raw recovery copy.
- [ ] Use every desktop flow with keyboard/VoiceOver. Verify labels, focus and feedback; automated checks are not a complete accessibility audit.
- [ ] Enable Reduce Motion and confirm decorative animation/autonomous roaming stop, while explicit follow/fetch/feed still completes.
- [ ] Check an Intel Touch Bar Mac and a native Apple Silicon Mac independently. Window play covers Macs without physical Touch Bar.

No physical-device session is claimed until a result is recorded. macOS 11 is a deployment target; every OS/model combination has not been exercised.
