import Foundation
import PetCore

func worldChecks() throws {
    var p=try pet(); p.xp=182; p.coins=217; p.best["stars"]=16; try p.wear(.scarf); _=try p.care(.meal,now:date)
    var legacy=try JSONSerialization.jsonObject(with:p.encoded()) as! [String:Any]
    legacy["version"]=1; legacy.removeValue(forKey:"playground")
    let raw=try JSONSerialization.data(withJSONObject:legacy,options:[.sortedKeys])
    let migrated=try PetArchive.decode(raw)
    try check(migrated.version==2 && migrated.playground==PlaygroundProgress(),"Version one migrates to a fresh world without inventing lifetime stats")
    var expected=p; expected.gameProgress=PlaygroundProgress()
    try check(migrated==expected,"Legacy migration preserves identity, XP, currency, needs, cosmetics and daily progress")
    try check(try PetArchive.decode(migrated.encoded())==migrated,"Migrated version two reopens without a second migration")
    let temp=FileManager.default.temporaryDirectory.appendingPathComponent("pati-migration-"+UUID().uuidString); defer { try? FileManager.default.removeItem(at:temp) }
    try FileManager.default.createDirectory(at:temp,withIntermediateDirectories:true); let store=PetStore(directory:temp); try raw.write(to:store.file)
    try check(store.load().archive==migrated && !store.load().protected,"Store opens a real legacy JSON without modifying its primary bytes")
    try check(try Data(contentsOf:store.file)==raw,"Legacy load alone is read-only")
    try store.save(migrated); try check(try Data(contentsOf:store.previous)==raw,"First version two save preserves the raw version one revision")
    legacy["version"]=2; try rejects("Version two missing world data is rejected") { _=try PetArchive.decode(JSONSerialization.data(withJSONObject:legacy)) }
    legacy["version"]=1; legacy["playground"]=(try JSONSerialization.jsonObject(with:migrated.encoded()) as! [String:Any])["playground"]
    try rejects("Ambiguous version one plus new world fields is rejected") { _=try PetArchive.decode(JSONSerialization.data(withJSONObject:legacy)) }
    p=try pet(); let initial=p
    try rejects("Unowned expensive decoration cannot overdraw the wallet") { try p.decorate(.tent) }
    try check(p==initial,"Rejected decoration leaves currency and equipped item intact")
    try p.decorate(.cushion); try check(p.coins==0 && p.gameProgress.decoration == .cushion && p.gameProgress.owned.contains(.cushion),"Decoration purchase spends exact game coins and records ownership")
    try p.decorate(.none); try p.decorate(.cushion); try check(p.coins==0,"Owned decorations can be re-equipped for free")
    p.gameProgress.scene = .seaside; p.gameProgress.daylight = .sunset; p.gameProgress.weather = .rain
    try check(try PetArchive.decode(p.encoded())==p,"Selected background, lighting, weather and purchased decor survive JSON reopen")
    try rejects("Decorations require adoption") { var fresh=PetArchive(now:date); try fresh.decorate(.none) }
    var progress=PlaygroundProgress(); progress.decoration = .tent
    try rejects("Equipped but unowned decor is rejected") { try progress.validate() }
    progress=PlaygroundProgress(); progress.owned=[.none,.none]; try rejects("Duplicate cosmetic ownership is rejected") { try progress.validate() }
    progress=PlaygroundProgress(); progress.fetches = -1; try rejects("Negative lifetime progress is rejected") { try progress.validate() }
    progress=PlaygroundProgress(); progress.challenges=1; try rejects("Challenge count cannot exceed total completed rounds") { try progress.validate() }
    progress=PlaygroundProgress(); progress.bestFetchScore=5; try rejects("Challenge best score requires a completed challenge") { try progress.validate() }
    progress=PlaygroundProgress(); progress.challengeReceipts=[UUID()]; try rejects("Receipt count cannot exceed completed challenges") { try progress.validate() }
    p=try pet(); try check(!p.claimAdventure(.firstSteps,now:date),"Unfinished adventure has no reward")
    for _ in 0..<3 { p.recordFetch() }; _=try p.care(.meal,now:date); _=try p.settle(finished(.stars),now:date)
    try check(p.gameProgress.ready(.firstSteps) && p.gameProgress.completion(.firstSteps)==1,"Actual care, fetches and completed rounds fill adventure goals")
    let wallet=p.coins,bond=p.xp
    try check(p.claimAdventure(.firstSteps,now:date) && p.coins==wallet+30 && p.xp==bond+15,"Adventure grants its exact one-time reward")
    let claimed=p; try check(!p.claimAdventure(.firstSteps,now:date) && p==claimed,"Claimed adventure cannot award twice")
    try check(p.gameProgress.nextAdventure == .playmates,"Adventure completion reveals the next chapter")
    p.gameProgress.fetches=25; p.gameProgress.meals=8; p.gameProgress.rounds=10; p.gameProgress.challenges=5
    try check(!p.claimAdventure(.explorers,now:date),"Later adventure cannot skip an unclaimed chapter")
    try check(p.claimAdventure(.playmates,now:date) && p.claimAdventure(.explorers,now:date) && p.gameProgress.nextAdventure==nil,"All chapters can be completed in order")
    try check(p.gameProgress.badges==Badge.allCases,"Seven badges follow real lifetime thresholds")
    try check(try PetArchive.decode(p.encoded())==p,"Completed adventures and badge-driving statistics survive restart")
    progress=PlaygroundProgress(); progress.claimed=[.firstSteps]; try rejects("Unmet claimed goals are rejected on import") { try progress.validate() }
    progress=p.gameProgress; progress.claimed=[.explorers]; try rejects("Out-of-order claimed adventures are rejected") { try progress.validate() }
    var challenge=FetchRound(seed:9),other=FetchRound(seed:9)
    try check(challenge.target==other.target && (0.15...0.85).contains(challenge.target),"Fetch targets are seeded and bounded")
    challenge.throwAt(0.8); try check(challenge.attempt==nil && challenge.returned()==0,"Ready challenge cannot score or accept throws")
    challenge.start(); challenge.throwAt(.nan); challenge.throwAt(.infinity); challenge.throwAt(-1)
    try check(challenge.attempt==nil,"Invalid challenge coordinates cannot create an attempt")
    let target=challenge.target; challenge.throwAt(target); try check(challenge.score==0,"Throwing at a target never scores before a return")
    try check(challenge.returned()==5 && challenge.perfect==1 && challenge.catches==1,"Accurate completed fetch scores five and moves the target")
    try check(challenge.returned()==0 && challenge.score==5,"A single return cannot be counted twice")
    challenge.throwAt(challenge.target<0.5 ? 0.95 : 0.05); try check(challenge.returned()==3 && challenge.score==8,"Off-target completed fetch still scores three")
    challenge.throwAt(challenge.target); challenge.cancelThrow(); try check(challenge.returned()==0,"Cancelled throws never score")
    challenge.tick(0.05); let elapsed=challenge.elapsed; challenge.pause(); challenge.tick(100)
    try check(challenge.elapsed==elapsed,"Pausing freezes challenge reward time")
    challenge.resume(); challenge.tick(100); try check(abs(challenge.elapsed-elapsed-0.05)<0.000001,"Challenge cannot fast-forward after a long frame gap")
    let before=challenge.elapsed; challenge.tick(-1); challenge.tick(.nan); challenge.tick(.infinity); try check(challenge.elapsed==before,"Nonfinite challenge time is ignored")
    p=try pet(); try rejects("Unfinished challenge cannot pay") { _=try p.settleFetch(challenge,now:date) }
    challenge.throwAt(challenge.target); for _ in 0..<600 { challenge.tick(0.05) }
    try check(challenge.phase == .finished && challenge.elapsed==30 && challenge.secondsLeft==0 && challenge.attempt==nil,"Thirty active seconds finish and discard an unfinished throw")
    try check(challenge.returned()==0 && challenge.score==8,"A return after the deadline cannot change the score")
    try check(try p.settleFetch(challenge,now:date),"Finished challenge settles once")
    try check(p.gameProgress.challenges==1 && p.gameProgress.rounds==1 && p.gameProgress.bestFetchScore==8 && p.daily.games==1,"Challenge settlement updates lifetime stats, best score and daily goals")
    try check(p.coins==51 && p.xp==12,"Challenge reward equals eight plus bounded score coins and XP")
    let paid=p; try check(try !p.settleFetch(challenge,now:date) && p==paid,"Challenge receipt blocks duplicate rewards")
    var reopened=try PetArchive.decode(p.encoded()); try check(try !reopened.settleFetch(challenge,now:date) && reopened==p,"Challenge receipt survives export and reopen")
    other.start(); for _ in 0..<600 { other.tick(0.05) }; _=try p.settleFetch(other,now:date)
    try check(p.gameProgress.bestFetchScore==8 && p.gameProgress.challenges==2,"A lower later round preserves the personal best")
    var short=CompanionWorld(); _=short.throwToy(.ball,toward:0.5,allowShort:true)
    try check(short.target==0.5,"Challenge throws honor nearby target positions")
}
