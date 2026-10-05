import Foundation

public enum SceneTheme: String, Codable, CaseIterable { case garden, seaside, room, moonlight, snowfield }
public enum Daylight: String, Codable, CaseIterable { case day, sunset, night }
public enum SceneWeather: String, Codable, CaseIterable { case clear, rain, snow }
public enum Decoration: String, Codable, CaseIterable {
    case none, cushion, flowers, lantern, tent
    public var cost: Int { switch self { case .none: return 0; case .cushion: return 35; case .flowers: return 50; case .lantern: return 70; case .tent: return 95 } }
}
public enum Adventure: String, Codable, CaseIterable {
    case firstSteps, playmates, explorers
    public var goals: (fetches:Int, meals:Int, rounds:Int, challenges:Int) {
        switch self { case .firstSteps: return (3,1,1,0); case .playmates: return (10,3,3,1); case .explorers: return (25,8,10,3) }
    }
    public var coins: Int { switch self { case .firstSteps: return 30; case .playmates: return 55; case .explorers: return 90 } }
    public var xp: Int { switch self { case .firstSteps: return 15; case .playmates: return 25; case .explorers: return 40 } }
}
public enum Badge: String, CaseIterable { case firstFetch, tenFetches, twentyFiveFetches, fiveMeals, threeRounds, firstChallenge, fiveChallenges }
public struct PlaygroundProgress: Codable, Equatable {
    public var scene: SceneTheme = .garden
    public var daylight: Daylight = .day
    public var weather: SceneWeather = .clear
    public var decoration: Decoration = .none
    public var owned: [Decoration] = [.none]
    public var fetches = 0
    public var meals = 0
    public var rounds = 0
    public var challenges = 0
    public var bestFetchScore = 0
    public var claimed: [Adventure] = []
    public var challengeReceipts: [UUID] = []
    public init() {}
    public var badges: [Badge] {
        var result:[Badge]=[]
        if fetches >= 1 { result.append(.firstFetch) }; if fetches >= 10 { result.append(.tenFetches) }; if fetches >= 25 { result.append(.twentyFiveFetches) }
        if meals >= 5 { result.append(.fiveMeals) }; if rounds >= 3 { result.append(.threeRounds) }
        if challenges >= 1 { result.append(.firstChallenge) }; if challenges >= 5 { result.append(.fiveChallenges) }
        return result
    }
    public var nextAdventure: Adventure? { Adventure.allCases.first { !claimed.contains($0) } }
    public func ready(_ adventure:Adventure)->Bool {
        let g=adventure.goals
        return fetches>=g.fetches && meals>=g.meals && rounds>=g.rounds && challenges>=g.challenges
    }
    public func completion(_ adventure:Adventure)->Double {
        let g=adventure.goals
        let pairs=[(fetches,g.fetches),(meals,g.meals),(rounds,g.rounds),(challenges,g.challenges)].filter { $0.1>0 }
        return pairs.map { min(1,Double($0.0)/Double($0.1)) }.reduce(0,+)/Double(pairs.count)
    }
    public func validate() throws {
        guard [fetches,meals,rounds,challenges].allSatisfy({(0...1_000_000).contains($0)}), (0...999).contains(bestFetchScore), challenges<=rounds,
              owned.count<=Decoration.allCases.count, Set(owned).count==owned.count, owned.contains(.none), owned.contains(decoration),
              claimed.count<=3, Set(claimed).count==claimed.count, claimed.allSatisfy({ready($0)}),
              claimed == Array(Adventure.allCases.prefix(claimed.count)),
              challengeReceipts.count<=100, challengeReceipts.count<=challenges, Set(challengeReceipts).count==challengeReceipts.count,
              challenges>0 || bestFetchScore==0 else { throw PetError.invalid("Invalid playground progress") }
    }
}

/// A skill-based fetch round. A throw is judged at pickup/return completion, never at launch.
public struct FetchRound {
    public static let duration: Double = 30
    public let id: UUID
    public private(set) var phase: Phase = .ready
    public private(set) var elapsed: Double = 0
    public private(set) var score = 0
    public private(set) var catches = 0
    public private(set) var perfect = 0
    public private(set) var target: Double = 0.75
    public private(set) var attempt: Double?
    private var attemptTarget: Double = 0.75
    private var seed: UInt64
    public init(seed:UInt64=91,id:UUID=UUID()) { self.seed=seed; self.id=id; changeTarget() }
    private mutating func changeTarget() {
        seed=seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        target=0.15+Double(seed>>11)/Double(UInt64.max>>11)*0.7
    }
    public var secondsLeft: Int { Int(ceil(max(0,Self.duration-elapsed))) }
    public mutating func start() { if phase == .ready { phase = .running } }
    public mutating func pause() { if phase == .running { phase = .paused } }
    public mutating func resume() { if phase == .paused { phase = .running } }
    public mutating func throwAt(_ x:Double) { guard phase == .running, x.isFinite, (0.05...0.95).contains(x) else { return }; attempt=x; attemptTarget=target }
    @discardableResult public mutating func returned()->Int {
        guard phase == .running, let landing=attempt else { return 0 }
        let accurate=abs(landing-attemptTarget)<=0.10
        let points=accurate ? 5 : 3
        catches+=1; if accurate { perfect+=1 }; score=min(999,score+points)
        attempt=nil; changeTarget(); return points
    }
    public mutating func cancelThrow() { attempt=nil }
    public mutating func tick(_ delta:Double) {
        guard phase == .running, delta.isFinite, delta>0 else { return }
        elapsed=min(Self.duration,elapsed+min(0.05,delta))
        if elapsed>=Self.duration-0.000001 { elapsed=Self.duration; phase = .finished; attempt=nil }
    }
}

extension PetArchive {
    public var gameProgress: PlaygroundProgress {
        get { playground ?? PlaygroundProgress() }
        set { playground=newValue }
    }
    public mutating func decorate(_ decoration:Decoration) throws {
        guard adopted else { throw PetError.invalid("Adopt a pet first") }
        var p=gameProgress
        if !p.owned.contains(decoration) {
            guard coins>=decoration.cost else { throw PetError.locked("Not enough paw coins") }
            coins-=decoration.cost; p.owned.append(decoration)
        }
        p.decoration=decoration; gameProgress=p
    }
    public mutating func recordFetch() { guard adopted else { return }; var p=gameProgress; p.fetches=min(1_000_000,p.fetches+1); gameProgress=p }
    @discardableResult public mutating func claimAdventure(_ adventure:Adventure,now:Date)->Bool {
        var p=gameProgress
        guard adopted, p.nextAdventure==adventure, p.ready(adventure) else { return false }
        p.claimed.append(adventure); gameProgress=p
        coins=min(1_000_000,coins+adventure.coins); xp=min(1_000_000,xp+adventure.xp)
        note("adventure",at:now,amount:adventure.coins); return true
    }
    @discardableResult public mutating func settleFetch(_ round:FetchRound,now:Date)throws->Bool {
        guard adopted, round.phase == .finished, round.elapsed>=FetchRound.duration else { throw PetError.invalid("Fetch round is unfinished") }
        var p=gameProgress
        guard !p.challengeReceipts.contains(round.id) else { return false }
        advance(to:now); p.challengeReceipts.append(round.id); p.challengeReceipts=Array(p.challengeReceipts.suffix(100))
        p.challenges=min(1_000_000,p.challenges+1); p.rounds=min(1_000_000,p.rounds+1); p.bestFetchScore=max(p.bestFetchScore,round.score); gameProgress=p
        coins=min(1_000_000,coins+8+min(40,round.score)); xp=min(1_000_000,xp+8+min(25,round.score/2))
        needs.joy=min(100,needs.joy+12); needs.energy=max(20,needs.energy-6); daily.games=min(1000,daily.games+1)
        note("game.fetch",at:now,amount:round.score); return true
    }
}
