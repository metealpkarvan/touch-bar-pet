import AppKit
import PetCore
import ImageIO

final class PetDelegate:NSObject,NSApplicationDelegate {
    var controller:PetController?
    func applicationDidFinishLaunching(_ notification:Notification) {
        let directory=FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("TouchBarPet",isDirectory:true)
        let desk=PetController(store:PetStore(directory:directory)); controller=desk; menus(desk); desk.showDesk()
    }
    func applicationShouldHandleReopen(_ sender:NSApplication,hasVisibleWindows flag:Bool)->Bool { controller?.showDesk(); return true }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender:NSApplication)->Bool { true }
    func applicationSupportsSecureRestorableState(_ app:NSApplication)->Bool { true }
    func applicationShouldTerminate(_ sender:NSApplication)->NSApplication.TerminateReply {
        guard controller?.saveBeforeQuit() == false else { return .terminateNow }
        let alert=NSAlert(); alert.messageText="İlerleyiş kaydedilemedi / Progress could not be saved"; alert.informativeText="Tekrar deneyebilir veya kaydedilmeyen son işlem olmadan çıkabilirsin. / Retry or quit without the last unsaved action."
        alert.addButton(withTitle:"Uygulamada kal / Stay"); alert.addButton(withTitle:"Kaydetmeden çık / Quit without saving")
        return alert.runModal() == .alertSecondButtonReturn ? .terminateNow : .terminateCancel
    }
    private func menus(_ desk:PetController) {
        let menu=NSMenu(); NSApp.mainMenu=menu
        let app=NSMenuItem(); menu.addItem(app); let appMenu=NSMenu(title:"Pati Cepte"); app.submenu=appMenu
        let about=NSMenuItem(title:"Pati Cepte Hakkında / About",action:#selector(aboutAction),keyEquivalent:""); about.target=self; appMenu.addItem(about)
        let source=NSMenuItem(title:"GitHub · Kaynak / Source",action:#selector(sourceAction),keyEquivalent:""); source.target=self; appMenu.addItem(source)
        appMenu.addItem(.separator()); appMenu.addItem(NSMenuItem(title:"Çık / Quit Pati Cepte",action:#selector(NSApplication.terminate(_:)),keyEquivalent:"q"))
        let edit=NSMenuItem(); menu.addItem(edit); let editMenu=NSMenu(title:"Düzen / Edit"); edit.submenu=editMenu
        for (title,action,key) in [("Geri al / Undo",Selector(("undo:")),"z"),("Kes / Cut",#selector(NSText.cut(_:)),"x"),("Kopyala / Copy",#selector(NSText.copy(_:)),"c"),("Yapıştır / Paste",#selector(NSText.paste(_:)),"v"),("Tümünü seç / Select All",#selector(NSText.selectAll(_:)),"a")] { editMenu.addItem(NSMenuItem(title:title,action:action,keyEquivalent:key)) }
        let save=NSMenuItem(); menu.addItem(save); let saveMenu=NSMenu(title:"Dost / Pet"); save.submenu=saveMenu
        for (title,action,key) in [("JSON yedekle / Export JSON",#selector(PetController.exportAction),"s"),("Yedek yükle / Restore JSON",#selector(PetController.importAction),"o")] { let i=NSMenuItem(title:title,action:action,keyEquivalent:key); i.target=desk; saveMenu.addItem(i) }
    }
    @objc func aboutAction() { NSApp.orderFrontStandardAboutPanel(options:[.applicationName:"Pati Cepte · Touch Bar Pet",.applicationVersion:"1.1.0",.credits:NSAttributedString(string:"A little friend, a little play.\nMete Alp Karvan · MIT · 2026")]) }
    @objc func sourceAction() { NSWorkspace.shared.open(URL(string:"https://github.com/metealpkarvan/touch-bar-pet")!) }
}
func png(_ view:NSView,_ url:URL)throws {
    view.layoutSubtreeIfNeeded(); guard let bitmap=view.bitmapImageRepForCachingDisplay(in:view.bounds) else { throw PetError.invalid("Bitmap unavailable") }
    view.cacheDisplay(in:view.bounds,to:bitmap); guard let data=bitmap.representation(using:.png,properties:[:]) else { throw PetError.invalid("PNG unavailable") }; try data.write(to:url)
}
func smoke(_ screenshots:URL?)throws {
    var checks=0
    func check(_ value:@autoclosure ()throws->Bool,_ name:String)throws { guard try value() else { throw PetError.invalid("FAIL "+name) }; checks += 1; print("PASS "+name) }
    let date=Date(timeIntervalSince1970:1_791_180_000)
    let temp=FileManager.default.temporaryDirectory.appendingPathComponent("pati-appkit-"+UUID().uuidString); defer { try? FileManager.default.removeItem(at:temp) }
    var pet=PetArchive(now:date); try pet.adopt(name:"Misket",species:.cat,fur:.apricot,now:date)
    pet.xp=82; try pet.wear(.scarf)
    let store=PetStore(directory:temp); try store.save(pet)
    let desk=PetController(store:store,timers:false,now:{date})
    try check(desk.archive.name=="Misket" && desk.archive.xp==82,"Native desk opens persisted pet identity and XP")
    guard let bar=desk.window?.touchBar,
          let popover=bar.item(forIdentifier:.petMenu) as? NSPopoverTouchBarItem,
          let physical=(bar.item(forIdentifier:.petRail) as? NSCustomTouchBarItem)?.view as? PetRailView,
          let action=(bar.item(forIdentifier:.petAction) as? NSCustomTouchBarItem)?.view as? NSButton else { throw PetError.invalid("Touch Bar items missing") }
    try check(popover.popoverTouchBar.defaultItemIdentifiers.count==7,"Physical Touch Bar popover exposes four care actions and three games")
    func advanceDesk(_ seconds:Double) { for _ in 0..<Int(seconds/0.05) { desk.step(0.05) } }
    let beforeMeal=desk.archive
    action.performClick(nil); try check(desk.archive==beforeMeal && desk.world.object == .meal,"Touch Bar feed places a bowl before changing persistent needs")
    advanceDesk(4); try check(desk.archive.daily.meals==1,"Touch Bar meal saves only after travel and eating")
    let wash=(popover.popoverTouchBar.item(forIdentifier:NSTouchBarItem.Identifier("com.metealpkarvan.TouchBarPet.care.wash")) as? NSCustomTouchBarItem)?.view as? NSButton
    wash?.performClick(nil); advanceDesk(1.2); try check(desk.archive.daily.washes==1,"Popover washing dispatches and completes the real care handler")
    desk.refresh(); try check(physical.archive==desk.archive && desk.rail.archive==desk.archive,"Physical and desktop strips share the pet archive")
    let stored=PetStore(directory:temp).load().archive
    try check(stored?.coins==desk.archive.coins && stored?.xp==desk.archive.xp,"Actual care handlers save before reporting success")
    desk.chooseGame(.stars); try check(desk.session?.phase == .ready,"Selecting game creates ready round")
    physical.onInput?(.tap(0.5)); try check(desk.session?.phase == .running,"Touch Bar input starts round")
    let target=desk.session!.target; physical.onInput?(.tap(target)); try check(desk.session?.score==4,"Touch Bar position reaches star rules")
    let elapsed=desk.session!.elapsed; desk.pause(); desk.step(2)
    try check(desk.session?.phase == .paused && desk.session?.elapsed==elapsed,"Native pause freezes the round")
    action.performClick(nil); try check(desk.session?.phase == .running,"Touch Bar action resumes paused round")
    for _ in 0..<250 { desk.step(0.1) }
    try check(desk.session?.phase == .finished && desk.rewardSaved,"Native round completion saves a real reward")
    let paid=desk.archive; desk.completeRound(); try check(desk.archive==paid,"Repeated native finish cannot award again")
    try check(PetStore(directory:temp).load().archive?.best["stars"]==4,"Best score persists through actual completion handler")
    desk.claimButton.performClick(nil); try check(desk.archive.daily.claimed,"Daily gift button settles the completed trio")
    let paidGift=desk.archive; desk.claimButton.performClick(nil); try check(desk.archive==paidGift,"Disabled daily gift cannot award twice")
    desk.homeAction(); try check(desk.session==nil,"Finished round returns to pet habitat")
    guard let toys=bar.item(forIdentifier:.petToys) as? NSPopoverTouchBarItem else { throw PetError.invalid("Toy controls missing") }
    try check(toys.popoverTouchBar.defaultItemIdentifiers.count==4,"Touch Bar exposes follow, ball, bone and food tools")
    desk.selectTool(.follow); let start=desk.world.position; physical.onInput?(.tap(0.92)); desk.step(0.05)
    try check(desk.world.position>start && desk.world.position<0.92,"Touch Bar follow handler drives gradual movement")
    try check(physical.world.position==desk.world.position && desk.habitat.world.position==desk.world.position,"Habitat, desktop and Touch Bar share the same live position")
    advanceDesk(3)
    physical.onInput?(.move(0.22)); advanceDesk(3)
    try check(abs(desk.world.position-0.22)<0.003 && desk.world.facing == -1,"Dragging moves the real character and reverses its facing")
    let toyButton=(toys.popoverTouchBar.item(forIdentifier:NSTouchBarItem.Identifier("com.metealpkarvan.TouchBarPet.tool.ball")) as? NSCustomTouchBarItem)?.view as? NSButton
    toyButton?.performClick(nil)
    try check(desk.selectedTool == .ball && desk.barToys?.collapsedRepresentationLabel == "Top","Physical toy menu updates the shared selected tool")
    let beforeFetch=desk.archive; physical.onInput?(.tap(0.9)); advanceDesk(0.25)
    try check(desk.world.isFlying && desk.world.objectLift>0 && desk.archive==beforeFetch,"Native ball throw animates before any fetch award")
    advanceDesk(6)
    try check(desk.world.completedFetches==1 && abs(desk.world.position-0.22)<0.003,"Native fetch chases, picks up and returns the ball")
    try check(PetStore(directory:temp).load().archive==desk.archive,"Completed fetch is persisted by the actual care settlement path")
    desk.selectTool(.bone); physical.onInput?(.tap(0.75)); advanceDesk(5)
    try check(desk.world.completedFetches==2 && desk.world.object == nil,"Native bone fetch completes and clears the carried object")
    desk.selectTool(.food); let meals=desk.archive.daily.meals; physical.onInput?(.tap(0.8)); advanceDesk(0.2)
    try check(desk.archive.daily.meals==meals && desk.world.careInProgress,"Placed food does not immediately count as a meal")
    try check(desk.gameButtons[.stars]?.isEnabled == false,"A meal in progress prevents conflicting mini-game selection")
    advanceDesk(6)
    try check(desk.archive.daily.meals==meals+1 && !desk.world.careInProgress,"Placed food is saved after the complete eating animation")
    desk.selectTool(.follow); physical.onInput?(.tap(desk.world.position)); advanceDesk(1)
    try check(desk.world.activity != .cuddling && desk.pendingInteraction == nil,"Touching the pet completes a cuddle once")
    desk.careButtons[.rest]?.performClick(nil); try check(desk.archive.sleeping,"Native rest button saves sleeping state")
    desk.chooseGame(.rally); try check(desk.session==nil,"Sleeping pet does not enter a game")
    action.performClick(nil); try check(!desk.archive.sleeping,"Touch Bar wakes the sleeping pet")
    desk.languageButton.performClick(nil); try check(desk.archive.language == .en && desk.careButtons[.meal]?.title=="Feed","English updates the native interface")
    let reopened=PetController(store:PetStore(directory:temp),timers:false,now:{date})
    try check(reopened.archive.xp==desk.archive.xp && reopened.archive.coins==desk.archive.coins && reopened.archive.daily==desk.archive.daily,"Reopening keeps levels, coins and daily progress")
    try check(reopened.archive.species==desk.archive.species && reopened.archive.fur==desk.archive.fur && reopened.archive.accessory==desk.archive.accessory,"Reopening keeps species, fur and earned accessory")
    desk.languageButton.performClick(nil); try check(desk.archive.language == .tr,"Language preference returns to Turkish")
    if let folder=screenshots {
        try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
        try png(desk.window!.contentView!,folder.appendingPathComponent("desktop-tr.png"))
        desk.languageButton.performClick(nil); try png(desk.window!.contentView!,folder.appendingPathComponent("desktop-en.png")); desk.languageButton.performClick(nil)
        physical.frame=NSRect(x:0,y:0,width:600,height:30); physical.session=nil; physical.archive=desk.archive
        physical.world=desk.world
        try png(physical,folder.appendingPathComponent("touchbar-pet.png"))
        try livingPreview(desk,physical,folder)
        for (game,name) in [(MiniGame.stars,"stars"),(.rally,"rally"),(.memory,"memory")] {
            desk.chooseGame(game); desk.playAction(); desk.step(0.1); physical.session=desk.session
            try png(physical,folder.appendingPathComponent("touchbar-"+name+".png"))
            desk.session=nil; desk.rewardSaved=false
        }
        var dog=desk.archive; dog.species = .dog; dog.fur = .cocoa; desk.habitat.archive=dog; try png(desk.habitat,folder.appendingPathComponent("pet-dog.png"))
        dog.species = .rabbit; dog.fur = .cloud; desk.habitat.archive=dog; try png(desk.habitat,folder.appendingPathComponent("pet-rabbit.png"))
    }
    let raw=Data("unreadable-raw-pet-progress".utf8); try raw.write(to:store.file)
    let guarded=PetController(store:store,timers:false,now:{date}); guarded.performCare(.meal)
    try check(guarded.protectedSave && guarded.recoveryAvailable,"Native desk protects a corrupt primary and exposes recovery")
    try check(try Data(contentsOf:store.file)==raw,"Native care cannot overwrite corrupt raw progress")
    let denied=temp.appendingPathComponent("not-directory"); try Data("x".utf8).write(to:denied)
    let failing=PetController(store:PetStore(directory:denied),archive:pet,timers:false,now:{date})
    let unchanged=failing.archive; failing.performCare(.meal); for _ in 0..<100 { failing.step(0.05) }
    try check(failing.archive==unchanged && !failing.errorMessage.isEmpty,"Failed persistence rolls native action back without reporting saved progress")
    try check(failing.pendingInteraction == .meal && failing.homeButton.isEnabled,"A completed interaction survives a failed write and exposes retry")
    try FileManager.default.removeItem(at:denied); failing.homeButton.performClick(nil)
    try check(failing.pendingInteraction == nil && failing.archive.daily.meals==pet.daily.meals+1,"Retry settles the finished interaction after storage becomes writable")
    let paidMeal=failing.archive; failing.homeButton.performClick(nil)
    try check(failing.archive==paidMeal,"Repeated retry cannot pay for the same interaction twice")
    print("\(checks) AppKit integration checks passed. No real user save, clipboard, permission or physical touch was changed.")
}
func livingPreview(_ desk:PetController,_ strip:PetRailView,_ folder:URL)throws {
    let url=folder.appendingPathComponent("touchbar-live.gif")
    guard let destination=CGImageDestinationCreateWithURL(url as CFURL,"com.compuserve.gif" as CFString,360,nil) else { throw PetError.invalid("GIF destination unavailable") }
    CGImageDestinationSetProperties(destination,[kCGImagePropertyGIFDictionary:[kCGImagePropertyGIFLoopCount:0]] as CFDictionary)
    let originalFrame=strip.frame; strip.frame=NSRect(x:0,y:0,width:600,height:48)
    desk.world=CompanionWorld(seed:9); desk.selectTool(.follow); desk.input(.tap(0.15))
    for frame in 0..<360 {
        if frame==30 { desk.selectTool(.ball); desk.input(.tap(0.86)) }
        if frame==140 { desk.selectTool(.bone); desk.input(.tap(0.58)) }
        if frame==220 { desk.selectTool(.food); desk.input(.tap(0.80)) }
        desk.step(0.05)
        if [45,160,305].contains(frame) { try png(strip,folder.appendingPathComponent(frame==45 ? "touchbar-fetch.png" : frame==160 ? "touchbar-bone.png" : "touchbar-meal.png")) }
        guard let bitmap=strip.bitmapImageRepForCachingDisplay(in:strip.bounds) else { throw PetError.invalid("GIF frame unavailable") }
        strip.cacheDisplay(in:strip.bounds,to:bitmap)
        guard let image=bitmap.cgImage else { throw PetError.invalid("GIF bitmap unavailable") }
        CGImageDestinationAddImage(destination,image,[kCGImagePropertyGIFDictionary:[kCGImagePropertyGIFDelayTime:0.05,kCGImagePropertyGIFUnclampedDelayTime:0.05]] as CFDictionary)
    }
    guard CGImageDestinationFinalize(destination) else { throw PetError.invalid("GIF write failed") }
    strip.frame=originalFrame; desk.selectTool(.follow)
}
let app=NSApplication.shared
if let index=CommandLine.arguments.firstIndex(of:"--iconset"), CommandLine.arguments.indices.contains(index+1) {
    app.setActivationPolicy(.prohibited)
    let folder=URL(fileURLWithPath:CommandLine.arguments[index+1],isDirectory:true)
    do {
        try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
        final class Icon:NSView {
            override func draw(_ dirtyRect:NSRect) {
                fill(bounds,Palette.paper,radius:bounds.width*0.22)
                fill(bounds.insetBy(dx:bounds.width*0.06,dy:bounds.height*0.06),NSColor(calibratedRed:0.83,green:0.90,blue:0.79,alpha:1),radius:bounds.width*0.18)
                drawPet(NSRect(x:bounds.width*0.15,y:bounds.height*0.08,width:bounds.width*0.70,height:bounds.height*0.82),archive:PetArchive(),motion:false)
                star(NSPoint(x:bounds.width*0.80,y:bounds.height*0.77),radius:bounds.width*0.055,color:Palette.gold)
            }
        }
        for size in [16,32,128,256,512] {
            for multiplier in [1,2] {
                let pixels=size*multiplier; let view=Icon(frame:NSRect(x:0,y:0,width:pixels,height:pixels))
                let name="icon_\(size)x\(size)"+(multiplier==2 ? "@2x" : "")+".png"
                try png(view,folder.appendingPathComponent(name))
            }
        }
        exit(0)
    } catch { fputs("Icon failed: \(error)\n",stderr); exit(1) }
} else if CommandLine.arguments.contains("--smoke-test") {
    app.setActivationPolicy(.prohibited)
    let args=CommandLine.arguments
    let folder=args.firstIndex(of:"--screenshots").flatMap { args.indices.contains($0+1) ? URL(fileURLWithPath:args[$0+1],isDirectory:true) : nil }
    do { try smoke(folder); exit(0) } catch { fputs("Smoke failed: \(error)\n",stderr); exit(1) }
} else {
    app.setActivationPolicy(.regular); let delegate=PetDelegate(); app.delegate=delegate; app.run()
}
