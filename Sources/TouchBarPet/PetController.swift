import AppKit
import PetCore

extension NSTouchBarItem.Identifier {
    static let petRail = NSTouchBarItem.Identifier("com.metealpkarvan.TouchBarPet.rail")
    static let petMenu = NSTouchBarItem.Identifier("com.metealpkarvan.TouchBarPet.menu")
    static let petAction = NSTouchBarItem.Identifier("com.metealpkarvan.TouchBarPet.action")
    static let petWorld = NSTouchBarItem.Identifier("com.metealpkarvan.TouchBarPet.world")
    static let petToys = NSTouchBarItem.Identifier("com.metealpkarvan.TouchBarPet.toys")
}
final class PetWindow: NSWindow {
    weak var owner: PetController?
    override func makeTouchBar() -> NSTouchBar? { owner?.makeBar() }
}
final class PaperView: NSView {
    override func draw(_ dirtyRect:NSRect) { Palette.paper.setFill(); bounds.fill() }
}
final class PetController: NSWindowController, NSWindowDelegate, NSTouchBarDelegate {
    var archive: PetArchive
    let store: PetStore?
    var protectedSave = false
    var recoveryAvailable = false
    var now: () -> Date
    var fetchRound: FetchRound?
    var worldPanel: WorldPanel?
    var sceneButton = NSButton(), adventureButton = NSButton(), fetchButton = NSButton()
    var barWorld: NSButton?
    var roundPhase: Phase? { session?.phase ?? fetchRound?.phase }
    var session: GameSession?
    var world = CompanionWorld()
    var selectedTool: PlaygroundTool = .follow
    var pendingInteraction: CompanionEvent?
    var pendingFetchRound: FetchRound?
    var rewardSaved = false
    var timer: Timer?
    var observers: [NSObjectProtocol] = []
    var lastTick = ProcessInfo.processInfo.systemUptime
    var lastRefresh = 0.0
    var lastSaved = Date.distantPast
    var message = ""
    var errorMessage = ""
    let habitat = HabitatView(frame:NSRect(x:28,y:350,width:340,height:226))
    let rail = PetRailView(frame:NSRect(x:28,y:72,width:784,height:48))
    var touchRail: PetRailView?
    let heading = label("Pati Cepte",29,Palette.ink,.bold)
    let subtitle = label("",12,Palette.muted)
    let petName = label("",23,Palette.ink,.semibold)
    let progress = label("",12,Palette.muted)
    let bondProgress = NSProgressIndicator()
    let dailyTitle = label("",17,Palette.ink,.semibold)
    let dailyText = label("",13,Palette.muted)
    let gamesTitle = label("",20,Palette.ink,.semibold)
    let roundsTitle = label("",11,Palette.muted,.medium)
    let instruction = label("",12,Palette.muted)
    let railTitle = label("",11,Palette.muted,.medium)
    let saveLabel = label("",10,Palette.muted)
    let banner = label("",11,Palette.coral,.medium)
    let vitals = (0..<4).map { _ in VitalView(frame:.zero) }
    var careButtons: [Care:NSButton] = [:]
    var gameButtons: [MiniGame:NSButton] = [:]
    var toolButtons: [PlaygroundTool:NSButton] = [:]
    var barToolButtons: [PlaygroundTool:NSButton] = [:]
    var barToys: NSPopoverTouchBarItem?
    var barMenu: NSPopoverTouchBarItem?
    var languageButton = NSButton()
    var identityButton = NSButton()
    var claimButton = NSButton()
    var costumeButton = NSButton()
    var playButton = NSButton()
    var homeButton = NSButton()
    var exportButton = NSButton()
    var importButton = NSButton()
    var recoverButton = NSButton()
    var barAction: NSButton?
    var popButtons: [String:NSButton] = [:]

    init(store:PetStore?=nil, archive:PetArchive?=nil, timers:Bool=true, now:@escaping ()->Date={ Date() }) {
        self.store=store; self.now=now
        let report=store?.load()
        self.archive=archive ?? report?.archive ?? PetArchive(now:now())
        protectedSave=report?.protected ?? false; recoveryAvailable=report?.recoveryAvailable ?? false
        let window=PetWindow(contentRect:NSRect(x:0,y:0,width:840,height:720),styleMask:[.titled,.closable,.miniaturizable],backing:.buffered,defer:false)
        super.init(window:window); window.owner=self; window.delegate=self
        window.title="Pati Cepte · Touch Bar Pet"; window.backgroundColor=Palette.paper; window.isReleasedWhenClosed=false
        window.appearance=NSAppearance(named:.aqua)
        window.contentView=PaperView(frame:NSRect(x:0,y:0,width:840,height:720)); window.center()
        build(); window.touchBar=makeBar(); refresh()
        if timers {
            timer=Timer(timeInterval:1.0/30.0,repeats:true) { [weak self] _ in self?.tick() }
            RunLoop.main.add(timer!,forMode:.common)
            for name in [NSApplication.didResignActiveNotification,NSWindow.didMiniaturizeNotification] {
                observers.append(NotificationCenter.default.addObserver(forName:name,object:name == NSWindow.didMiniaturizeNotification ? window : nil,queue:.main) { [weak self] _ in self?.pause() })
            }
        }
    }
    required init?(coder:NSCoder) { fatalError() }
    deinit { timer?.invalidate(); for observer in observers { NotificationCenter.default.removeObserver(observer) } }
    var language:Language { archive.language }
    var motion:Bool { !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }
    func showDesk() { showWindow(nil); NSApp.activate(ignoringOtherApps:true); window?.makeKeyAndOrderFront(nil) }
    func place(_ view:NSView,_ rect:NSRect) { view.frame=rect; window?.contentView?.addSubview(view) }
    func button(_ title:String,_ rect:NSRect,_ action:Selector,_ tag:Int=0) -> NSButton {
        let b=NSButton(title:title,target:self,action:action); b.bezelStyle = .rounded; b.font = NSFont.systemFont(ofSize:12,weight:.medium); b.tag=tag; place(b,rect); return b
    }
    private func build() {
        place(heading,NSRect(x:28,y:661,width:470,height:38))
        place(subtitle,NSRect(x:29,y:639,width:665,height:20))
        languageButton=button("English",NSRect(x:716,y:669,width:96,height:30),#selector(languageAction))
        place(banner,NSRect(x:29,y:619,width:630,height:19))
        recoverButton=button("Kurtar",NSRect(x:698,y:618,width:115,height:23),#selector(recoverAction))
        sceneButton=button("",NSRect(x:24,y:582,width:348,height:31),#selector(worldAction))
        adventureButton=button("",NSRect(x:396,y:582,width:244,height:31),#selector(worldAction))
        fetchButton=button("",NSRect(x:648,y:582,width:168,height:31),#selector(fetchAction))
        place(habitat,habitat.frame)
        place(petName,NSRect(x:28,y:314,width:225,height:30))
        identityButton=button("Dost edin",NSRect(x:254,y:315,width:114,height:27),#selector(identityAction))
        place(progress,NSRect(x:28,y:288,width:340,height:24))
        bondProgress.style = .bar; bondProgress.isIndeterminate=false; bondProgress.minValue=0; bondProgress.maxValue=1
        bondProgress.setAccessibilityLabel("Bond level progress"); place(bondProgress,NSRect(x:28,y:278,width:340,height:6))
        for i in 0..<4 { place(vitals[i],NSRect(x:28+CGFloat(i)*88,y:231,width:76,height:46)); vitals[i].color=[Palette.coral,Palette.gold,Palette.green,NSColor.systemTeal][i] }
        for (i,care) in [Care.meal,.wash,.cuddle,.rest].enumerated() { careButtons[care]=button("",NSRect(x:26+CGFloat(i)*88,y:186,width:84,height:35),#selector(careAction),i) }
        careButtons[.snack]=button("",NSRect(x:26,y:141,width:162,height:32),#selector(careAction),4)
        costumeButton=button("",NSRect(x:204,y:141,width:166,height:32),#selector(costumeAction))
        place(dailyTitle,NSRect(x:400,y:550,width:412,height:27)); place(dailyText,NSRect(x:400,y:482,width:412,height:63))
        claimButton=button("",NSRect(x:396,y:443,width:260,height:32),#selector(claimAction))
        place(gamesTitle,NSRect(x:400,y:394,width:412,height:30))
        for (i,tool) in PlaygroundTool.allCases.enumerated() { toolButtons[tool]=button("",NSRect(x:396+CGFloat(i)*105,y:349,width:103,height:38),#selector(toolAction),i) }
        place(roundsTitle,NSRect(x:400,y:316,width:412,height:21))
        for (i,game) in MiniGame.allCases.enumerated() { gameButtons[game]=button("",NSRect(x:396+CGFloat(i)*140,y:270,width:138,height:36),#selector(gameAction),i); gameButtons[game]?.font=NSFont.systemFont(ofSize:11,weight:.medium) }
        place(instruction,NSRect(x:400,y:188,width:412,height:60))
        playButton=button("",NSRect(x:396,y:141,width:200,height:32),#selector(playAction))
        homeButton=button("",NSRect(x:608,y:141,width:205,height:32),#selector(homeAction))
        place(railTitle,NSRect(x:29,y:122,width:780,height:17)); place(rail,rail.frame)
        rail.onInput = { [weak self] input in self?.input(input) }
        habitat.onInput = { [weak self] input in self?.input(input) }
        place(saveLabel,NSRect(x:29,y:20,width:505,height:37))
        exportButton=button("",NSRect(x:552,y:25,width:120,height:31),#selector(exportAction))
        importButton=button("",NSRect(x:684,y:25,width:130,height:31),#selector(importAction))
    }
    @discardableResult func commit(_ change:(inout PetArchive)throws->Void) -> Bool {
        guard !protectedSave else { errorMessage=t(language,"Korunan kayıt: önce kurtar veya yedek yükle.","Protected save: recover or restore a backup first."); refresh(); return false }
        var next=archive
        do {
            next.advance(to:now()); try change(&next); try next.validate(); try store?.save(next)
            archive=next; lastSaved=now(); errorMessage=""; refresh(); return true
        } catch { errorMessage=t(language,"Kaydedilemedi; değişiklik uygulanmadı.","Save failed; the change was not applied.") + " " + String(describing:error); refresh(); return false }
    }
    func refresh() {
        let l=language
        world.sleep(archive.sleeping)
        subtitle.stringValue=t(l,"Yürüyen, koşan, oyuncağını getiren küçük dostun. Dokun, mama bırak, birlikte oyna.","A little friend who walks, runs and fetches. Tap, place food and play together.")
        languageButton.title=t(l,"English","Türkçe")
        if protectedSave { banner.stringValue=t(l,"Ana kayıt korunuyor. ","Primary save is protected. ") + t(l,recoveryAvailable ? "Önceki sağlam kayıt kurtarılabilir." : "Geçerli bir JSON yedeği yükleyebilirsin.",recoveryAvailable ? "A previous valid save can be recovered." : "You can restore a valid JSON backup.") }
        else { banner.stringValue=errorMessage }
        recoverButton.isHidden = !recoveryAvailable || !protectedSave; recoverButton.title=t(l,"Kaydı kurtar","Recover save")
        habitat.archive=archive; habitat.world=world; habitat.motion=motion; habitat.setAccessibilityLabel(archive.name + ", " + activityName(world,l) + ". " + t(l,"Dokunarak etkileş.","Tap to interact."))
        petName.stringValue=archive.adopted ? archive.name : t(l,"Bir dost edin","Adopt a friend")
        identityButton.title=t(l,archive.adopted ? "Adı / rengi" : "Dost seç",archive.adopted ? "Name / fur" : "Choose pet")
        identityButton.isEnabled = !protectedSave
        progress.stringValue=t(l,"Seviye \(archive.level) · \(archive.xp) bağ XP · \(archive.coins) pati parası","Level \(archive.level) · \(archive.xp) bond XP · \(archive.coins) paw coins")
        bondProgress.doubleValue=archive.levelProgress
        let titles=l == .tr ? ["Tokluk","Neşe","Enerji","Temizlik"] : ["Food","Joy","Energy","Clean"]
        for i in 0..<4 { vitals[i].title=titles[i]; vitals[i].value=archive.needs.values[i]; vitals[i].setAccessibilityLabel(titles[i]) }
        let cares:[Care:String]=[.meal:t(l,"Mama","Feed"),.wash:t(l,"Temizle","Wash"),.cuddle:t(l,"Sev","Cuddle"),.rest:t(l,archive.sleeping ? "Uyandır" : "Dinlendir",archive.sleeping ? "Wake" : "Rest"),.snack:t(l,"Ödül maması · 15","Treat · 15")]
        for (care,b) in careButtons { b.title=cares[care]!; b.isEnabled=archive.adopted && !protectedSave && roundPhase == nil && pendingInteraction == nil && (care == .rest || (!world.careInProgress && !archive.sleeping)) && (care != .snack || archive.coins >= 15) }
        costumeButton.title=t(l,"Aksesuarlar · Sv. \(archive.level)","Accessories · Lv. \(archive.level)"); costumeButton.isEnabled=archive.adopted && !protectedSave
        dailyTitle.stringValue=t(l,"Bugünün küçük üçlüsü · \(archive.daily.completed)/3","Today's little trio · \(archive.daily.completed)/3")
        let mark: (Bool)->String = { $0 ? "✓" : "○" }
        dailyText.stringValue="\(mark(archive.daily.meals > 0)) " + t(l,"Bir öğün mama\n","A meal\n") + "\(mark(archive.daily.washes > 0)) " + t(l,"Bir temizlik\n","A wash\n") + "\(mark(archive.daily.games > 0)) " + t(l,"Bir tamamlanmış oyun turu","A completed game round")
        claimButton.title=t(l,archive.daily.claimed ? "Bugünün hediyesi alındı" : "Hediyeyi al · +40 para / +20 XP",archive.daily.claimed ? "Today's gift collected" : "Collect gift · +40 coins / +20 XP")
        claimButton.isEnabled=archive.adopted && !protectedSave && archive.daily.completed==3 && !archive.daily.claimed
        gamesTitle.stringValue=t(l,"Canlı oyun alanı","Living playground")
        roundsTitle.stringValue=t(l,"KISA TURLAR · 24 SANİYE · EN İYİ PUAN","SHORT ROUNDS · 24 SECONDS · BEST SCORE")
        for (game,b) in gameButtons { b.title=word(game,l) + " · \(archive.best[game.rawValue] ?? 0)"; b.isEnabled=archive.adopted && !protectedSave && !archive.sleeping && !world.careInProgress && pendingInteraction == nil && fetchRound == nil }
        for (tool,b) in toolButtons { b.title=(selectedTool == tool ? "• " : "") + toolName(tool,l); b.isEnabled=archive.adopted && !protectedSave && !archive.sleeping && session == nil && !world.careInProgress && pendingInteraction == nil && (fetchRound == nil || tool == .ball || tool == .bone) }
        for (tool,b) in barToolButtons { b.title=(selectedTool == tool ? "• " : "") + toolName(tool,l); b.isEnabled=toolButtons[tool]?.isEnabled ?? false }
        barToys?.collapsedRepresentationLabel=toolName(selectedTool,l)
        instruction.stringValue=gameInstruction()
        playButton.title=t(l,roundPhase == .running ? "Duraklat · P" : roundPhase == .paused ? "Devam et · boşluk" : "Başla · boşluk",roundPhase == .running ? "Pause · P" : roundPhase == .paused ? "Resume · space" : "Start · space")
        playButton.isEnabled=roundPhase != nil && roundPhase != .finished && !protectedSave
        homeButton.title=pendingInteraction != nil ? t(l,"Kaydetmeyi yeniden dene","Retry saving") : t(l,"Yuvaya dön","Back home"); homeButton.isEnabled=roundPhase != nil || pendingInteraction != nil
        railTitle.stringValue=fetchRound.map { t(l,"Getir Götür","Fetch Dash") + " · \($0.secondsLeft)s · \($0.score) " + t(l,"puan · \($0.perfect) isabet","points · \($0.perfect) perfect") } ?? session.map { word($0.game,l) + " · \($0.secondsLeft)s · \($0.score) " + t(l,"puan","points") } ?? (toolName(selectedTool,l).uppercased() + " · " + activityName(world,l) + t(l," · Dokun / sürükle"," · Tap / drag"))
        let format=DateFormatter(); format.dateStyle = .none; format.timeStyle = .short; format.locale=Locale(identifier:l == .tr ? "tr_TR" : "en_US")
        let saved=lastSaved == .distantPast ? t(l,"Yerel kayıt · her bakım ve tamamlanan turda otomatik","Local save · automatic after care and completed rounds") : t(l,"Kaydedildi · \(format.string(from:lastSaved))","Saved · \(format.string(from:lastSaved))")
        saveLabel.stringValue=errorMessage.isEmpty ? (message.isEmpty ? saved : message + "\n" + saved) : errorMessage
        saveLabel.textColor=errorMessage.isEmpty ? Palette.muted : Palette.coral
        exportButton.title=t(l,"JSON yedekle","Export JSON"); importButton.title=t(l,"Yedek yükle","Restore JSON")
        exportButton.isEnabled=archive.adopted
        for view in [rail,touchRail].compactMap({$0}) { view.archive=archive; view.session=session; view.fetchRound=fetchRound; view.world=world; view.tool=selectedTool; view.motion=motion; view.setAccessibilityLabel(archive.name + ". " + toolName(selectedTool,l) + ". " + activityName(world,l)); view.setAccessibilityValue("\(Int(world.position*100))%") }
        if let s=fetchRound { barAction?.title=s.phase == .running ? "Ⅱ \(s.secondsLeft)s" : s.phase == .finished ? "✓ \(s.score)" : "▶ \(s.secondsLeft)s" }
        else if let s=session { barAction?.title=s.phase == .running ? "Ⅱ \(s.secondsLeft)s" : s.phase == .finished ? "✓ \(s.score)" : "▶ \(s.secondsLeft)s" }
        else { barAction?.title=t(l,archive.sleeping ? "Uyandır" : "Mama",archive.sleeping ? "Wake" : "Feed") }
        barAction?.isEnabled=archive.adopted && !protectedSave && roundPhase != .finished && pendingInteraction == nil && !world.careInProgress
        sceneButton.title=t(l,"Dünya · ","World · ")+sceneName(archive.gameProgress.scene,l)+" ▾"
        adventureButton.title=t(l,"Macera · \(archive.gameProgress.claimed.count)/3 · Rozet \(archive.gameProgress.badges.count)/7","Adventure · \(archive.gameProgress.claimed.count)/3 · Badges \(archive.gameProgress.badges.count)/7")
        fetchButton.title=t(l,"Getir Götür · 30s","Fetch Dash · 30s"); fetchButton.isEnabled=archive.adopted && !protectedSave && !archive.sleeping && roundPhase == nil && !world.careInProgress && pendingInteraction == nil
        barWorld?.title=sceneName(archive.gameProgress.scene,l); barWorld?.isEnabled=archive.adopted && !protectedSave
        worldPanel?.refresh()
        for (key,b) in popButtons {
            if key == "fetch" { b.title=t(l,"Getir Götür","Fetch Dash"); b.isEnabled=fetchButton.isEnabled }
            else if let care=Care(rawValue:key) { b.title=cares[care]!; b.isEnabled=careButtons[care]?.isEnabled ?? false }
            else if let game=MiniGame(rawValue:String(key.dropFirst(5))) { b.title=word(game,l); b.isEnabled=gameButtons[game]?.isEnabled ?? false }
        }
    }
    func gameInstruction() -> String {
        guard archive.adopted else { return t(language,"Kedi, köpek veya tavşan seç. İlk dostunun adı, rengi ve tüm ilerleyişi bu Mac’te kalır.","Choose a cat, dog or rabbit. Your friend's name, fur and progress stay on this Mac.") }
        if archive.sleeping && session == nil { return t(language,"Dostun dinleniyor. Oynamak için Uyandır’a dokun. Dinlenirken enerji dolar.","Your friend is resting. Tap Wake to play. Rest gradually restores energy.") }
        if let r=fetchRound {
            if r.phase == .finished { return rewardSaved ? t(language,"Tur kaydedildi! İsabet: \(r.perfect) · Getirme: \(r.catches). Macera ve rozetlere Pati Dünyası’ndan bak.","Round saved! Perfect: \(r.perfect) · Fetches: \(r.catches). Check Paw World for adventures and badges.") : t(language,"Ödül kaydedilemedi. Yuvaya dön ile tekrar dene.","Reward could not be saved. Back home retries.") }
            return t(language,"Altın hedef bölgesine top veya kemik at. Geri getirince +3, hedefe isabetliyse +5 puan. 30 aktif saniye; P ile duraklat.","Throw a ball or bone into the gold target zone. A return scores +3, an accurate throw +5. 30 active seconds; P pauses.")
        }
        guard let s=session else {
            switch selectedTool {
            case .follow: return t(language,"Bir yere dokun: dostun oraya yürüsün veya koşsun. Parmağını sürükle: takip etsin. Dostunun üstüne dokun: sev.","Tap a place: your friend walks or runs there. Drag: follow your finger. Tap your pet: cuddle.")
            case .ball, .bone: return t(language,"Şeritte bir yere dokun: oyuncağı oraya at. Dostun koşup alır, attığın yere geri getirir. Sürükleyerek de atabilirsin.","Tap a place on the strip to throw a toy. Your friend runs, picks it up and brings it back to the launch point. Drag to throw too.")
            case .food: return t(language,"Bir yere dokun: mama kabını bırak. Dostun yürüyüp yedikten sonra tokluk ve ilerleme kaydedilir.","Tap a place to put down a bowl. Your friend walks over and eats before food and progress are saved.")
            }
        }
        if s.phase == .finished { return rewardSaved ? t(language,"Tur tamamlandı ve ödül kaydedildi. Yeni oyun seçebilir veya yuvaya dönebilirsin.","Round complete and reward saved. Choose another game or return home.") : t(language,"Ödül henüz kaydedilemedi. Yuvaya dön düğmesi kaydetmeyi yeniden dener.","The reward could not be saved. Back home retries saving.") }
        switch s.game {
        case .stars: return t(language,"Yıldıza dokun veya sürükle. Klavyede ← → ile patini taşı, boşlukla yakala. +4 puan.","Tap a star or drag. Keyboard: move with ← → and catch with space. +4 points.")
        case .rally: return t(language,"Top yeşil alandayken şeride veya boşluğa dokun. Her yakalayışta hedef değişir. +3 puan.","Tap the strip or space while the ball is in green. The target moves after each catch. +3 points.")
        case .memory: return t(language,s.showing ? "Parlayan pati sırasını izle. Sıra bitince aynı sırada 1–4 veya şeridin dört alanına dokun." : "Şimdi sıra sende: aynı pati sırasını 1–4 ile veya şeride dokunarak tekrarla.",s.showing ? "Watch the lit paw sequence. Then repeat with 1–4 or the four strip areas." : "Your turn: repeat the paw sequence using 1–4 or the strip areas.")
        }
    }
    @objc func identityAction() {
        pause()
        let alert=NSAlert(); alert.messageText=t(language,archive.adopted ? "Dostunun kimliği" : "Küçük bir dost edin",archive.adopted ? "Your friend's identity" : "Adopt a little friend")
        alert.informativeText=t(language,"Adı 1–24 karakter olabilir. İlerleyiş otomatik kaydedilir. Tür sahiplenirken seçilir.","Use a 1–24 character name. Progress is saved automatically. Species is chosen at adoption.")
        let box=NSView(frame:NSRect(x:0,y:0,width:320,height:112))
        let name=NSTextField(string:archive.name); name.frame=NSRect(x:0,y:77,width:320,height:26); name.setAccessibilityLabel(t(language,"Dostunun adı","Pet name")); box.addSubview(name)
        let species=NSPopUpButton(frame:NSRect(x:0,y:39,width:153,height:27)); species.addItems(withTitles:language == .tr ? ["Kedi","Köpek","Tavşan"] : ["Cat","Dog","Rabbit"]); species.selectItem(at:Species.allCases.firstIndex(of:archive.species)!); species.isEnabled = !archive.adopted; species.setAccessibilityLabel(t(language,"Tür","Species")); box.addSubview(species)
        let fur=NSPopUpButton(frame:NSRect(x:166,y:39,width:154,height:27)); fur.addItems(withTitles:language == .tr ? ["Kayısı","Bulut","Kakao"] : ["Apricot","Cloud","Cocoa"]); fur.selectItem(at:Fur.allCases.firstIndex(of:archive.fur)!); fur.setAccessibilityLabel(t(language,"Tüy rengi","Fur color")); box.addSubview(fur)
        alert.accessoryView=box; alert.addButton(withTitle:t(language,"Kaydet","Save")); alert.addButton(withTitle:t(language,"Vazgeç","Cancel")); window?.makeFirstResponder(name)
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let date=now(), selectedSpecies=Species.allCases[species.indexOfSelectedItem], selectedFur=Fur.allCases[fur.indexOfSelectedItem]
        if commit({ pet in if pet.adopted { pet.name=name.stringValue.trimmingCharacters(in:.whitespacesAndNewlines); pet.fur=selectedFur } else { try pet.adopt(name:name.stringValue,species:selectedSpecies,fur:selectedFur,now:date) } }) { message=t(language,"\(archive.name) artık senin dostun.","\(archive.name) is your little friend."); refresh() }
    }
    @objc func careAction(_ sender:NSButton) { performCare([Care.meal,.wash,.cuddle,.rest,.snack][min(4,max(0,sender.tag))]) }
    func performCare(_ action:Care) {
        guard archive.adopted, !protectedSave, pendingInteraction == nil else { return }
        guard roundPhase == nil else { pause(); message=t(language,"Önce yuvaya dönerek bakım yapabilirsin.","Return home to care for your friend."); refresh(); return }
        if action == .rest {
            let date=now(); if commit({ _=try $0.care(.rest,now:date) }) { world.sleep(archive.sleeping) }; refresh(); return
        }
        guard !archive.sleeping, !world.careInProgress else { return }
        let destination = world.position < 0.5 ? 0.82 : 0.18
        switch action {
        case .meal: _=world.feed(at:destination)
        case .snack: if archive.coins >= 15 { _=world.feed(at:destination,treat:true) }
        case .cuddle: _=world.cuddle()
        case .wash: _=world.wash()
        case .rest: break
        }
        message=activityName(world,language); refresh()
    }
    @objc func toolAction(_ sender:NSButton) { selectTool(PlaygroundTool.allCases[min(3,max(0,sender.tag))]); barToys?.dismissPopover(nil) }
    func selectTool(_ tool:PlaygroundTool) {
        guard archive.adopted, !protectedSave, !archive.sleeping, session == nil, !world.careInProgress, pendingInteraction == nil else { return }
        guard fetchRound == nil || tool == .ball || tool == .bone else { return }
        selectedTool=tool; message=""; refresh(); window?.makeFirstResponder(rail)
    }
    func settleInteraction() {
        guard let event=pendingInteraction else { return }
        let action:Care
        switch event { case .meal: action = .meal; case .treat: action = .snack; case .cuddle,.fetched: action = .cuddle; case .wash: action = .wash }
        let date=now(); var reward=0
        if case .fetched = event, pendingFetchRound == nil, var nextRound=fetchRound { _=nextRound.returned(); pendingFetchRound=nextRound }
        var nextRound=pendingFetchRound ?? fetchRound
        if fetchRound?.phase == .paused { nextRound?.pause() }
        let points=max(0,(nextRound?.score ?? 0)-(fetchRound?.score ?? 0))
        if commit({ pet in reward=try pet.care(action,now:date); if case .fetched = event { pet.recordFetch() } }) {
            fetchRound=nextRound
            pendingFetchRound=nil
            pendingInteraction=nil
            if case .fetched = event { message=t(language,"Oyuncağını geri getirdi!", "Your friend brought the toy back!") }
            else { message=t(language,"Bakım tamamlandı.","Care completed.") }
            if points > 0 { message += " · +\(points) " + t(language,"puan","points") }; if reward > 0 { message += " · +\(reward) XP" }; refresh()
        }
    }
    @objc func worldAction() { pause(); if worldPanel == nil { worldPanel=WorldPanel(owner:self) }; worldPanel?.refresh(); worldPanel?.showWindow(nil); worldPanel?.window?.makeKeyAndOrderFront(nil) }
    @objc func cycleWorldAction() { let scenes=SceneTheme.allCases,i=scenes.firstIndex(of:archive.gameProgress.scene)!; _=commit { $0.gameProgress.scene=scenes[(i+1)%scenes.count] } }
    @objc func fetchAction() {
        guard archive.adopted,!protectedSave,!archive.sleeping,roundPhase == nil,!world.careInProgress,pendingInteraction == nil else { return }
        world.cancel(); fetchRound=FetchRound(seed:UInt64.random(in:1...UInt64.max)); selectedTool = .ball; rewardSaved=false; message=""; refresh(); barMenu?.dismissPopover(nil); window?.makeFirstResponder(rail)
    }
    @objc func languageAction() { _=commit { $0.language = $0.language == .tr ? .en : .tr }; refresh() }
    @objc func claimAction() { let date=now(); if commit({ _=$0.claimDaily(now:date) }) { message=t(language,"Küçük üçlü tamam! +40 para, +20 XP.","Little trio complete! +40 coins, +20 XP."); refresh() } }
    @objc func costumeAction() {
        pause()
        let alert=NSAlert(); alert.messageText=t(language,"Sevgiyle açılan aksesuarlar","Accessories earned with care")
        alert.informativeText=t(language,"Fular: seviye 2 · Yıldız: seviye 3 · Taç: seviye 5. Aksesuarlar para harcamaz.","Scarf: level 2 · Star: level 3 · Crown: level 5. Accessories cost no coins.")
        let picker=NSPopUpButton(frame:NSRect(x:0,y:0,width:280,height:30))
        picker.addItems(withTitles:language == .tr ? ["Doğal","Fular","Yıldız","Taç"] : ["Natural","Scarf","Star","Crown"])
        picker.selectItem(at:Accessory.allCases.firstIndex(of:archive.accessory)!)
        for (i,a) in Accessory.allCases.enumerated() { picker.item(at:i)?.isEnabled=archive.level>=a.requiredLevel }; picker.autoenablesItems=false
        alert.accessoryView=picker; alert.addButton(withTitle:t(language,"Tak","Wear")); alert.addButton(withTitle:t(language,"Vazgeç","Cancel"))
        if alert.runModal() == .alertFirstButtonReturn { _=commit { try $0.wear(Accessory.allCases[picker.indexOfSelectedItem]) } }
    }
    @objc func gameAction(_ sender:NSButton) { chooseGame(MiniGame.allCases[min(2,max(0,sender.tag))]) }
    func chooseGame(_ game:MiniGame) {
        guard archive.adopted, !protectedSave, !archive.sleeping, fetchRound == nil, !world.careInProgress, pendingInteraction == nil else { return }
        if roundPhase == .finished && !rewardSaved { completeRound(); guard rewardSaved else { return } }
        if session?.phase == .running || session?.phase == .paused {
            pause(); let alert=NSAlert(); alert.messageText=t(language,"Bu turdan çıkılsın mı?","Leave this round?"); alert.informativeText=t(language,"Bitmemiş turun ödülü alınmaz. Önceki ilerleyişin kayıtlı.","An unfinished round has no reward. Previous progress is saved."); alert.addButton(withTitle:t(language,"Yeni oyun","New game")); alert.addButton(withTitle:t(language,"Turda kal","Stay")); if alert.runModal() != .alertFirstButtonReturn { return }
        }
        world.cancel(); session=GameSession(game:game,seed:UInt64.random(in:1...UInt64.max)); rewardSaved=false; message=""; refresh(); barMenu?.dismissPopover(nil); window?.makeFirstResponder(rail)
    }
    @objc func playAction() {
        guard !protectedSave, !archive.sleeping else { return }
        if fetchRound != nil { switch fetchRound?.phase { case .ready: fetchRound?.start(); case .running: fetchRound?.pause(); case .paused: fetchRound?.resume(); default: break } }
        else { switch session?.phase { case .ready: session?.start(); case .running: session?.pause(); case .paused: session?.resume(); default: break } }
        lastTick=ProcessInfo.processInfo.systemUptime; refresh(); window?.makeFirstResponder(rail)
    }
    func pause() { session?.pause(); fetchRound?.pause(); refresh() }
    @objc func homeAction() {
        if pendingInteraction != nil { settleInteraction(); return }
        if roundPhase == .finished && !rewardSaved { completeRound(); guard rewardSaved else { return } }
        if roundPhase == .running || roundPhase == .paused {
            pause(); let alert=NSAlert(); alert.messageText=t(language,"Yuvaya dönülsün mü?","Return home?"); alert.informativeText=t(language,"Bitmemiş tur için ödül verilmez. Kayıtlı ilerleyiş korunur.","An unfinished round has no reward. Saved progress is kept."); alert.addButton(withTitle:t(language,"Yuvaya dön","Return home")); alert.addButton(withTitle:t(language,"Turda kal","Stay")); if alert.runModal() != .alertFirstButtonReturn { return }
        }
        session=nil; fetchRound=nil; world.cancel(); rewardSaved=false; refresh()
    }
    func input(_ input:RailInput) {
        guard archive.adopted, !protectedSave, pendingInteraction == nil else { return }
        if fetchRound != nil {
            switch input {
            case .pause: if fetchRound?.phase == .running { pause() } else if fetchRound?.phase == .paused { playAction() }
            case .tap(let x): if fetchRound?.phase == .ready || fetchRound?.phase == .paused { playAction() } else { challengeThrow(x) }
            case .release(let x): challengeThrow(x)
            case .pad(let i): if PlaygroundTool.allCases.indices.contains(i) { selectTool(PlaygroundTool.allCases[i]) }
            case .move: break
            }; refresh(); return
        }
        if session == nil {
            if archive.sleeping { if case .tap = input { performCare(.rest) }; return }
            switch input {
            case .tap(let x):
                switch selectedTool {
                case .follow: if abs(x-world.position) < 0.055 { _=world.cuddle() } else { _=world.follow(x) }
                case .ball: _=world.throwToy(.ball,toward:x)
                case .bone: _=world.throwToy(.bone,toward:x)
                case .food: _=world.feed(at:x)
                }
            case .move(let x): if selectedTool == .follow { _=world.follow(x) }
            case .release(let x): if selectedTool == .ball || selectedTool == .bone { _=world.throwToy(selectedTool == .ball ? .ball : .bone,toward:x) }
            case .pause: world.cancel()
            case .pad(let index): if PlaygroundTool.allCases.indices.contains(index) { selectTool(PlaygroundTool.allCases[index]) }
            }
            refresh(); return
        }
        switch input {
        case .pause: if session?.phase == .running { pause() } else if session?.phase == .paused { playAction() }
        case .tap(let x): if session?.phase == .ready || session?.phase == .paused { playAction() } else { _=session?.tap(x) }
        case .move(let x): session?.move(x); if session?.game == .stars { _=session?.tap(min(1,max(0,x))) }
        case .pad(let index): if session?.game == .memory { _=session?.tap((Double(index)+0.5)/4) }
        case .release: break
        }
        refresh()
    }
    func challengeThrow(_ x:Double) {
        guard fetchRound?.phase == .running else { return }
        if world.throwToy(selectedTool == .bone ? .bone : .ball,toward:x,allowShort:true) { fetchRound?.throwAt(world.target) }
    }
    func completeRound() {
        guard !rewardSaved else { return }; let date=now()
        if let round=fetchRound,round.phase == .finished {
            if commit({ _=try $0.settleFetch(round,now:date) }) { rewardSaved=true; message=t(language,"Getir Götür kaydedildi · +\(8+min(40,round.score)) para","Fetch Dash saved · +\(8+min(40,round.score)) coins"); refresh() }
        } else if let round=session,round.phase == .finished {
            if commit({ _=try $0.settle(round,now:date) }) { rewardSaved=true; message=t(language,"Tur kaydedildi · +\(6+min(60,round.score)) pati parası","Round saved · +\(6+min(60,round.score)) paw coins"); refresh() }
        }
    }
    func advanceCompanion(_ delta:Double) {
        guard session == nil,archive.adopted,!protectedSave,pendingInteraction == nil else { return }
        if fetchRound != nil {
            guard fetchRound?.phase == .running else { return }
            fetchRound?.tick(delta)
            if fetchRound?.phase == .finished { world.cancel(); completeRound(); return }
        }
        if let event=world.tick(delta,roaming:motion && fetchRound == nil).first { pendingInteraction=event; settleInteraction() }
    }
    func step(_ delta:Double) { let wasRunning=session?.phase == .running; session?.tick(delta); if wasRunning && session?.phase == .finished { completeRound() }; advanceCompanion(delta); refresh() }
    func tick() {
        let stamp=ProcessInfo.processInfo.systemUptime, delta=stamp-lastTick; lastTick=stamp
        if session?.phase == .running { session?.tick(delta); if session?.phase == .finished { completeRound() } }
        if NSApp.isActive && window?.isMiniaturized != true { advanceCompanion(delta) }
        if NSApp.isActive && window?.isMiniaturized != true {
            habitat.clock=motion ? stamp : 0
            habitat.world=world
            if worldPanel?.window?.isVisible == true { worldPanel?.preview.clock=motion ? stamp : 0; worldPanel?.preview.world=world }
            for view in [rail,touchRail].compactMap({$0}) { view.clock=motion ? stamp : 0; view.session=session; view.fetchRound=fetchRound; view.world=world }
        }
        if stamp-lastRefresh >= 1 { lastRefresh=stamp; refresh() }
        if archive.adopted && !protectedSave && now().timeIntervalSince(lastSaved) >= 60 { _=commit { _=$0.advance(to:now()) } }
    }
    func saveBeforeQuit() -> Bool {
        pause()
        if pendingInteraction != nil { settleInteraction(); if pendingInteraction != nil { return false } }
        if roundPhase == .finished && !rewardSaved { completeRound(); if !rewardSaved { return false } }
        return !archive.adopted || protectedSave || commit { _=$0.advance(to:now()) }
    }
    func windowWillClose(_ notification:Notification) { pause(); _=saveBeforeQuit() }
    @objc func exportAction() {
        pause(); let panel=NSSavePanel(); panel.allowedFileTypes=["json"]; panel.nameFieldStringValue="pati-cepte-backup.json"
        panel.title=t(language,"Dostunu JSON olarak yedekle","Back up your friend as JSON")
        guard panel.runModal() == .OK, let url=panel.url else { return }
        do { try archive.encoded().write(to:url,options:.atomic); message=t(language,"JSON yedeği oluşturuldu.","JSON backup exported.") } catch { errorMessage=String(describing:error) }; refresh()
    }
    @objc func importAction() {
        pause(); let panel=NSOpenPanel(); panel.allowedFileTypes=["json"]; panel.canChooseDirectories=false; panel.allowsMultipleSelection=false
        guard panel.runModal() == .OK, let url=panel.url, let store=store else { return }
        do {
            let imported=try store.importFile(url); let alert=NSAlert(); alert.messageText=t(language,"\(imported.name) yedeği geri yüklensin mi?","Restore \(imported.name)'s backup?")
            alert.informativeText=t(language,"Bu Mac’teki mevcut kayıt değişir. Eski ham kayıt kurtarma kopyası olarak korunur. Yedekler birleştirilmez.","The local save will be replaced. Its original raw data is kept as a recovery copy. Backups are not merged.")
            alert.addButton(withTitle:t(language,"Geri yükle","Restore")); alert.addButton(withTitle:t(language,"Vazgeç","Cancel")); guard alert.runModal() == .alertFirstButtonReturn else { return }
            try store.restore(imported); archive=imported; protectedSave=false; recoveryAvailable=false; session=nil; fetchRound=nil; world=CompanionWorld(); pendingInteraction=nil; pendingFetchRound=nil; rewardSaved=false; lastSaved=now(); errorMessage=""; message=t(language,"Yedek geri yüklendi.","Backup restored.")
        } catch { errorMessage=t(language,"Yedek yüklenemedi: ","Restore failed: ") + String(describing:error) }; refresh()
    }
    @objc func recoverAction() {
        guard let store=store, recoveryAvailable else { return }
        let alert=NSAlert(); alert.messageText=t(language,"Önceki sağlam kayıt kurtarılsın mı?","Recover the previous valid save?"); alert.informativeText=t(language,"Okunamayan ana kayıt ham kurtarma kopyası olarak korunur. Son sağlam kayıttan devam edilir.","The unreadable primary is preserved as a raw recovery copy. Continue from the previous valid save.")
        alert.addButton(withTitle:t(language,"Kurtar","Recover")); alert.addButton(withTitle:t(language,"Vazgeç","Cancel")); guard alert.runModal() == .alertFirstButtonReturn else { return }
        do { archive=try store.recoverPrevious(); session=nil; fetchRound=nil; pendingInteraction=nil; pendingFetchRound=nil; world=CompanionWorld(); rewardSaved=false; protectedSave=false; recoveryAvailable=false; errorMessage=""; lastSaved=now(); message=t(language,"Önceki kayıt kurtarıldı.","Previous save recovered.") } catch { errorMessage=String(describing:error) }; refresh()
    }
    func makeBar() -> NSTouchBar {
        let bar=NSTouchBar(); bar.delegate=self; bar.defaultItemIdentifiers=[.petMenu,.petWorld,.petRail,.petToys,.petAction]; bar.principalItemIdentifier = .petRail; return bar
    }
    func touchBar(_ touchBar:NSTouchBar,makeItemForIdentifier identifier:NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case .petRail:
            let item=NSCustomTouchBarItem(identifier:identifier); let view=PetRailView(frame:NSRect(x:0,y:0,width:400,height:30))
            view.widthAnchor.constraint(greaterThanOrEqualToConstant:220).isActive=true; view.heightAnchor.constraint(equalToConstant:30).isActive=true
            view.onInput = { [weak self] input in self?.input(input) }; item.view=view; touchRail=view; view.archive=archive; view.session=session; return item
        case .petWorld:
            let item=NSCustomTouchBarItem(identifier:identifier); let b=NSButton(title:"Dünya",target:self,action:#selector(cycleWorldAction)); item.view=b; barWorld=b; refresh(); return item
        case .petAction:
            let item=NSCustomTouchBarItem(identifier:identifier); let b=NSButton(title:"Mama",target:self,action:#selector(barActionTapped)); b.bezelColor=Palette.green; item.view=b; barAction=b; refresh(); return item
        case .petToys:
            let item=NSPopoverTouchBarItem(identifier:identifier); item.showsCloseButton=true
            let menu=NSTouchBar(); var ids:[NSTouchBarItem.Identifier]=[]; var items:Set<NSTouchBarItem>=[]
            for (i,tool) in PlaygroundTool.allCases.enumerated() {
                let id=NSTouchBarItem.Identifier("com.metealpkarvan.TouchBarPet.tool."+tool.rawValue); ids.append(id)
                let child=NSCustomTouchBarItem(identifier:id); let b=NSButton(title:toolName(tool,language),target:self,action:#selector(toolAction)); b.tag=i; child.view=b; items.insert(child); barToolButtons[tool]=b
            }
            menu.defaultItemIdentifiers=ids; menu.templateItems=items; item.popoverTouchBar=menu; barToys=item; refresh(); return item
        case .petMenu:
            let item=NSPopoverTouchBarItem(identifier:identifier); item.collapsedRepresentationLabel="Pati"; item.showsCloseButton=true; barMenu=item
            let bar=NSTouchBar(); var ids:[NSTouchBarItem.Identifier]=[]; var items:Set<NSTouchBarItem>=[]
            for (i,action) in [Care.meal,.wash,.cuddle,.rest].enumerated() {
                let id=NSTouchBarItem.Identifier("com.metealpkarvan.TouchBarPet.care."+action.rawValue); ids.append(id)
                let child=NSCustomTouchBarItem(identifier:id); let b=NSButton(title:action.rawValue,target:self,action:#selector(careAction)); b.tag=i; child.view=b; items.insert(child); popButtons[action.rawValue]=b
            }
            for (i,game) in MiniGame.allCases.enumerated() {
                let id=NSTouchBarItem.Identifier("com.metealpkarvan.TouchBarPet.game."+game.rawValue); ids.append(id)
                let child=NSCustomTouchBarItem(identifier:id); let b=NSButton(title:word(game,language),target:self,action:#selector(gameAction)); b.tag=i; child.view=b; items.insert(child); popButtons["game."+game.rawValue]=b
            }
            let fetchID=NSTouchBarItem.Identifier("com.metealpkarvan.TouchBarPet.game.fetch"); ids.append(fetchID)
            let fetchItem=NSCustomTouchBarItem(identifier:fetchID); let fetch=NSButton(title:"Getir Götür",target:self,action:#selector(fetchAction)); fetchItem.view=fetch; items.insert(fetchItem); popButtons["fetch"]=fetch
            bar.defaultItemIdentifiers=ids; bar.templateItems=items; item.popoverTouchBar=bar; refresh(); return item
        default: return nil
        }
    }
    @objc func barActionTapped() { if roundPhase != nil { playAction() } else { performCare(archive.sleeping ? .rest : .meal) } }
}
