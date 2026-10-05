import AppKit
import PetCore
import ImageIO

func worldSmoke(_ desk:PetController,_ physical:PetRailView,_ bar:NSTouchBar,_ date:Date,_ temp:URL,_ screenshots:URL?)throws->Int {
    var checks=0
    func check(_ condition:@autoclosure ()throws->Bool,_ name:String)throws { guard try condition() else { throw PetError.invalid("FAIL "+name) }; checks+=1; print("PASS "+name) }
    func advance(_ seconds:Double) { for _ in 0..<Int(seconds/0.05) { desk.step(0.05) } }
    guard let cycle=(bar.item(forIdentifier:.petWorld) as? NSCustomTouchBarItem)?.view as? NSButton else { throw PetError.invalid("World control missing") }
    cycle.performClick(nil)
    try check(desk.archive.gameProgress.scene == .seaside && physical.archive.gameProgress.scene == .seaside && desk.habitat.archive.gameProgress.scene == .seaside,"Physical world button changes the desktop, habitat and Touch Bar background together")
    let panel=WorldPanel(owner:desk); desk.worldPanel=panel
    try check(panel.scene.numberOfItems==5 && panel.decoration.numberOfItems==5,"Native world panel exposes all five scenes and decorations")
    panel.scene.selectItem(at:2); panel.picked(panel.scene)
    panel.daylight.selectItem(at:1); panel.picked(panel.daylight)
    panel.weather.selectItem(at:1); panel.picked(panel.weather)
    try check(desk.archive.gameProgress.scene == .room && desk.archive.gameProgress.daylight == .sunset && desk.archive.gameProgress.weather == .rain,"Native scene, lighting and weather selectors use real persistence handlers")
    let beforeDecor=desk.archive
    panel.decoration.selectItem(at:1); panel.picked(panel.decoration)
    try check(desk.archive==beforeDecor && panel.buy.isEnabled,"Browsing an unowned decoration does not spend coins")
    panel.buy.performClick(nil)
    try check(desk.archive.coins==beforeDecor.coins-35 && desk.archive.gameProgress.decoration == .cushion,"Explicit native purchase equips decor and spends the displayed price")
    let bought=desk.archive.coins
    panel.decoration.selectItem(at:0); panel.picked(panel.decoration); panel.buy.performClick(nil)
    panel.decoration.selectItem(at:1); panel.picked(panel.decoration); panel.buy.performClick(nil)
    try check(desk.archive.coins==bought && desk.archive.gameProgress.owned == [.none,.cushion],"Re-equipping an owned decoration is free without duplicate ownership")
    try check(PetStore(directory:temp).load().archive?.gameProgress==desk.archive.gameProgress,"Chosen world and decoration survive a new store instance")
    let fetchControl=((bar.item(forIdentifier:.petMenu) as? NSPopoverTouchBarItem)?.popoverTouchBar.item(forIdentifier:NSTouchBarItem.Identifier("com.metealpkarvan.TouchBarPet.game.fetch")) as? NSCustomTouchBarItem)?.view as? NSButton
    fetchControl?.performClick(nil)
    try check(desk.fetchRound?.phase == .ready && desk.session==nil && desk.selectedTool == .ball,"Physical Fetch Dash menu creates a ready interactive round")
    physical.onInput?(.tap(0.5)); try check(desk.fetchRound?.phase == .running,"Physical strip starts the thirty-second challenge")
    try check(desk.careButtons[.meal]?.isEnabled == false && desk.toolButtons[.food]?.isEnabled == false && desk.gameButtons[.stars]?.isEnabled == false,"Challenge locks conflicting care, food and mini-game controls")
    let tool=desk.selectedTool; desk.selectTool(.food); desk.chooseGame(.stars)
    try check(desk.selectedTool==tool && desk.session==nil,"Handlers reject conflicting actions even when called directly")
    let target=desk.fetchRound!.target,fetches=desk.archive.gameProgress.fetches
    physical.onInput?(.tap(target)); advance(0.25)
    try check(desk.fetchRound?.score==0 && desk.archive.gameProgress.fetches==fetches && desk.world.isFlying,"Challenge throw animates without early score or saved fetch count")
    desk.pause(); let elapsed=desk.fetchRound!.elapsed,position=desk.world.position; advance(3)
    try check(desk.fetchRound?.elapsed==elapsed && desk.world.position==position,"Pause freezes the challenge timer and pet movement together")
    desk.playAction(); advance(5)
    try check(desk.fetchRound?.score==5 && desk.fetchRound?.perfect==1 && desk.archive.gameProgress.fetches==fetches+1,"Accurate actual pickup and return award five points and one permanent fetch")
    try check(physical.fetchRound?.score==5 && desk.rail.fetchRound?.score==5,"Desktop and physical strip share challenge state")
    if let folder=screenshots { try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true); try png(physical,folder.appendingPathComponent("fetch-challenge.png")) }
    advance(30)
    try check(desk.fetchRound?.phase == .finished && desk.rewardSaved && desk.archive.gameProgress.challenges==1,"Native challenge finishes, saves rewards and increments challenge progress")
    let paid=desk.archive; desk.completeRound(); try check(desk.archive==paid,"Repeated challenge completion cannot award twice")
    try check(PetStore(directory:temp).load().archive?.gameProgress.bestFetchScore==5,"Real challenge completion persists the personal best")
    desk.homeAction(); try check(desk.roundPhase==nil && desk.world.object==nil,"Completed challenge returns home and clears unfinished objects")
    try check(panel.claim.isEnabled,"Real care and play unlock the first adventure reward")
    let wallet=desk.archive.coins; panel.claim.performClick(nil)
    try check(desk.archive.gameProgress.claimed == [.firstSteps] && desk.archive.coins==wallet+30,"Native adventure button awards the exact chapter reward")
    let afterClaim=desk.archive; panel.claim.performClick(nil); try check(desk.archive==afterClaim,"Next locked adventure cannot award through a repeated button click")
    let reopened=PetController(store:PetStore(directory:temp),timers:false,now:{date})
    try check(reopened.archive.gameProgress==desk.archive.gameProgress,"Restart preserves backgrounds, cosmetics, lifetime stats, badges and chapters")
    let denied=temp.appendingPathComponent("world-blocked"); try Data("file".utf8).write(to:denied)
    var pet=PetArchive(now:date); try pet.adopt(name:"Test",species:.dog,fur:.cloud,now:date)
    let failed=PetController(store:PetStore(directory:denied),archive:pet,timers:false,now:{date})
    let failedPanel=WorldPanel(owner:failed)
    // Retain the real failing controller as the panel's owner during rollback checks.
    failedPanel.desk=failed; failed.worldPanel=failedPanel; failedPanel.refresh()
    failedPanel.selectedDecoration = .cushion; failedPanel.refresh(); failedPanel.buy.performClick(nil)
    try check(failed.archive==pet && !failed.errorMessage.isEmpty,"Failed native cosmetic save rolls back both currency and decoration")
    failed.fetchAction(); failed.playAction(); failed.challengeThrow(failed.fetchRound!.target)
    for _ in 0..<120 { failed.step(0.05) }
    try check(failed.pendingInteraction != nil && failed.fetchRound?.score==0 && failed.pendingFetchRound?.score==5,"A failed fetch write retains completed score for retry without exposing unsaved progress")
    failed.pause(); let frozen=failed.fetchRound!.elapsed; failed.step(5)
    try check(failed.fetchRound?.elapsed==frozen,"Pending save failure freezes challenge time")
    try FileManager.default.removeItem(at:denied); failed.homeButton.performClick(nil)
    try check(failed.pendingInteraction==nil && failed.fetchRound?.score==5 && failed.fetchRound?.phase == .paused && failed.archive.gameProgress.fetches==1,"Storage repair settles the same completed return once and preserves pause")
    failedPanel.buy.performClick(nil); let purchase=failed.archive
    try check(purchase.coins==pet.coins-35+2 && purchase.gameProgress.decoration == .cushion,"Storage repair applies the original cosmetic purchase with exact currency")
    failedPanel.buy.performClick(nil); try check(failed.archive==purchase,"Saved cosmetic retry cannot charge twice")
    if let folder=screenshots {
        try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
        panel.refresh(); try png(panel.window!.contentView!,folder.appendingPathComponent("world-tr.png"))
        desk.languageAction(); try png(panel.window!.contentView!,folder.appendingPathComponent("world-en.png")); desk.languageAction()
        try worldPreview(desk,physical,folder)
    }
    return checks
}

func worldPreview(_ desk:PetController,_ strip:PetRailView,_ folder:URL)throws {
    let original=desk.archive,frame=strip.frame
    desk.archive.gameProgress.owned=Decoration.allCases
    let url=folder.appendingPathComponent("touchbar-worlds.gif")
    guard let dest=CGImageDestinationCreateWithURL(url as CFURL,"com.compuserve.gif" as CFString,300,nil) else { throw PetError.invalid("GIF destination unavailable") }
    CGImageDestinationSetProperties(dest,[kCGImagePropertyGIFDictionary:[kCGImagePropertyGIFLoopCount:0]] as CFDictionary)
    strip.frame=NSRect(x:0,y:0,width:600,height:48); desk.world=CompanionWorld(seed:9)
    for f in 0..<300 {
        if f%60==0 {
            let i=f/60; desk.archive.gameProgress.scene=SceneTheme.allCases[i]; desk.archive.gameProgress.daylight=[.day,.sunset,.night,.night,.day][i]; desk.archive.gameProgress.weather=[.clear,.clear,.rain,.clear,.snow][i]
            desk.archive.gameProgress.decoration=[.flowers,.tent,.cushion,.lantern,.tent][i]
            desk.selectTool(.ball); desk.input(.tap(i%2==0 ? 0.86 : 0.14))
        }
        // Render snapshots from the real simulation, without committing illustrative cosmetics.
        _=desk.world.tick(0.05,roaming:false); desk.refresh(); strip.clock=Double(f)*0.05; desk.habitat.clock=strip.clock
        if f%60==20 { try png(desk.habitat,folder.appendingPathComponent("scene-"+desk.archive.gameProgress.scene.rawValue+".png")) }
        guard let bitmap=strip.bitmapImageRepForCachingDisplay(in:strip.bounds) else { throw PetError.invalid("World GIF bitmap unavailable") }; strip.cacheDisplay(in:strip.bounds,to:bitmap)
        guard let image=bitmap.cgImage else { throw PetError.invalid("World GIF image unavailable") }
        CGImageDestinationAddImage(dest,image,[kCGImagePropertyGIFDictionary:[kCGImagePropertyGIFDelayTime:0.05,kCGImagePropertyGIFUnclampedDelayTime:0.05]] as CFDictionary)
    }
    guard CGImageDestinationFinalize(dest) else { throw PetError.invalid("World GIF failed") }
    desk.archive=original; strip.frame=frame; desk.world.cancel(); desk.refresh()
}
