import AppKit
import PetCore

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
    @objc func aboutAction() { NSApp.orderFrontStandardAboutPanel(options:[.applicationName:"Pati Cepte · Touch Bar Pet",.applicationVersion:"1.0.0",.credits:NSAttributedString(string:"A little friend, a little play.\nMete Alp Karvan · MIT · 2026")]) }
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
    action.performClick(nil); try check(desk.archive.daily.meals==1,"Touch Bar feed changes the shared persistent model")
    let wash=(popover.popoverTouchBar.item(forIdentifier:NSTouchBarItem.Identifier("com.metealpkarvan.TouchBarPet.care.wash")) as? NSCustomTouchBarItem)?.view as? NSButton
    wash?.performClick(nil); try check(desk.archive.daily.washes==1,"Popover washing dispatches the real care handler")
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
        try png(physical,folder.appendingPathComponent("touchbar-pet.png"))
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
    let unchanged=failing.archive; failing.performCare(.meal)
    try check(failing.archive==unchanged && !failing.errorMessage.isEmpty,"Failed persistence rolls native action back without reporting saved progress")
    print("\(checks) AppKit integration checks passed. No real user save, clipboard, permission or physical touch was changed.")
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
