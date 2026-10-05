import AppKit
import PetCore

extension NSTouchBarItem.Identifier {
    static let petRail = NSTouchBarItem.Identifier("com.metealpkarvan.TouchBarPet.rail")
    static let petMenu = NSTouchBarItem.Identifier("com.metealpkarvan.TouchBarPet.menu")
    static let petAction = NSTouchBarItem.Identifier("com.metealpkarvan.TouchBarPet.action")
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
    var session: GameSession?
    var rewardSaved = false
    var timer: Timer?
    var observers: [NSObjectProtocol] = []
    var lastTick = ProcessInfo.processInfo.systemUptime
    var lastPaint = 0.0
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
    let instruction = label("",12,Palette.muted)
    let railTitle = label("",11,Palette.muted,.medium)
    let saveLabel = label("",10,Palette.muted)
    let banner = label("",11,Palette.coral,.medium)
    let vitals = (0..<4).map { _ in VitalView(frame:.zero) }
    var careButtons: [Care:NSButton] = [:]
    var gameButtons: [MiniGame:NSButton] = [:]
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
        let window=PetWindow(contentRect:NSRect(x:0,y:0,width:840,height:680),styleMask:[.titled,.closable,.miniaturizable],backing:.buffered,defer:false)
        super.init(window:window); window.owner=self; window.delegate=self
        window.title="Pati Cepte · Touch Bar Pet"; window.backgroundColor=Palette.paper; window.isReleasedWhenClosed=false
        window.appearance=NSAppearance(named:.aqua)
        window.contentView=PaperView(frame:NSRect(x:0,y:0,width:840,height:680)); window.center()
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
        place(heading,NSRect(x:28,y:621,width:470,height:38))
        place(subtitle,NSRect(x:29,y:599,width:665,height:20))
        languageButton=button("English",NSRect(x:716,y:629,width:96,height:30),#selector(languageAction))
        place(banner,NSRect(x:29,y:579,width:630,height:19))
        recoverButton=button("Kurtar",NSRect(x:698,y:578,width:115,height:23),#selector(recoverAction))
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
        for (i,game) in MiniGame.allCases.enumerated() { gameButtons[game]=button("",NSRect(x:396,y:349-CGFloat(i)*46,width:418,height:38),#selector(gameAction),i) }
        place(instruction,NSRect(x:400,y:188,width:412,height:60))
        playButton=button("",NSRect(x:396,y:141,width:200,height:32),#selector(playAction))
        homeButton=button("",NSRect(x:608,y:141,width:205,height:32),#selector(homeAction))
        place(railTitle,NSRect(x:29,y:122,width:780,height:17)); place(rail,rail.frame)
        rail.onInput = { [weak self] input in self?.input(input) }
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
        subtitle.stringValue=t(l,"Touch Bar’ında küçük bir dost. Bakım yap, birlikte oyna, kaldığın yerden devam et.","A little friend in your Touch Bar. Care, play and pick up where you left off.")
        languageButton.title=t(l,"English","Türkçe")
        if protectedSave { banner.stringValue=t(l,"Ana kayıt korunuyor. ","Primary save is protected. ") + t(l,recoveryAvailable ? "Önceki sağlam kayıt kurtarılabilir." : "Geçerli bir JSON yedeği yükleyebilirsin.",recoveryAvailable ? "A previous valid save can be recovered." : "You can restore a valid JSON backup.") }
        else { banner.stringValue=errorMessage }
        recoverButton.isHidden = !recoveryAvailable || !protectedSave; recoverButton.title=t(l,"Kaydı kurtar","Recover save")
        habitat.archive=archive; habitat.motion=motion; habitat.setAccessibilityLabel(t(l,"\(archive.name), \(archive.species.rawValue), ","\(archive.name), \(archive.species.rawValue), ") + t(l,archive.sleeping ? "dinleniyor" : "uyanik",archive.sleeping ? "resting" : "awake"))
        petName.stringValue=archive.adopted ? archive.name : t(l,"Bir dost edin","Adopt a friend")
        identityButton.title=t(l,archive.adopted ? "Adı / rengi" : "Dost seç",archive.adopted ? "Name / fur" : "Choose pet")
        identityButton.isEnabled = !protectedSave
        progress.stringValue=t(l,"Seviye \(archive.level) · \(archive.xp) bağ XP · \(archive.coins) pati parası","Level \(archive.level) · \(archive.xp) bond XP · \(archive.coins) paw coins")
        bondProgress.doubleValue=archive.levelProgress
        let titles=l == .tr ? ["Tokluk","Neşe","Enerji","Temizlik"] : ["Food","Joy","Energy","Clean"]
        for i in 0..<4 { vitals[i].title=titles[i]; vitals[i].value=archive.needs.values[i]; vitals[i].setAccessibilityLabel(titles[i]) }
        let cares:[Care:String]=[.meal:t(l,"Mama","Feed"),.wash:t(l,"Temizle","Wash"),.cuddle:t(l,"Sev","Cuddle"),.rest:t(l,archive.sleeping ? "Uyandır" : "Dinlendir",archive.sleeping ? "Wake" : "Rest"),.snack:t(l,"Ödül maması · 15","Treat · 15")]
        for (care,b) in careButtons { b.title=cares[care]!; b.isEnabled=archive.adopted && !protectedSave && session == nil && (care != .snack || archive.coins >= 15) }
        costumeButton.title=t(l,"Aksesuarlar · Sv. \(archive.level)","Accessories · Lv. \(archive.level)"); costumeButton.isEnabled=archive.adopted && !protectedSave
        dailyTitle.stringValue=t(l,"Bugünün küçük üçlüsü · \(archive.daily.completed)/3","Today's little trio · \(archive.daily.completed)/3")
        let mark: (Bool)->String = { $0 ? "✓" : "○" }
        dailyText.stringValue="\(mark(archive.daily.meals > 0)) " + t(l,"Bir öğün mama\n","A meal\n") + "\(mark(archive.daily.washes > 0)) " + t(l,"Bir temizlik\n","A wash\n") + "\(mark(archive.daily.games > 0)) " + t(l,"Bir tamamlanmış oyun turu","A completed game round")
        claimButton.title=t(l,archive.daily.claimed ? "Bugünün hediyesi alındı" : "Hediyeyi al · +40 para / +20 XP",archive.daily.claimed ? "Today's gift collected" : "Collect gift · +40 coins / +20 XP")
        claimButton.isEnabled=archive.adopted && !protectedSave && archive.daily.completed==3 && !archive.daily.claimed
        gamesTitle.stringValue=t(l,"Birlikte oyun zamanı","Play together")
        for (game,b) in gameButtons { b.title=word(game,l) + " · " + t(l,"En iyi \(archive.best[game.rawValue] ?? 0)","Best \(archive.best[game.rawValue] ?? 0)"); b.isEnabled=archive.adopted && !protectedSave && !archive.sleeping }
        instruction.stringValue=gameInstruction()
        playButton.title=t(l,session?.phase == .running ? "Duraklat · P" : session?.phase == .paused ? "Devam et · boşluk" : "Başla · boşluk",session?.phase == .running ? "Pause · P" : session?.phase == .paused ? "Resume · space" : "Start · space")
        playButton.isEnabled=session != nil && session?.phase != .finished && !protectedSave
        homeButton.title=t(l,"Yuvaya dön","Back home"); homeButton.isEnabled=session != nil
        railTitle.stringValue=session.map { word($0.game,l) + " · \($0.secondsLeft)s · \($0.score) " + t(l,"puan","points") } ?? t(l,"TOUCH BAR ÖNİZLEMESİ · DOSTUNA DOKUN","TOUCH BAR PREVIEW · TAP YOUR FRIEND")
        let format=DateFormatter(); format.dateStyle = .none; format.timeStyle = .short; format.locale=Locale(identifier:l == .tr ? "tr_TR" : "en_US")
        let saved=lastSaved == .distantPast ? t(l,"Yerel kayıt · her bakım ve tamamlanan turda otomatik","Local save · automatic after care and completed rounds") : t(l,"Kaydedildi · \(format.string(from:lastSaved))","Saved · \(format.string(from:lastSaved))")
        saveLabel.stringValue=errorMessage.isEmpty ? (message.isEmpty ? saved : message + "\n" + saved) : errorMessage
        saveLabel.textColor=errorMessage.isEmpty ? Palette.muted : Palette.coral
        exportButton.title=t(l,"JSON yedekle","Export JSON"); importButton.title=t(l,"Yedek yükle","Restore JSON")
        exportButton.isEnabled=archive.adopted
        for view in [rail,touchRail].compactMap({$0}) { view.archive=archive; view.session=session; view.motion=motion }
        if let s=session { barAction?.title=s.phase == .running ? "Ⅱ \(s.secondsLeft)s" : s.phase == .finished ? "✓ \(s.score)" : "▶ \(s.secondsLeft)s" }
        else { barAction?.title=t(l,archive.sleeping ? "Uyandır" : "Mama",archive.sleeping ? "Wake" : "Feed") }
        barAction?.isEnabled=archive.adopted && !protectedSave && session?.phase != .finished
        for (key,b) in popButtons {
            if let care=Care(rawValue:key) { b.title=cares[care]!; b.isEnabled=archive.adopted && !protectedSave && session == nil && (care != .snack || archive.coins>=15) }
            else if let game=MiniGame(rawValue:String(key.dropFirst(5))) { b.title=word(game,l); b.isEnabled=archive.adopted && !protectedSave && !archive.sleeping }
        }
    }
    func gameInstruction() -> String {
        guard archive.adopted else { return t(language,"Kedi, köpek veya tavşan seç. İlk dostunun adı, rengi ve tüm ilerleyişi bu Mac’te kalır.","Choose a cat, dog or rabbit. Your friend's name, fur and progress stay on this Mac.") }
        if archive.sleeping && session == nil { return t(language,"Dostun dinleniyor. Oynamak için Uyandır’a dokun. Dinlenirken enerji dolar.","Your friend is resting. Tap Wake to play. Rest gradually restores energy.") }
        guard let s=session else { return t(language,"Her tur 24 saniye. Yıldızlara dokun, topu yeşil alanda yakala veya pati sırasını hatırla. Tab ile şeride geçebilirsin.","Each round lasts 24 seconds. Tap stars, catch the ball in green or remember the paw pattern. Tab can focus the strip.") }
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
        guard session == nil else { pause(); message=t(language,"Önce yuvaya dönerek bakım yapabilirsin.","Return home to care for your friend."); refresh(); return }
        let date=now(); var reward=0
        if commit({ reward=try $0.care(action,now:date) }) { message=t(language,reward > 0 ? "Küçük bakım, büyük bağ · +\(reward) XP" : "Dostunla ilgilendin.",reward > 0 ? "A little care, a stronger bond · +\(reward) XP" : "You cared for your friend."); refresh() }
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
        guard archive.adopted, !protectedSave, !archive.sleeping else { return }
        if session?.phase == .finished && !rewardSaved { completeRound(); guard rewardSaved else { return } }
        if session?.phase == .running || session?.phase == .paused {
            pause(); let alert=NSAlert(); alert.messageText=t(language,"Bu turdan çıkılsın mı?","Leave this round?"); alert.informativeText=t(language,"Bitmemiş turun ödülü alınmaz. Önceki ilerleyişin kayıtlı.","An unfinished round has no reward. Previous progress is saved."); alert.addButton(withTitle:t(language,"Yeni oyun","New game")); alert.addButton(withTitle:t(language,"Turda kal","Stay")); if alert.runModal() != .alertFirstButtonReturn { return }
        }
        session=GameSession(game:game,seed:UInt64.random(in:1...UInt64.max)); rewardSaved=false; message=""; refresh(); window?.makeFirstResponder(rail)
    }
    @objc func playAction() {
        guard !protectedSave, !archive.sleeping else { return }
        switch session?.phase { case .ready: session?.start(); case .running: session?.pause(); case .paused: session?.resume(); default: break }
        lastTick=ProcessInfo.processInfo.systemUptime; refresh(); window?.makeFirstResponder(rail)
    }
    func pause() { session?.pause(); refresh() }
    @objc func homeAction() {
        if session?.phase == .finished && !rewardSaved { completeRound(); guard rewardSaved else { return } }
        if session?.phase == .running || session?.phase == .paused {
            pause(); let alert=NSAlert(); alert.messageText=t(language,"Yuvaya dönülsün mü?","Return home?"); alert.informativeText=t(language,"Bitmemiş tur için ödül verilmez. Kayıtlı ilerleyiş korunur.","An unfinished round has no reward. Saved progress is kept."); alert.addButton(withTitle:t(language,"Yuvaya dön","Return home")); alert.addButton(withTitle:t(language,"Turda kal","Stay")); if alert.runModal() != .alertFirstButtonReturn { return }
        }
        session=nil; rewardSaved=false; refresh()
    }
    func input(_ input:RailInput) {
        if session == nil { if case .tap = input { performCare(archive.sleeping ? .rest : .cuddle) }; return }
        switch input {
        case .pause: if session?.phase == .running { pause() } else if session?.phase == .paused { playAction() }
        case .tap(let x): if session?.phase == .ready || session?.phase == .paused { playAction() } else { _=session?.tap(x) }
        case .move(let x): session?.move(x); if session?.game == .stars { _=session?.tap(min(1,max(0,x))) }
        case .pad(let index): if session?.game == .memory { _=session?.tap((Double(index)+0.5)/4) }
        }
        refresh()
    }
    func completeRound() {
        guard let round=session, round.phase == .finished, !rewardSaved else { return }
        let date=now()
        if commit({ _=try $0.settle(round,now:date) }) { rewardSaved=true; message=t(language,"Tur kaydedildi · +\(6+min(60,round.score)) pati parası","Round saved · +\(6+min(60,round.score)) paw coins"); refresh() }
    }
    func step(_ delta:Double) { let wasRunning=session?.phase == .running; session?.tick(delta); if wasRunning && session?.phase == .finished { completeRound() }; refresh() }
    func tick() {
        let stamp=ProcessInfo.processInfo.systemUptime, delta=stamp-lastTick; lastTick=stamp
        if session?.phase == .running { session?.tick(delta); if session?.phase == .finished { completeRound() } }
        if NSApp.isActive && (session?.phase == .running || stamp-lastPaint >= 0.2) {
            lastPaint=stamp; habitat.clock=motion ? stamp : 0
            for view in [rail,touchRail].compactMap({$0}) { view.clock=motion ? stamp : 0; view.session=session }
        }
        if stamp-lastRefresh >= 1 { lastRefresh=stamp; refresh() }
        if archive.adopted && !protectedSave && now().timeIntervalSince(lastSaved) >= 60 { _=commit { _=$0.advance(to:now()) } }
    }
    func saveBeforeQuit() -> Bool {
        pause()
        if session?.phase == .finished && !rewardSaved { completeRound(); if !rewardSaved { return false } }
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
            try store.restore(imported); archive=imported; protectedSave=false; recoveryAvailable=false; session=nil; rewardSaved=false; lastSaved=now(); errorMessage=""; message=t(language,"Yedek geri yüklendi.","Backup restored.")
        } catch { errorMessage=t(language,"Yedek yüklenemedi: ","Restore failed: ") + String(describing:error) }; refresh()
    }
    @objc func recoverAction() {
        guard let store=store, recoveryAvailable else { return }
        let alert=NSAlert(); alert.messageText=t(language,"Önceki sağlam kayıt kurtarılsın mı?","Recover the previous valid save?"); alert.informativeText=t(language,"Okunamayan ana kayıt ham kurtarma kopyası olarak korunur. Son sağlam kayıttan devam edilir.","The unreadable primary is preserved as a raw recovery copy. Continue from the previous valid save.")
        alert.addButton(withTitle:t(language,"Kurtar","Recover")); alert.addButton(withTitle:t(language,"Vazgeç","Cancel")); guard alert.runModal() == .alertFirstButtonReturn else { return }
        do { archive=try store.recoverPrevious(); protectedSave=false; recoveryAvailable=false; errorMessage=""; lastSaved=now(); message=t(language,"Önceki kayıt kurtarıldı.","Previous save recovered.") } catch { errorMessage=String(describing:error) }; refresh()
    }
    func makeBar() -> NSTouchBar {
        let bar=NSTouchBar(); bar.delegate=self; bar.defaultItemIdentifiers=[.petMenu,.petRail,.petAction]; bar.principalItemIdentifier = .petRail; return bar
    }
    func touchBar(_ touchBar:NSTouchBar,makeItemForIdentifier identifier:NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case .petRail:
            let item=NSCustomTouchBarItem(identifier:identifier); let view=PetRailView(frame:NSRect(x:0,y:0,width:400,height:30))
            view.widthAnchor.constraint(greaterThanOrEqualToConstant:220).isActive=true; view.heightAnchor.constraint(equalToConstant:30).isActive=true
            view.onInput = { [weak self] input in self?.input(input) }; item.view=view; touchRail=view; view.archive=archive; view.session=session; return item
        case .petAction:
            let item=NSCustomTouchBarItem(identifier:identifier); let b=NSButton(title:"Mama",target:self,action:#selector(barActionTapped)); b.bezelColor=Palette.green; item.view=b; barAction=b; refresh(); return item
        case .petMenu:
            let item=NSPopoverTouchBarItem(identifier:identifier); item.collapsedRepresentationLabel="Pati"; item.showsCloseButton=true
            let bar=NSTouchBar(); var ids:[NSTouchBarItem.Identifier]=[]; var items:Set<NSTouchBarItem>=[]
            for (i,action) in [Care.meal,.wash,.cuddle,.rest].enumerated() {
                let id=NSTouchBarItem.Identifier("com.metealpkarvan.TouchBarPet.care."+action.rawValue); ids.append(id)
                let child=NSCustomTouchBarItem(identifier:id); let b=NSButton(title:action.rawValue,target:self,action:#selector(careAction)); b.tag=i; child.view=b; items.insert(child); popButtons[action.rawValue]=b
            }
            for (i,game) in MiniGame.allCases.enumerated() {
                let id=NSTouchBarItem.Identifier("com.metealpkarvan.TouchBarPet.game."+game.rawValue); ids.append(id)
                let child=NSCustomTouchBarItem(identifier:id); let b=NSButton(title:word(game,language),target:self,action:#selector(gameAction)); b.tag=i; child.view=b; items.insert(child); popButtons["game."+game.rawValue]=b
            }
            bar.defaultItemIdentifiers=ids; bar.templateItems=items; item.popoverTouchBar=bar; refresh(); return item
        default: return nil
        }
    }
    @objc func barActionTapped() { if session != nil { playAction() } else { performCare(archive.sleeping ? .rest : .meal) } }
}
