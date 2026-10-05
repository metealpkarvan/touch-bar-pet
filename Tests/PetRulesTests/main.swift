import Foundation
import PetCore

var checks=0
func check(_ condition:@autoclosure ()throws->Bool,_ name:String) throws {
    guard try condition() else { throw PetError.invalid("FAIL: " + name) }; checks += 1; print("PASS " + name)
}
func rejects(_ name:String,_ body:()throws->Void) throws {
    do { try body() } catch { checks += 1; print("PASS " + name); return }; throw PetError.invalid("Expected rejection: " + name)
}
let date=Date(timeIntervalSince1970:1_791_180_000)
func pet() throws -> PetArchive { var p=PetArchive(now:date); try p.adopt(name:"Misket",species:.cat,fur:.apricot,now:date); return p }
func finished(_ game:MiniGame,seed:UInt64=42) -> GameSession { var r=GameSession(game:game,seed:seed); r.start(); for _ in 0..<250 { r.tick(0.1) }; return r }
do {
    var p=PetArchive(now:date)
    try check(!p.adopted && p.level==1 && p.coins==35,"Fresh adoption and starting coins")
    try rejects("Cannot care before adoption") { _=try p.care(.meal,now:date) }
    try rejects("Blank name rejected") { try p.adopt(name:"  ",species:.cat,fur:.cloud,now:date) }
    try rejects("Long name rejected") { try p.adopt(name:String(repeating:"a",count:25),species:.cat,fur:.cloud,now:date) }
    try rejects("Control characters rejected") { try p.adopt(name:"Pati\nCep",species:.cat,fur:.cloud,now:date) }
    try p.adopt(name:"  Fındık  ",species:.rabbit,fur:.cocoa,now:date)
    try check(p.name=="Fındık" && p.species == .rabbit && p.fur == .cocoa,"Adoption trims name and keeps species/fur")
    try check(p.adopted && p.journal.last?.event=="adopt","Adoption has a saved journal entry")
    try rejects("Cannot silently replace adopted pet") { try p.adopt(name:"New",species:.dog,fur:.cloud,now:date) }
    try check(try PetArchive.decode(p.encoded())==p,"JSON round-trip preserves the complete pet")
    p=try pet(); let food=p.needs.food
    try check(try p.care(.meal,now:date)==3,"Meaningful meal earns bond XP")
    try check(p.needs.food>food && p.needs.food<=100 && p.coins==37,"Free meal improves needs and grants small coins")
    let xp=p.xp
    _=try p.care(.meal,now:date.addingTimeInterval(1))
    try check(p.xp==xp,"Repeated care cannot farm instant XP")
    try check(p.daily.meals==2,"Meal contributes to the daily trio")
    _=try p.care(.wash,now:date)
    try check(p.needs.clean==100 && p.daily.washes==1,"Washing improves clean and daily progress")
    _=try p.care(.cuddle,now:date)
    try check(p.needs.joy>99.99 && p.needs.joy<=100,"Cuddling improves joy to its bound")
    let fullXP=p.xp; _=try p.care(.cuddle,now:date.addingTimeInterval(61))
    try check(p.xp==fullXP,"Full needs do not yield care XP")
    p=try pet(); let coins=p.coins; _=try p.care(.snack,now:date)
    try check(p.coins==coins-15+2 && p.needs.joy>76,"Optional treat has an explicit cost")
    p.coins=0
    try rejects("Treat refuses insufficient coins") { _=try p.care(.snack,now:date) }
    _=try p.care(.meal,now:date)
    try check(p.needs.food==100,"Basic care stays free when coins are zero")
    p=try pet(); p.xp=164; p.coins=207; p.best["stars"]=20
    let spent=p.advance(to:date.addingTimeInterval(100*86400))
    try check(spent==8*3600,"Absence changes needs for at most eight hours")
    try check(p.xp==164 && p.coins==207 && p.best["stars"]==20,"Absence never erases earned progress")
    try check(p.needs.food>=20 && p.needs.joy>=25 && p.needs.energy>=25 && p.needs.clean>=25,"Needs have gentle floors without death")
    let before=p.updatedAt; let need=p.needs
    p.advance(to:date)
    try check(p.updatedAt==before && p.needs==need,"Clock rollback does not reverse the simulation")
    p=try pet(); _=try p.care(.rest,now:date)
    try check(p.sleeping,"Rest is an explicit persistent state")
    p.advance(to:date.addingTimeInterval(3600))
    try check(p.needs.energy==94,"Rest restores energy over elapsed time")
    _=try p.care(.rest,now:date.addingTimeInterval(3600)); try check(!p.sleeping,"Wake toggles resting state")
    p=try pet(); try rejects("Level-locked accessories rejected") { try p.wear(.crown) }
    p.xp=75; try check(p.level==2 && p.levelProgress==0,"Level two unlock at 75 XP")
    try p.wear(.scarf); try check(p.accessory == .scarf,"Unlocked accessory is persistent")
    p.xp=300; try p.wear(.crown); try check(p.level==5,"Crown unlocks at level five")
    p.xp=1_000_000; try check(p.level==50 && p.levelProgress==1,"Level cap is bounded")
    p=try pet(); try check(!p.claimDaily(now:date),"Incomplete daily gift cannot be claimed")
    _=try p.care(.meal,now:date); _=try p.care(.wash,now:date)
    let stars=finished(.stars); _=try p.settle(stars,now:date)
    try check(p.daily.completed==3,"Care and a completed round finish daily trio")
    let giftCoins=p.coins, giftXP=p.xp
    try check(p.claimDaily(now:date),"Completed gift can be claimed")
    try check(p.coins==giftCoins+40 && p.xp==giftXP+20,"Daily gift has exact transparent rewards")
    try check(!p.claimDaily(now:date) && !p.claimDaily(now:date.addingTimeInterval(-86400)),"Daily gift cannot be reclaimed or reset by rollback")
    p.advance(to:date.addingTimeInterval(86400)); try check(!p.daily.claimed && p.daily.completed==0,"A later local calendar day resets only daily goals")
    try check(PetArchive.dayKey(date,zone:TimeZone(secondsFromGMT:0)!).count==10,"Calendar keys use stable Gregorian format")
    p=try pet(); let round=finished(.rally)
    try check(round.phase == .finished && round.elapsed==24,"Every round ends after 24 active seconds")
    try check(try p.settle(round,now:date),"Completed round is settled")
    let paid=p
    try check(try !p.settle(round,now:date) && p==paid,"Reward receipt prevents duplicate settlement")
    try check(p.coins==41 && p.xp==6 && p.daily.games==1,"Finishing with zero points still gives a friendly reward")
    try rejects("Unfinished round has no reward") { _=try p.settle(GameSession(game:.stars),now:date) }
    var game=GameSession(game:.stars,seed:71); game.start()
    let target=game.target
    try check(game.tap(target) && game.score==4 && game.hits==1,"Star input maps normalized target to a hit")
    try check(!game.tap(game.target),"Tap debounce rejects duplicate immediate inputs")
    game.tick(0.2); game.tick(0.1)
    try check(!game.tap(-1) && !game.tap(.nan) && !game.tap(1.1),"Invalid game input is rejected")
    game.move(2); try check(game.player==1,"Movement is clamped to available strip")
    game.move(-2); try check(game.player==0,"Left movement stays within strip")
    let elapsed=game.elapsed; game.pause(); game.tick(10)
    try check(game.phase == .paused && game.elapsed==elapsed,"Pause freezes simulation and reward time")
    game.resume(); game.tick(10); try check(abs(game.elapsed-elapsed-0.1)<0.000001,"Long frame gaps are capped")
    let safeTime=game.elapsed; game.tick(-1); game.tick(.nan); game.tick(.infinity)
    try check(game.elapsed==safeTime,"Invalid time deltas do not mutate the game")
    var a=GameSession(game:.stars,seed:9), b=GameSession(game:.stars,seed:9); a.start(); b.start()
    for _ in 0..<40 { a.tick(0.05); b.tick(0.05) }
    try check(a.target==b.target && a.score==b.score && a.misses==b.misses,"Seeded targets and timing are reproducible")
    var rally=GameSession(game:.rally,seed:6); rally.start()
    for _ in 0..<239 { if abs(rally.ball-rally.target)<0.09 { _=rally.tap(0.5) }; rally.tick(0.1) }
    try check(rally.score>0 && rally.hits>0,"Ball rally produces real skill-based catches")
    try check((0.04...0.96).contains(rally.ball),"Ball stays inside its horizontal arena")
    var memory=GameSession(game:.memory,seed:12); memory.start()
    try check(memory.sequence.count==2 && memory.showing,"Memory game begins with a visible two-pad sequence")
    try check(!memory.tap(0.5) && memory.score==0,"Memory inputs are ignored during demonstration")
    for _ in 0..<20 { memory.tick(0.1) }
    try check(!memory.showing,"Memory game explicitly enters the player's turn")
    let sequence=memory.sequence
    for pad in sequence { _=memory.tap((Double(pad)+0.5)/4); memory.tick(0.1); memory.tick(0.1) }
    try check(memory.score==6 && memory.sequence.count==3 && memory.showing,"Correct memory sequence scores and grows difficulty")
    for _ in 0..<30 { memory.tick(0.1) }
    let wrong=(memory.sequence[0]+1)%4; _=memory.tap((Double(wrong)+0.5)/4)
    try check(memory.misses==1 && memory.showing && memory.sequence.count==2,"Incorrect sequence recovers without removing earned score")
    for game in MiniGame.allCases {
        let done=finished(game); try check(done.phase == .finished && done.secondsLeft==0,"\(game.rawValue) ends and reports zero remaining seconds")
    }
    var invalid=try pet(); invalid.needs.food = .nan
    try rejects("Nonfinite needs rejected") { try invalid.validate() }
    invalid=try pet(); invalid.coins = -1; try rejects("Negative currency rejected") { try invalid.validate() }
    invalid=try pet(); invalid.version=2; try rejects("Unknown save version protected") { try invalid.validate() }
    invalid=try pet(); invalid.best["unknown"]=99; try rejects("Unknown game score rejected") { try invalid.validate() }
    invalid=try pet(); invalid.daily.key="2026-99-88"; try rejects("Invalid calendar key rejected") { try invalid.validate() }
    invalid=try pet(); invalid.createdAt=Date(timeIntervalSince1970:.infinity); try rejects("Invalid timestamps rejected") { try invalid.validate() }
    invalid=try pet(); invalid.gameReceipts=[round.id,round.id]; try rejects("Duplicate reward receipts rejected") { try invalid.validate() }
    try rejects("Oversized backup rejected") { _=try PetArchive.decode(Data(repeating:32,count:1_048_577)) }
    try rejects("Malformed JSON rejected") { _=try PetArchive.decode(Data("broken".utf8)) }
    p=try pet(); for _ in 0..<60 { p.note("cuddle",at:date) }; try check(p.journal.count==40,"Journal remains bounded")
    let temp=FileManager.default.temporaryDirectory.appendingPathComponent("pati-tests-"+UUID().uuidString)
    defer { try? FileManager.default.removeItem(at:temp) }
    let store=PetStore(directory:temp)
    try check(store.load().archive==nil && !store.load().protected,"Missing save starts a fresh pet")
    let first=try pet(); try store.save(first)
    try check(store.load().archive==first,"Saved pet survives a new store instance")
    var second=first; second.xp=96; second.coins=118; second.name="Fıstık"; try second.wear(.scarf); try store.save(second)
    try check(try PetArchive.decode(Data(contentsOf:store.previous))==first,"Previous valid revision is kept")
    try check(PetStore(directory:temp).load().archive==second,"Name, XP, coins and cosmetic survive reopen")
    let permissions=try FileManager.default.attributesOfItem(atPath:store.file.path)[.posixPermissions] as? NSNumber
    try check(permissions?.intValue==0o600,"Saved record permissions are private to the local user")
    try FileManager.default.removeItem(at:store.file)
    try check(store.load().protected && store.load().recoveryAvailable && store.load().archive==first,"Missing primary protects and offers the previous pet instead of starting over")
    _=try store.recoverPrevious(); try check(store.load().archive==first,"A missing primary can be explicitly recovered")
    try store.save(second)
    let raw=Data("unreadable-original-pet-record".utf8); try raw.write(to:store.file)
    let report=store.load(); try check(report.protected && report.recoveryAvailable && report.archive==first,"Corrupt primary exposes a valid recovery candidate without overwriting")
    try rejects("Normal save refuses corrupt primary") { try store.save(second) }
    try check(try Data(contentsOf:store.file)==raw,"Rejected write keeps raw corrupt data byte-for-byte")
    let recovered=try store.recoverPrevious(); try check(recovered==first && store.load().archive==first,"Explicit recovery continues from previous valid pet")
    let rawCopies=try FileManager.default.contentsOfDirectory(at:temp,includingPropertiesForKeys:nil).filter { $0.lastPathComponent.hasPrefix("pet.recovery-") }
    try check(rawCopies.count==1 && (try Data(contentsOf:rawCopies[0]))==raw,"Recovery preserves a separate raw primary copy")
    try store.restore(second); try check(store.load().archive==second,"Explicit backup restore replaces with validated archive")
    let imported=try store.importFile(store.file); try check(imported==second,"Import validates a complete JSON backup")
    try raw.write(to:store.file); try raw.write(to:store.previous)
    try check(store.load().protected && !store.load().recoveryAvailable,"Both corrupt revisions block automatic replacement")
    let oversize=temp.appendingPathComponent("large.json"); try Data(repeating:32,count:1_048_577).write(to:oversize)
    try rejects("Import bounds size before reading") { _=try store.importFile(oversize) }
    let alias=temp.appendingPathComponent("alias.json"); try FileManager.default.createSymbolicLink(at:alias,withDestinationURL:store.previous)
    try rejects("Symbolic-link import refused") { _=try store.importFile(alias) }
    let denied=temp.appendingPathComponent("regular-file"); try Data("file".utf8).write(to:denied)
    try rejects("Unwritable save location reports failure") { try PetStore(directory:denied).save(first) }
    print("\(checks) core checks passed.")
} catch { fputs("\(error)\n",stderr); exit(1) }
