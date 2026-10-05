# Design: a companion you can return to

Pati Cepte uses a narrow strip as a shared playground rather than a dashboard of tiny menus. A desktop habitat introduces the pet and makes needs, currency and goals readable. The physical and window strips draw the same character and use the same input path.

The original visual system combines warm paper, apricot/cocoa/cloud fur, muted green foliage and a dark playground. The character is a vector drawing with species-specific ears, tail, muzzle, resting eyes and earned accessories. A slow idle bob and blink respect macOS Reduce Motion. No third-party or generated raster art is required.

## Care and progression

- Food/joy/energy/clean start at 72/76/82/68.
- Awake absence reduces food by 3, joy by 2, energy by 2 and clean by 1.5 per hour. Rest gains 12 energy/hour. At most eight hours are processed per catch-up.
- Catch-up floors are 20 food and 25 for other needs. A completed game can take energy down to 20. No death, debt, XP decay or streak is implemented.
- Meal: +28 food/+4 energy. Wash: +35 clean/+4 joy. Cuddle: +20 joy. Treat: 15 coins for +20 food/+12 joy/+8 energy.
- A care improvement of at least 2 points yields 3 XP/2 coins only once per action per 60 seconds. Care itself still works inside that interval. Fully satisfied care yields no XP.
- One level per 75 XP, capped at 50. Scarf/star/crown unlock at levels 2/3/5, without spending currency.
- Daily meal/wash/completed round gives an explicitly collected 40 coins/20 XP. Calendar goals reset on a later local Gregorian day, with no penalty for missed days. A backward clock cannot recreate an earlier claimed day.

## Games

Every round lasts 24 active seconds. Star Hunt awards 4 points per target caught within normalized distance 0.08. Ball Rally awards 3 points when its moving ball lies within 0.10 of the target. Paw Pattern begins at two pads, demonstrates a sequence, then accepts player inputs; successful sequences grow to five, mistakes shorten to two without taking earned points.

Completed rounds give `6 + min(60, score)` coins and `6 + min(30, score / 2)` XP, +18 joy and -8 energy. Completed rounds are settled once and remember best score per game. Abandoned rounds have no reward. No real-money purchases, network leaderboard or cheat-resistance claim is made.

Focus loss/minimization pauses the game. Resume is explicit. Long frame gaps are capped to 0.1 seconds. The completed reward is committed before the interface says it was saved; a failed write leaves archive progress unchanged and allows a retry.

## Adoption and continuity

Choose one species at adoption; later rename/recolor preserves identity and progression. One pet belongs to each macOS user profile. Nothing is sent to a service. Persistent rest works even while the app is closed; it does not turn the app into a background Touch Bar replacement.

No login item or notifications are installed. Launch the app when you want company. An optional future login feature would need a visible user choice.
