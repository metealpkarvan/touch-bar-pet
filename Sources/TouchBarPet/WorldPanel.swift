import AppKit
import PetCore

final class WorldPanel: NSWindowController {
    weak var desk: PetController?
    let preview = HabitatView(frame:NSRect(x:20,y:355,width:320,height:195))
    let title = label("",24,Palette.ink,.bold)
    let summary = label("",12,Palette.muted)
    let scene = NSPopUpButton(), daylight = NSPopUpButton(), weather = NSPopUpButton(), decoration = NSPopUpButton()
    let sceneLabel = label(""), daylightLabel = label(""), weatherLabel = label(""), decorationLabel = label("")
    let buy = NSButton(), claim = NSButton()
    let adventureTitle = label("",18,Palette.ink,.semibold)
    let goals = label("",13,Palette.muted)
    let progress = NSProgressIndicator()
    let stats = label("",12,Palette.muted)
    let collection = label("",15,Palette.ink,.semibold)
    let badges = label("",12,Palette.muted)
    let status = label("",11,Palette.coral)
    var selectedDecoration: Decoration
    init(owner:PetController) {
        self.desk=owner; selectedDecoration=owner.archive.gameProgress.decoration
        let window=NSWindow(contentRect:NSRect(x:0,y:0,width:760,height:620),styleMask:[.titled,.closable],backing:.buffered,defer:false)
        super.init(window:window); window.isReleasedWhenClosed=false; window.appearance=NSAppearance(named:.aqua)
        window.contentView=PaperView(frame:NSRect(x:0,y:0,width:760,height:620)); window.center()
        func place(_ v:NSView,_ r:NSRect) { v.frame=r; window.contentView?.addSubview(v) }
        place(title,NSRect(x:24,y:574,width:690,height:33)); place(summary,NSRect(x:24,y:550,width:690,height:21))
        place(preview,preview.frame)
        let picks=[scene,daylight,weather,decoration], labels=[sceneLabel,daylightLabel,weatherLabel,decorationLabel]
        for i in 0..<4 {
            place(labels[i],NSRect(x:367,y:510-CGFloat(i)*37,width:108,height:24))
            let p=picks[i]; p.tag=i; p.target=self; p.action=#selector(picked(_:)); p.addItems(withTitles:Array(repeating:"",count:i == 0 || i == 3 ? 5 : 3))
            place(p,NSRect(x:470,y:507-CGFloat(i)*37,width:267,height:29))
        }
        buy.target=self; buy.action=#selector(buyAction); buy.bezelStyle = .rounded; place(buy,NSRect(x:466,y:356,width:275,height:31))
        place(adventureTitle,NSRect(x:24,y:314,width:706,height:27)); place(goals,NSRect(x:24,y:269,width:706,height:41))
        progress.style = .bar; progress.isIndeterminate=false; progress.minValue=0; progress.maxValue=1; place(progress,NSRect(x:24,y:254,width:706,height:7))
        claim.target=self; claim.action=#selector(claimAction); claim.bezelStyle = .rounded; place(claim,NSRect(x:20,y:213,width:390,height:33))
        place(stats,NSRect(x:24,y:175,width:706,height:33)); place(collection,NSRect(x:24,y:141,width:706,height:26)); place(badges,NSRect(x:24,y:58,width:706,height:80))
        place(status,NSRect(x:24,y:16,width:706,height:34)); refresh()
    }
    required init?(coder:NSCoder) { fatalError() }
    func refresh() {
        guard let o=desk else { return }; let p=o.archive.gameProgress,l=o.language
        window?.title=t(l,"Pati Dünyası · Sahne ve Macera","Paw World · Scenes and Adventures")
        title.stringValue=t(l,"Dostunun küçük dünyası","Your friend's little world")
        summary.stringValue=t(l,"Beş ücretsiz dünya · dekorları oyun parasıyla al · seçimlerin otomatik kaydedilir","Five free worlds · buy decor with game coins · choices save automatically")
        preview.archive=o.archive; preview.world=o.world; preview.motion=o.motion
        let titles=[SceneTheme.allCases.map{sceneName($0,l)},Daylight.allCases.map{daylightName($0,l)},SceneWeather.allCases.map{weatherName($0,l)},Decoration.allCases.map{decorationName($0,l)+(p.owned.contains($0) ? " ✓" : " · \($0.cost)")}]
        for (i,picker) in [scene,daylight,weather,decoration].enumerated() { for (j,text) in titles[i].enumerated() { picker.item(at:j)?.title=text }; picker.isEnabled = !o.protectedSave && o.archive.adopted }
        scene.selectItem(at:SceneTheme.allCases.firstIndex(of:p.scene)!); daylight.selectItem(at:Daylight.allCases.firstIndex(of:p.daylight)!); weather.selectItem(at:SceneWeather.allCases.firstIndex(of:p.weather)!); decoration.selectItem(at:Decoration.allCases.firstIndex(of:selectedDecoration)!)
        for (field,text) in zip([sceneLabel,daylightLabel,weatherLabel,decorationLabel],l == .tr ? ["Dünya","Işık","Hava","Dekor"] : ["World","Lighting","Weather","Decoration"]) { field.stringValue=text }
        scene.setAccessibilityLabel(sceneLabel.stringValue); daylight.setAccessibilityLabel(daylightLabel.stringValue); weather.setAccessibilityLabel(weatherLabel.stringValue); decoration.setAccessibilityLabel(decorationLabel.stringValue)
        let owned=p.owned.contains(selectedDecoration),equipped=p.decoration==selectedDecoration
        buy.title=equipped ? t(l,"Kullanılıyor","Equipped") : owned ? t(l,"Dekoru yerleştir · ücretsiz","Equip decoration · free") : t(l,"Satın al ve yerleştir · \(selectedDecoration.cost) para","Buy and equip · \(selectedDecoration.cost) coins")
        buy.isEnabled=o.archive.adopted && !o.protectedSave && !equipped && (owned || o.archive.coins>=selectedDecoration.cost)
        if let a=p.nextAdventure {
            let g=a.goals
            adventureTitle.stringValue=t(l,"Macera \(p.claimed.count+1)/3 · ","Adventure \(p.claimed.count+1)/3 · ")+adventureName(a,l)
            goals.stringValue=t(l,"Getirme \(min(p.fetches,g.fetches))/\(g.fetches)  ·  Öğün \(min(p.meals,g.meals))/\(g.meals)  ·  Tam tur \(min(p.rounds,g.rounds))/\(g.rounds)","Fetches \(min(p.fetches,g.fetches))/\(g.fetches)  ·  Meals \(min(p.meals,g.meals))/\(g.meals)  ·  Rounds \(min(p.rounds,g.rounds))/\(g.rounds)")+(g.challenges>0 ? t(l,"\nGetir Götür turu \(min(p.challenges,g.challenges))/\(g.challenges)","\nFetch Dash rounds \(min(p.challenges,g.challenges))/\(g.challenges)") : "")
            progress.doubleValue=p.completion(a); claim.title=t(l,"Macera ödülünü al · +\(a.coins) para / +\(a.xp) XP","Collect adventure reward · +\(a.coins) coins / +\(a.xp) XP")
            claim.isEnabled=o.archive.adopted && !o.protectedSave && p.ready(a)
        } else {
            adventureTitle.stringValue=t(l,"Üç macera da tamamlandı!","All three adventures complete!"); goals.stringValue=t(l,"Dünyanı süsle, yeni rekorlar kır ve rozet koleksiyonunu tamamla.","Decorate your world, set new records and complete your badge collection."); progress.doubleValue=1; claim.title=t(l,"Tüm macera ödülleri alındı","All adventure rewards collected"); claim.isEnabled=false
        }
        stats.stringValue=t(l,"Kalıcı istatistikler: \(p.fetches) getirme · \(p.meals) öğün · \(p.rounds) tur · \(p.challenges) Getir Götür\nEn iyi Getir Götür: \(p.bestFetchScore) puan · Cüzdan: \(o.archive.coins) pati parası","Lifetime: \(p.fetches) fetches · \(p.meals) meals · \(p.rounds) rounds · \(p.challenges) Fetch Dash\nBest Fetch Dash: \(p.bestFetchScore) points · Wallet: \(o.archive.coins) paw coins")
        collection.stringValue=t(l,"Rozet koleksiyonu · \(p.badges.count)/7","Badge collection · \(p.badges.count)/7")
        let requirements=l == .tr ? ["1 getirme","10 getirme","25 getirme","5 öğün","3 tur","1 Getir Götür","5 Getir Götür"] : ["1 fetch","10 fetches","25 fetches","5 meals","3 rounds","1 Fetch Dash","5 Fetch Dash"]
        badges.stringValue=Badge.allCases.enumerated().map { i,b in (p.badges.contains(b) ? "★ " : "○ ")+badgeName(b,l)+" ("+requirements[i]+")" }.enumerated().map { i,s in s+(i%2==0 && i<6 ? "     " : "\n") }.joined()
        status.stringValue=o.errorMessage.isEmpty ? t(l,"Hava görseldir. Ay Bahçesi daima gecedir. Dekor satın almak gerçek para harcamaz.","Weather is visual. Moon Garden is always night. Decor uses game coins only.") : o.errorMessage
    }
    @objc func picked(_ sender:NSPopUpButton) {
        guard let o=desk else { return }; let i=sender.indexOfSelectedItem
        switch sender.tag {
        case 0: _=o.commit { $0.gameProgress.scene=SceneTheme.allCases[i] }
        case 1: _=o.commit { $0.gameProgress.daylight=Daylight.allCases[i] }
        case 2: _=o.commit { $0.gameProgress.weather=SceneWeather.allCases[i] }
        default: selectedDecoration=Decoration.allCases[i]
        }; refresh()
    }
    @objc func buyAction() { guard let o=desk else { return }; if o.commit({ try $0.decorate(selectedDecoration) }) { selectedDecoration=o.archive.gameProgress.decoration }; refresh() }
    @objc func claimAction() { guard let o=desk,let a=o.archive.gameProgress.nextAdventure else { return }; let date=o.now(); _=o.commit { _=$0.claimAdventure(a,now:date) }; refresh() }
}
