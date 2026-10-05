import Foundation

public enum PetError: Error, CustomStringConvertible {
    case invalid(String), locked(String)
    public var description: String { switch self { case .invalid(let s), .locked(let s): return s } }
}
public enum Species: String, Codable, CaseIterable { case cat, dog, rabbit }
public enum Fur: String, Codable, CaseIterable { case apricot, cloud, cocoa }
public enum Accessory: String, Codable, CaseIterable {
    case none, scarf, star, crown
    public var requiredLevel: Int { switch self { case .none: return 1; case .scarf: return 2; case .star: return 3; case .crown: return 5 } }
}
public enum Care: String, CaseIterable { case meal, wash, cuddle, rest, snack }
public enum MiniGame: String, Codable, CaseIterable { case stars, rally, memory }
public enum Language: String, Codable { case tr, en }
public enum Phase: String { case ready, running, paused, finished }

public struct Needs: Codable, Equatable {
    public var food: Double = 72
    public var joy: Double = 76
    public var energy: Double = 82
    public var clean: Double = 68
    public init() {}
    public var values: [Double] { [food, joy, energy, clean] }
}
public struct Daily: Codable, Equatable {
    public var key: String
    public var meals = 0
    public var washes = 0
    public var games = 0
    public var claimed = false
    public init(key: String) { self.key = key }
    public var completed: Int { (meals > 0 ? 1 : 0) + (washes > 0 ? 1 : 0) + (games > 0 ? 1 : 0) }
}
public struct JournalEntry: Codable, Equatable {
    public var date: Date
    public var event: String
    public var amount: Int
    public init(date: Date, event: String, amount: Int = 0) { self.date = date; self.event = event; self.amount = amount }
}
public struct PetArchive: Codable, Equatable {
    public var version = 2
    public var id = UUID()
    public var adopted = false
    public var name = "Misket"
    public var species: Species = .cat
    public var fur: Fur = .apricot
    public var accessory: Accessory = .none
    public var language: Language = .tr
    public var needs = Needs()
    public var sleeping = false
    public var xp = 0
    public var coins = 35
    public var createdAt: Date
    public var updatedAt: Date
    public var careRewards: [String: Date] = [:]
    public var best: [String: Int] = [:]
    public var gameReceipts: [UUID] = []
    public var daily: Daily
    public var journal: [JournalEntry] = []
    public var playground: PlaygroundProgress? = PlaygroundProgress()
    public init(now: Date = Date()) { createdAt = now; updatedAt = now; daily = Daily(key: Self.dayKey(now)) }
    public var level: Int { min(50, 1 + xp / 75) }
    public var levelProgress: Double { level == 50 ? 1 : Double(xp % 75) / 75 }
    public static func dayKey(_ date: Date, zone: TimeZone = .current) -> String {
        let format = DateFormatter(); format.locale = Locale(identifier: "en_US_POSIX")
        format.calendar = Calendar(identifier: .gregorian); format.timeZone = zone; format.dateFormat = "yyyy-MM-dd"
        return format.string(from: date)
    }
    public mutating func note(_ event: String, at date: Date, amount: Int = 0) {
        journal.append(JournalEntry(date: date, event: event, amount: amount)); journal = Array(journal.suffix(40))
    }
    public mutating func adopt(name: String, species: Species, fur: Fur, now: Date) throws {
        guard !adopted else { throw PetError.invalid("Already adopted") }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 24, !trimmed.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) else { throw PetError.invalid("Name must contain 1–24 printable characters") }
        self.name = trimmed; self.species = species; self.fur = fur; adopted = true
        createdAt = now; updatedAt = now; daily = Daily(key: Self.dayKey(now)); note("adopt", at: now)
    }
    /// Only eight absent hours affect needs. XP, coins, best scores and identity never decay.
    @discardableResult public mutating func advance(to now: Date) -> Double {
        guard now.timeIntervalSince1970.isFinite, adopted else { return 0 }
        let seconds = min(8 * 3600, max(0, now.timeIntervalSince(updatedAt)))
        let hours = seconds / 3600
        needs.food = max(20, needs.food - hours * 3)
        needs.joy = max(25, needs.joy - hours * 2)
        needs.clean = max(25, needs.clean - hours * 1.5)
        needs.energy = sleeping ? min(100, needs.energy + hours * 12) : max(25, needs.energy - hours * 2)
        if now > updatedAt { updatedAt = now }
        let key = Self.dayKey(now)
        // A clock rollback cannot recreate already claimed daily rewards.
        if key > daily.key { daily = Daily(key: key) }
        return seconds
    }
    @discardableResult public mutating func care(_ action: Care, now: Date) throws -> Int {
        guard adopted else { throw PetError.invalid("Adopt a pet first") }
        advance(to: now)
        if action == .rest { sleeping.toggle(); note(sleeping ? "sleep" : "wake", at: now); return 0 }
        let before = needs
        switch action {
        case .meal: needs.food = min(100, needs.food + 28); needs.energy = min(100, needs.energy + 4)
        case .wash: needs.clean = min(100, needs.clean + 35); needs.joy = min(100, needs.joy + 4)
        case .cuddle: needs.joy = min(100, needs.joy + 20)
        case .snack:
            guard coins >= 15 else { throw PetError.invalid("Not enough coins") }
            guard needs.food < 98 || needs.joy < 98 || needs.energy < 98 else { return 0 }
            coins -= 15; needs.food = min(100, needs.food + 20); needs.joy = min(100, needs.joy + 12); needs.energy = min(100, needs.energy + 8)
        case .rest: break
        }
        if action == .meal || action == .snack { daily.meals = min(1000, daily.meals + 1) }
        if action == .meal || action == .snack { var p=gameProgress; p.meals=min(1_000_000,p.meals+1); gameProgress=p }
        if action == .wash { daily.washes = min(1000, daily.washes + 1) }
        let gain = zip(needs.values, before.values).reduce(0.0) { $0 + max(0, $1.0 - $1.1) }
        let elapsed = careRewards[action.rawValue].map { now.timeIntervalSince($0) } ?? .infinity
        let reward = gain >= 2 && elapsed >= 60 ? 3 : 0
        if reward > 0 { xp = min(1_000_000, xp + reward); coins = min(1_000_000, coins + 2); careRewards[action.rawValue] = now }
        note(action.rawValue, at: now, amount: reward)
        return reward
    }
    public mutating func wear(_ item: Accessory) throws {
        guard level >= item.requiredLevel else { throw PetError.invalid("Accessory not unlocked") }; accessory = item
    }
    @discardableResult public mutating func claimDaily(now: Date) -> Bool {
        advance(to: now)
        guard adopted, daily.completed == 3, !daily.claimed else { return false }
        daily.claimed = true; xp = min(1_000_000, xp + 20); coins = min(1_000_000, coins + 40); note("daily", at: now, amount: 40); return true
    }
    /// A completed round is settled once. Abandoned/paused rounds have no reward.
    @discardableResult public mutating func settle(_ round: GameSession, now: Date) throws -> Bool {
        guard adopted, round.phase == .finished, round.elapsed >= GameSession.duration, round.score >= 0, round.score <= 999 else { throw PetError.invalid("Round is not finished") }
        guard !gameReceipts.contains(round.id) else { return false }
        advance(to: now)
        gameReceipts.append(round.id); gameReceipts = Array(gameReceipts.suffix(100))
        best[round.game.rawValue] = max(best[round.game.rawValue] ?? 0, round.score)
        xp = min(1_000_000, xp + 6 + min(30, round.score / 2))
        let reward = 6 + min(60, round.score)
        coins = min(1_000_000, coins + reward); needs.joy = min(100, needs.joy + 18)
        needs.energy = max(20, needs.energy - 8); daily.games = min(1000, daily.games + 1)
        var p=gameProgress; p.rounds=min(1_000_000,p.rounds+1); gameProgress=p
        note("game." + round.game.rawValue, at: now, amount: round.score); return true
    }
    public func validate() throws {
        func require(_ c: Bool, _ s: String) throws { if !c { throw PetError.invalid(s) } }
        try require(version == 2, "Unsupported save version")
        guard let playground=playground else { throw PetError.invalid("Missing playground progress") }
        try playground.validate()
        try require(!name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && name.count <= 24 && !name.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }), "Invalid pet name")
        try require(needs.values.allSatisfy { $0.isFinite && (0...100).contains($0) }, "Invalid needs")
        try require((0...1_000_000).contains(xp) && (0...1_000_000).contains(coins), "Invalid progress")
        try require(accessory.requiredLevel <= level, "Locked accessory")
        try require(best.count <= 3 && best.allSatisfy { MiniGame(rawValue: $0.key) != nil && (0...999).contains($0.value) }, "Invalid scores")
        try require(careRewards.count <= 4 && careRewards.keys.allSatisfy { ["meal", "wash", "cuddle", "snack"].contains($0) }, "Invalid care history")
        try require(gameReceipts.count <= 100 && Set(gameReceipts).count == gameReceipts.count, "Invalid receipts")
        let format = DateFormatter(); format.locale = Locale(identifier: "en_US_POSIX"); format.calendar = Calendar(identifier: .gregorian); format.timeZone = TimeZone(secondsFromGMT: 0); format.dateFormat = "yyyy-MM-dd"; format.isLenient = false
        try require(daily.key.count == 10 && format.date(from: daily.key).map { Self.dayKey($0, zone: TimeZone(secondsFromGMT: 0)!) == daily.key } == true, "Invalid daily date")
        try require([daily.meals, daily.washes, daily.games].allSatisfy { (0...1000).contains($0) }, "Invalid daily progress")
        let events = Set(["adopt", "meal", "wash", "cuddle", "sleep", "wake", "snack", "daily", "adventure", "game.fetch"] + MiniGame.allCases.map { "game." + $0.rawValue })
        try require(journal.count <= 40 && journal.allSatisfy { events.contains($0.event) && (0...999).contains($0.amount) }, "Invalid journal")
        let dates = [createdAt, updatedAt] + Array(careRewards.values) + journal.map { $0.date }
        try require(dates.allSatisfy { $0.timeIntervalSince1970.isFinite && (946_684_800...4_102_444_800).contains($0.timeIntervalSince1970) }, "Invalid timestamp")
    }
    public func encoded() throws -> Data {
        try validate(); let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601; encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; return try encoder.encode(self)
    }
    public static func decode(_ data: Data) throws -> PetArchive {
        guard data.count <= 1_048_576 else { throw PetError.invalid("Save larger than 1 MB") }
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        var archive = try decoder.decode(PetArchive.self, from: data)
        if archive.version == 1 {
            guard archive.playground == nil else { throw PetError.invalid("Unexpected playground data in legacy save") }
            archive.version=2; archive.playground=PlaygroundProgress()
        }
        try archive.validate(); return archive
    }
}

public struct GameSession {
    public static let duration: Double = 24
    public let id: UUID
    public let game: MiniGame
    public private(set) var phase: Phase = .ready
    public private(set) var elapsed: Double = 0
    public private(set) var score = 0
    public private(set) var hits = 0
    public private(set) var misses = 0
    public private(set) var player: Double = 0.5
    public private(set) var target: Double = 0.5
    public private(set) var ball: Double = 0.08
    public private(set) var targetLife: Double = 1.5
    public private(set) var sequence: [Int] = []
    public private(set) var showing = true
    public private(set) var sequenceClock: Double = 0
    public private(set) var inputIndex = 0
    public private(set) var flash: Int? = nil
    public private(set) var flashTime: Double = 0
    private var seed: UInt64
    private var ballDirection: Double = 1
    private var tapCooldown: Double = 0
    public init(game: MiniGame, seed: UInt64 = 42, id: UUID = UUID()) {
        self.game = game; self.seed = seed; self.id = id
        target = 0.16 + random() * 0.68
        if game == .memory { newSequence(length: 2) }
    }
    private mutating func random() -> Double { seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407; return Double(seed >> 11) / Double(UInt64.max >> 11) }
    private mutating func newSequence(length: Int) {
        sequence = (0..<length).map { _ in min(3, Int(random() * 4)) }; showing = true; sequenceClock = 0; inputIndex = 0
    }
    public var shownPad: Int? {
        guard game == .memory, showing else { return nil }
        let index = Int(sequenceClock / 0.7)
        return index < sequence.count && sequenceClock.truncatingRemainder(dividingBy: 0.7) < 0.46 ? sequence[index] : nil
    }
    public var secondsLeft: Int { Int(ceil(max(0, Self.duration - elapsed))) }
    public mutating func start() { if phase == .ready { phase = .running } }
    public mutating func pause() { if phase == .running { phase = .paused } }
    public mutating func resume() { if phase == .paused { phase = .running } }
    public mutating func move(_ x: Double) { guard x.isFinite, phase == .running else { return }; player = min(1, max(0, x)) }
    public mutating func tick(_ delta: Double) {
        guard phase == .running, delta.isFinite, delta > 0 else { return }
        let dt = min(0.1, delta)
        elapsed = min(Self.duration, elapsed + dt); tapCooldown = max(0, tapCooldown - dt); flashTime = max(0, flashTime - dt)
        if flashTime == 0 { flash = nil }
        switch game {
        case .stars:
            targetLife -= dt
            if targetLife <= 0 { misses += 1; target = 0.10 + random() * 0.80; targetLife = 1.5 }
        case .rally:
            ball += dt * 0.68 * ballDirection
            if ball >= 0.96 { ball = 0.96; ballDirection = -1 }
            if ball <= 0.04 { ball = 0.04; ballDirection = 1 }
        case .memory:
            if showing {
                sequenceClock += dt
                if sequenceClock >= Double(sequence.count) * 0.7 + 0.3 { showing = false }
            }
        }
        if elapsed >= Self.duration - 0.000001 { elapsed = Self.duration; phase = .finished }
    }
    @discardableResult public mutating func tap(_ x: Double) -> Bool {
        guard phase == .running, x.isFinite, (0...1).contains(x), tapCooldown <= 0 else { return false }
        switch game {
        case .stars:
            player = x; tapCooldown = 0.18
            if abs(x - target) <= 0.08 { score = min(999, score + 4); hits += 1; target = 0.1 + random() * 0.8; targetLife = 1.5; return true }
            misses += 1; return false
        case .rally:
            tapCooldown = 0.3
            if abs(ball - target) <= 0.10 { score = min(999, score + 3); hits += 1; target = 0.15 + random() * 0.7; return true }
            misses += 1; return false
        case .memory:
            guard !showing else { return false }
            tapCooldown = 0.16
            let pad = min(3, Int(x * 4)); flash = pad; flashTime = 0.22
            if pad == sequence[inputIndex] {
                inputIndex += 1
                if inputIndex == sequence.count { score = min(999, score + sequence.count * 3); hits += 1; newSequence(length: min(5, sequence.count + 1)) }
                return true
            }
            misses += 1; newSequence(length: max(2, sequence.count - 1)); return false
        }
    }
}

public struct LoadReport {
    public let archive: PetArchive?
    public let protected: Bool
    public let recoveryAvailable: Bool
    public let message: String?
}
public final class PetStore {
    public let directory: URL
    public var file: URL { directory.appendingPathComponent("pet.json") }
    public var previous: URL { directory.appendingPathComponent("pet.previous.json") }
    public init(directory: URL) { self.directory = directory }
    private func read(_ url: URL) throws -> Data {
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        guard attrs[.type] as? FileAttributeType == .typeRegular, ((attrs[.size] as? NSNumber)?.intValue ?? Int.max) <= 1_048_576 else { throw PetError.invalid("Unsafe or oversized save file") }
        return try Data(contentsOf: url)
    }
    public func load() -> LoadReport {
        guard FileManager.default.fileExists(atPath: file.path) else {
            if FileManager.default.fileExists(atPath: previous.path) {
                let recovered = try? PetArchive.decode(read(previous))
                return LoadReport(archive: recovered, protected: true, recoveryAvailable: recovered != nil, message: "Primary save is missing")
            }
            return LoadReport(archive: nil, protected: false, recoveryAvailable: false, message: nil)
        }
        do { return LoadReport(archive: try PetArchive.decode(read(file)), protected: false, recoveryAvailable: false, message: nil) }
        catch {
            let recovered = try? PetArchive.decode(read(previous))
            return LoadReport(archive: recovered, protected: true, recoveryAvailable: recovered != nil, message: String(describing: error))
        }
    }
    public func save(_ archive: PetArchive) throws {
        let data = try archive.encoded()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        if FileManager.default.fileExists(atPath: file.path) {
            let existing = try read(file); _ = try PetArchive.decode(existing)
            try existing.write(to: previous, options: .atomic)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: previous.path)
        }
        try data.write(to: file, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
    }
    /// Explicit restore preserves any existing raw primary before replacing it.
    @discardableResult public func restore(_ archive: PetArchive) throws -> URL? {
        let data = try archive.encoded()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        var rawCopy: URL?
        if FileManager.default.fileExists(atPath: file.path) {
            let attrs = try FileManager.default.attributesOfItem(atPath: file.path)
            guard attrs[.type] as? FileAttributeType == .typeRegular else { throw PetError.locked("Save path is not a regular file") }
            let destination = directory.appendingPathComponent("pet.recovery-" + UUID().uuidString + ".json")
            try FileManager.default.copyItem(at: file, to: destination); rawCopy = destination
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: destination.path)
        }
        try data.write(to: file, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
        return rawCopy
    }
    public func recoverPrevious() throws -> PetArchive {
        let archive = try PetArchive.decode(read(previous)); try restore(archive); return archive
    }
    public func importFile(_ url: URL) throws -> PetArchive { try PetArchive.decode(read(url)) }
}
