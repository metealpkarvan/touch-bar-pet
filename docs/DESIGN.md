# Design: a companion you can return to

Pati Cepte uses a narrow strip as a shared playground rather than a dashboard of tiny menus. A desktop habitat introduces the pet and makes needs, currency and goals readable. The physical and window strips draw the same character and use the same input path.

The original visual system combines warm paper, apricot/cocoa/cloud fur, muted green foliage and five original worlds. The living side-view character has species-specific ears, four articulated paws, turning, tail movement, blinking, an eating pose and earned accessories. Reduce Motion disables decorative movement and automatic roaming while explicit travel remains usable. No third-party or generated raster art is required.

## Living interactions

`CompanionWorld` shares normalized positions between the habitat, desktop strip and physical Touch Bar. It moves incrementally instead of teleporting: walking 0.16, running 0.42, chasing 0.48 and returning 0.34 strip widths per second. A distant Follow target uses running. After 3.8 idle seconds a seeded roaming target is selected; Reduce Motion disables this automatic walk.

Thrown balls/bones follow a bounded flight arc. The pet runs to the destination, waits until the flight lands, carries the toy back to the launch point and celebrates before emitting one fetch event. A new throw or Follow input cancels an unfinished fetch without rewards. Drag release changes a toy's destination once rather than restarting its flight on every move sample.

A food bowl remains visible until the pet reaches it and completes 1.3 seconds of eating. Cuddle takes 0.65 seconds; washing takes one second. Care in progress prevents conflicting care/game starts; Rest or Escape cancels it. Completion is committed through existing care rules, preserving reward caps. Fetch uses the existing cuddle/joy reward and does not count as the daily completed-round goal. A finished Fetch Dash challenge does count.

The controller keeps a failed completion pending and offers retry; the archive changes only after a successful write. Frame deltas cap at 0.05 seconds, background/minimized frames do not advance the world, and no unfinished interaction is reconstructed on reopening. Version-1 JSON migrates to version 2 with existing progress preserved and new counters at zero.

## Care and progression

- Food/joy/energy/clean start at 72/76/82/68.
- Awake absence reduces food by 3, joy by 2, energy by 2 and clean by 1.5 per hour. Rest gains 12 energy/hour. At most eight hours are processed per catch-up.
- Catch-up floors are 20 food and 25 for other needs. A completed game can take energy down to 20. No death, debt, XP decay or streak is implemented.
- Meal: +28 food/+4 energy. Wash: +35 clean/+4 joy. Cuddle: +20 joy. Treat: 15 coins for +20 food/+12 joy/+8 energy.
- A care improvement of at least 2 points yields 3 XP/2 coins only once per action per 60 seconds. Care itself still works inside that interval. Fully satisfied care yields no XP.
- One level per 75 XP, capped at 50. Scarf/star/crown unlock at levels 2/3/5, without spending currency.
- Daily meal/wash/completed round gives an explicitly collected 40 coins/20 XP. Calendar goals reset on a later local Gregorian day, with no penalty for missed days. A backward clock cannot recreate an earlier claimed day.

## Games

Each of the original three mini games lasts 24 active seconds. Star Hunt awards 4 points per target caught within normalized distance 0.08. Ball Rally awards 3 points when its moving ball lies within 0.10 of the target. Paw Pattern begins at two pads, demonstrates a sequence, then accepts player inputs; successful sequences grow to five, mistakes shorten to two without taking earned points.

Completed rounds give `6 + min(60, score)` coins and `6 + min(30, score / 2)` XP, +18 joy and -8 energy. Completed rounds are settled once and remember best score per game. Abandoned rounds have no reward. No real-money purchases, network leaderboard or cheat-resistance claim is made.

Focus loss/minimization pauses the game. Resume is explicit. Long frame gaps are capped to 0.1 seconds. The completed reward is committed before the interface says it was saved; a failed write leaves archive progress unchanged and allows a retry.

## Adoption and continuity

Choose one species at adoption; later rename/recolor preserves identity and progression. One pet belongs to each macOS user profile. Nothing is sent to a service. Persistent rest works even while the app is closed; it does not turn the app into a background Touch Bar replacement.

No login item or notifications are installed. Launch the app when you want company. An optional future login feature would need a visible user choice.

## Worlds, decoration and permanent adventures

All five environments are free: garden hills, seaside waves/sand, a cozy room with window and rug, a moonlit firefly garden, and snowy mountains. Lighting and precipitation are visual choices. Moon Garden intentionally remains night. Rain/snow is kept behind the room window. Reduced Motion renders static precipitation and stops decorative movement.

Decorations are game-coin purchases: cushion 35, flowers 50, lantern 70, tent 95. Selection alone never spends money; an explicit priced button buys and equips. Owned items can be re-equipped for free. Purchases commit only after a successful save.

| Adventure | Total fetches | Meals | Completed rounds | Fetch Dash rounds | Reward coins / XP |
| --- | --- | --- | --- | --- | --- |
| First Paws | 3 | 1 | 1 | 0 | 30 / 15 |
| Playmates | 10 | 3 | 3 | 1 | 55 / 25 |
| Explorers Together | 25 | 8 | 10 | 3 | 90 / 40 |

The goals are lifetime totals starting at this update. Chapters are claimed in order once, with no daily reset. Seven badges are derived from 1/10/25 fetches, 5 meals, 3 rounds, 1/5 Fetch Dash rounds; no separate conflicting badge state is stored.

Fetch Dash lasts 30 active seconds and uses the living companion. An accurate throw within 0.10 of the captured gold target yields 5 points after return, otherwise 3. A new throw cancels the previous attempt. A nearby target is honored exactly instead of the free-play minimum-distance redirect. The deadline cancels unfinished returns. Completion grants `8 + min(40, score)` coins, `8 + min(25, score / 2)` XP, +12 joy and -6 energy; personal best and challenge count persist. Care/food/mini-game starts are locked until returning home. Pause freezes pet movement and time; storage failure also freezes progress until retry succeeds.
