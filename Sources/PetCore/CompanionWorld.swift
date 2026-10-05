import Foundation

public enum PlaygroundTool: String, CaseIterable { case follow, ball, bone, food }
public enum PlayObject: String { case ball, bone, meal, treat }
public enum CompanionActivity: String { case idle, walking, running, chasing, returning, eating, cuddling, washing, celebrating, sleeping }
public enum CompanionEvent: Equatable { case meal, treat, cuddle, wash, fetched(PlayObject) }

/// A transient, deterministic playground. Existing version-1 pet saves remain unchanged.
/// Care is emitted only after eating/interaction; fetching only after the toy comes back.
public struct CompanionWorld {
    public private(set) var position: Double = 0.5
    public private(set) var target: Double = 0.5
    public private(set) var facing: Double = 1
    public private(set) var activity: CompanionActivity = .idle
    public private(set) var object: PlayObject?
    public private(set) var objectPosition: Double = 0.5
    public private(set) var objectLift: Double = 0
    public private(set) var objectRotation: Double = 0
    public private(set) var clock: Double = 0
    public private(set) var activityTime: Double = 0
    public private(set) var completedFetches = 0
    private var ownerPosition: Double = 0.5
    private var flightStart: Double = 0.5
    private var flightTime: Double = 0
    private var flightDuration: Double = 0
    private var pending: CompanionEvent?
    private var seed: UInt64
    public init(seed: UInt64 = 73) { self.seed = seed }
    public var moving: Bool { [.walking, .running, .chasing, .returning].contains(activity) }
    public var carrying: Bool { activity == .returning }
    public var careInProgress: Bool { pending != nil && activity != .celebrating }
    public var eatingProgress: Double { activity == .eating ? min(1, activityTime / 1.3) : 0 }
    public var flightProgress: Double { flightDuration > 0 ? min(1, flightTime / flightDuration) : 1 }
    public var isFlying: Bool { object != nil && flightTime < flightDuration }
    private func bounded(_ x: Double) -> Double { min(0.95, max(0.05, x)) }
    private mutating func enter(_ state: CompanionActivity) { activity = state; activityTime = 0 }
    public mutating func cancel() {
        object = nil; objectLift = 0; pending = nil; flightDuration = 0; flightTime = 0
        target = position; enter(.idle)
    }
    public mutating func sleep(_ sleeping: Bool) {
        if sleeping && activity != .sleeping { cancel(); enter(.sleeping) }
        else if !sleeping && activity == .sleeping { enter(.idle) }
    }
    @discardableResult public mutating func follow(_ x: Double) -> Bool {
        guard x.isFinite, activity != .sleeping, !careInProgress else { return false }
        cancel(); target = bounded(x)
        enter(abs(target - position) > 0.28 ? .running : .walking)
        return true
    }
    @discardableResult public mutating func throwToy(_ kind: PlayObject, toward x: Double) -> Bool {
        guard [.ball, .bone].contains(kind), x.isFinite, activity != .sleeping, !careInProgress else { return false }
        cancel(); object = kind; ownerPosition = position; flightStart = position
        target = bounded(x); objectPosition = position
        // A tap beside the pet still produces a useful, bounded throw.
        if abs(target - position) < 0.12 { target = position < 0.5 ? 0.82 : 0.18 }
        flightDuration = 0.55 + abs(target - position) * 0.4; flightTime = 0
        enter(.chasing); return true
    }
    @discardableResult public mutating func feed(at x: Double, treat: Bool = false) -> Bool {
        guard x.isFinite, activity != .sleeping, !careInProgress else { return false }
        cancel(); target = bounded(x); object = treat ? .treat : .meal
        objectPosition = target; pending = treat ? .treat : .meal
        enter(.walking); return true
    }
    @discardableResult public mutating func cuddle() -> Bool {
        guard activity != .sleeping, !careInProgress else { return false }
        cancel(); pending = .cuddle; enter(.cuddling); return true
    }
    @discardableResult public mutating func wash() -> Bool {
        guard activity != .sleeping, !careInProgress else { return false }
        cancel(); pending = .wash; enter(.washing); return true
    }
    private mutating func move(to destination: Double, speed: Double, delta: Double) -> Bool {
        let distance = destination - position
        if abs(distance) <= 0.002 { position = destination; return true }
        facing = distance >= 0 ? 1 : -1
        position = bounded(position + facing * min(abs(distance), speed * delta))
        return abs(destination - position) <= 0.002
    }
    private mutating func random() -> Double {
        seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Double(seed >> 11) / Double(UInt64.max >> 11)
    }
    /// Frames are capped; focus loss cannot fast-forward an interaction or its reward.
    public mutating func tick(_ delta: Double, roaming: Bool = true) -> [CompanionEvent] {
        guard delta.isFinite, delta > 0, activity != .sleeping else { return [] }
        let dt = min(0.05, delta); clock += dt; activityTime += dt
        if isFlying {
            flightTime = min(flightDuration, flightTime + dt)
            let p = flightProgress
            objectPosition = flightStart + (target - flightStart) * p
            objectLift = sin(p * .pi); objectRotation = p * .pi * 4
        }
        switch activity {
        case .idle:
            if roaming && activityTime >= 3.8 {
                target = 0.12 + random() * 0.76
                if abs(target - position) < 0.18 { target = position < 0.5 ? 0.84 : 0.16 }
                enter(.walking)
            }
        case .walking, .running:
            if move(to: target, speed: activity == .running ? 0.42 : 0.16, delta: dt) {
                enter(pending == .meal || pending == .treat ? .eating : .idle)
            }
        case .chasing:
            if move(to: target, speed: 0.48, delta: dt) && !isFlying {
                target = ownerPosition; objectLift = 0; enter(.returning)
            }
        case .returning:
            let arrived = move(to: ownerPosition, speed: 0.34, delta: dt)
            objectPosition = bounded(position + facing * 0.025)
            if arrived { enter(.celebrating) }
        case .eating:
            if activityTime >= 1.3, let event = pending { cancel(); return [event] }
        case .cuddling, .washing:
            if activityTime >= (activity == .washing ? 1.0 : 0.65), let event = pending { cancel(); return [event] }
        case .celebrating:
            if activityTime >= 0.65, let toy = object {
                completedFetches += 1; cancel(); return [.fetched(toy)]
            }
        case .sleeping: break
        }
        return []
    }
}
