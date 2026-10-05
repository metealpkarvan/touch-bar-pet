import AppKit
import PetCore

enum Palette {
    static let paper = NSColor(calibratedRed: 0.98, green: 0.96, blue: 0.92, alpha: 1)
    static let ink = NSColor(calibratedRed: 0.17, green: 0.23, blue: 0.24, alpha: 1)
    static let muted = NSColor(calibratedRed: 0.43, green: 0.49, blue: 0.46, alpha: 1)
    static let green = NSColor(calibratedRed: 0.23, green: 0.48, blue: 0.39, alpha: 1)
    static let coral = NSColor(calibratedRed: 0.87, green: 0.43, blue: 0.31, alpha: 1)
    static let gold = NSColor(calibratedRed: 0.92, green: 0.68, blue: 0.29, alpha: 1)
    static let rail = NSColor(calibratedRed: 0.055, green: 0.09, blue: 0.10, alpha: 1)
    static func fur(_ fur: Fur) -> NSColor {
        switch fur { case .apricot: return NSColor(calibratedRed: 0.95, green: 0.68, blue: 0.43, alpha: 1)
        case .cloud: return NSColor(calibratedRed: 0.88, green: 0.88, blue: 0.81, alpha: 1)
        case .cocoa: return NSColor(calibratedRed: 0.64, green: 0.42, blue: 0.30, alpha: 1) }
    }
}
func t(_ language: Language, _ tr: String, _ en: String) -> String { language == .tr ? tr : en }
func word(_ game: MiniGame, _ language: Language) -> String {
    switch game { case .stars: return t(language, "Yıldız Topla", "Star Hunt"); case .rally: return t(language, "Top Yuvarla", "Ball Rally"); case .memory: return t(language, "İz Takibi", "Paw Pattern") }
}
func label(_ text: String, _ size: CGFloat = 13, _ color: NSColor = Palette.ink, _ weight: NSFont.Weight = .regular) -> NSTextField {
    let field = NSTextField(labelWithString: text); field.font = NSFont.systemFont(ofSize: size, weight: weight); field.textColor = color; field.lineBreakMode = .byWordWrapping; return field
}
func drawText(_ text: String, _ rect: NSRect, size: CGFloat, color: NSColor, weight: NSFont.Weight = .regular, alignment: NSTextAlignment = .left) {
    let p = NSMutableParagraphStyle(); p.alignment = alignment; p.lineBreakMode = .byTruncatingTail
    (text as NSString).draw(in: rect, withAttributes: [.font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: color, .paragraphStyle: p])
}
func fill(_ rect: NSRect, _ color: NSColor, radius: CGFloat = 0) {
    color.setFill(); NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}
func ellipse(_ rect: NSRect, _ color: NSColor) { color.setFill(); NSBezierPath(ovalIn: rect).fill() }
func line(_ a: NSPoint, _ b: NSPoint, _ color: NSColor, width: CGFloat = 1) {
    let path = NSBezierPath(); path.move(to: a); path.line(to: b); path.lineWidth = width; color.setStroke(); path.stroke()
}
func star(_ center: NSPoint, radius: CGFloat, color: NSColor) {
    let path = NSBezierPath()
    for i in 0..<10 { let angle = CGFloat(i) * .pi / 5 + .pi / 2; let r = i % 2 == 0 ? radius : radius * 0.44
        let p = NSPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r); if i == 0 { path.move(to:p) } else { path.line(to:p) } }
    path.close(); color.setFill(); path.fill()
}
/// Original vector character. This renderer is shared by the habitat, icon and Touch Bar.
func drawPet(_ rect: NSRect, archive: PetArchive, clock: Double = 0, motion: Bool = true) {
    NSGraphicsContext.saveGraphicsState()
    let transform = AffineTransform(translationByX: rect.minX, byY: rect.minY); (transform as NSAffineTransform).concat()
    let s = min(rect.width / 100, rect.height / 110)
    let scale = NSAffineTransform(); scale.scale(by: s); scale.concat()
    let bob: CGFloat = motion && !archive.sleeping ? CGFloat(sin(clock * 1.7)) * 1.5 : 0
    let fur = Palette.fur(archive.fur), dark = Palette.ink
    ellipse(NSRect(x: 12, y: 2, width: 76, height: 10), dark.withAlphaComponent(0.10))
    // Tail and body.
    let tail = NSBezierPath(); tail.move(to:NSPoint(x: 76, y: 33)); tail.curve(to:NSPoint(x:91,y:51),controlPoint1:NSPoint(x:104,y:24),controlPoint2:NSPoint(x:104,y:48)); tail.lineWidth = archive.species == .rabbit ? 11 : 9; tail.lineCapStyle = .round; fur.setStroke(); tail.stroke()
    fill(NSRect(x: 22, y: 9 + bob, width: 58, height: 55), fur, radius: 25)
    ellipse(NSRect(x: 31, y: 17 + bob, width: 38, height: 34), Palette.paper.withAlphaComponent(0.70))
    fill(NSRect(x: 21, y: 6, width: 23, height: 13), fur, radius: 6); fill(NSRect(x: 57, y: 6, width: 23, height: 13), fur, radius: 6)
    switch archive.species {
    case .cat:
        for x: CGFloat in [19, 59] {
            let ear = NSBezierPath(); ear.move(to:NSPoint(x:x,y:72+bob)); ear.line(to:NSPoint(x:x+2,y:102+bob)); ear.line(to:NSPoint(x:x+23,y:78+bob)); ear.close(); fur.setFill(); ear.fill()
            let inner = NSBezierPath(); inner.move(to:NSPoint(x:x+5,y:81+bob)); inner.line(to:NSPoint(x:x+6,y:94+bob)); inner.line(to:NSPoint(x:x+17,y:81+bob)); inner.close(); Palette.coral.withAlphaComponent(0.55).setFill(); inner.fill()
        }
    case .dog:
        fill(NSRect(x: 9, y: 49 + bob, width: 22, height: 48), fur.blended(withFraction:0.20,of:dark)!, radius: 10)
        fill(NSRect(x: 71, y: 49 + bob, width: 22, height: 48), fur.blended(withFraction:0.20,of:dark)!, radius: 10)
    case .rabbit:
        fill(NSRect(x: 26, y: 77 + bob, width: 17, height: 37), fur, radius: 9)
        fill(NSRect(x: 57, y: 77 + bob, width: 17, height: 37), fur, radius: 9)
        fill(NSRect(x: 31, y: 83 + bob, width: 7, height: 23), Palette.coral.withAlphaComponent(0.5), radius: 4)
        fill(NSRect(x: 62, y: 83 + bob, width: 7, height: 23), Palette.coral.withAlphaComponent(0.5), radius: 4)
    }
    fill(NSRect(x: 15, y: 43 + bob, width: 70, height: 51), fur, radius: 24)
    ellipse(NSRect(x: 31, y: 49 + bob, width: 39, height: 23), Palette.paper.withAlphaComponent(0.68))
    let eyesClosed = archive.sleeping || (motion && clock.truncatingRemainder(dividingBy: 5) > 4.7)
    for x: CGFloat in [34, 63] {
        if eyesClosed { line(NSPoint(x:x-3,y:72+bob),NSPoint(x:x+3,y:72+bob),dark,width:2.3) }
        else { ellipse(NSRect(x:x-2.5,y:68+bob,width:5,height:7),dark); ellipse(NSRect(x:x-1.3,y:72+bob,width:1.6,height:1.6),Palette.paper) }
    }
    ellipse(NSRect(x: 47, y: 61 + bob, width: 7, height: 5), Palette.coral)
    line(NSPoint(x:50,y:62+bob),NSPoint(x:50,y:55+bob),dark,width:1.2)
    let mouth = NSBezierPath(); mouth.move(to:NSPoint(x:43,y:56+bob)); mouth.curve(to:NSPoint(x:57,y:56+bob),controlPoint1:NSPoint(x:48,y:50+bob),controlPoint2:NSPoint(x:52,y:50+bob)); mouth.lineWidth = 1.2; dark.setStroke(); mouth.stroke()
    if archive.species == .cat { for y: CGFloat in [58,64] { line(NSPoint(x:12,y:y+bob),NSPoint(x:31,y:y-2+bob),dark.withAlphaComponent(0.4)); line(NSPoint(x:69,y:y-2+bob),NSPoint(x:88,y:y+bob),dark.withAlphaComponent(0.4)) } }
    switch archive.accessory {
    case .none: break
    case .scarf: fill(NSRect(x:23,y:41+bob,width:54,height:7),Palette.green,radius:3); fill(NSRect(x:66,y:24+bob,width:9,height:20),Palette.green,radius:3)
    case .star: star(NSPoint(x:50,y:42+bob),radius:8,color:Palette.gold)
    case .crown:
        let crown = NSBezierPath(); crown.move(to:NSPoint(x:32,y:91+bob)); crown.line(to:NSPoint(x:31,y:105+bob)); crown.line(to:NSPoint(x:42,y:99+bob)); crown.line(to:NSPoint(x:50,y:112+bob)); crown.line(to:NSPoint(x:59,y:99+bob)); crown.line(to:NSPoint(x:70,y:105+bob)); crown.line(to:NSPoint(x:68,y:91+bob)); crown.close(); Palette.gold.setFill(); crown.fill()
    }
    NSGraphicsContext.restoreGraphicsState()
}

final class HabitatView: NSView {
    var archive = PetArchive() { didSet { needsDisplay = true } }
    var world = CompanionWorld() { didSet { needsDisplay = true } }
    var onInput: ((RailInput) -> Void)?
    var gestureStart: Double?
    var clock: Double = 0 { didSet { needsDisplay = true } }
    var motion = true
    override init(frame: NSRect) { super.init(frame:frame); allowedTouchTypes = [.direct]; setAccessibilityElement(true); setAccessibilityRole(.button) }
    required init?(coder:NSCoder) { fatalError() }
    func position(_ point: NSPoint) -> Double { min(1, max(0, Double((point.x - 42) / max(1, bounds.width - 84)))) }
    override func mouseDown(with event: NSEvent) { let x=position(convert(event.locationInWindow, from:nil)); gestureStart=x; onInput?(.tap(x)) }
    override func mouseDragged(with event: NSEvent) { onInput?(.move(position(convert(event.locationInWindow, from: nil)))) }
    override func mouseUp(with event: NSEvent) { let x=position(convert(event.locationInWindow,from:nil)); if let start=gestureStart, abs(x-start)>0.03 { onInput?(.release(x)) }; gestureStart=nil }
    override func accessibilityPerformPress() -> Bool { onInput?(.tap(world.position)); return true }
    override func draw(_ dirtyRect:NSRect) {
        fill(bounds,Palette.paper,radius:16)
        let sky = NSRect(x:8,y:8,width:bounds.width-16,height:bounds.height-16)
        fill(sky,NSColor(calibratedRed:0.86,green:0.91,blue:0.83,alpha:1),radius:12)
        ellipse(NSRect(x:bounds.width-83,y:bounds.height-68,width:36,height:36),Palette.gold.withAlphaComponent(0.7))
        for x in stride(from:CGFloat(10),to:bounds.width,by:26) { line(NSPoint(x:x,y:8),NSPoint(x:x+32,y:bounds.height-8),NSColor.white.withAlphaComponent(0.13)) }
        fill(NSRect(x:8,y:8,width:bounds.width-16,height:45),Palette.green.withAlphaComponent(0.10),radius:12)
        let x = 42 + CGFloat(world.position) * (bounds.width - 84)
        drawLivingPet(NSRect(x:x-50,y:30,width:100,height:80),archive:archive,world:world,motion:motion)
        let objectX = world.carrying ? x + CGFloat(world.facing) * 42 : 42 + CGFloat(world.objectPosition) * (bounds.width - 84)
        drawPlayObject(NSPoint(x:objectX,y:world.carrying ? 73 : 36 + (motion ? CGFloat(world.objectLift) * 65 : 0)),size:17,world:world,motion:motion)
        if archive.adopted { drawText(activityName(world,archive.language),NSRect(x:18,y:bounds.height-35,width:bounds.width-36,height:20),size:12,color:Palette.green,weight:.medium) }
        for (x,y) in [(bounds.width-42,CGFloat(33)),(CGFloat(94),CGFloat(25)),(bounds.width-99,CGFloat(21))] { star(NSPoint(x:x,y:y),radius:3,color:Palette.gold) }
    }
}

final class VitalView: NSView {
    var title = "" { didSet { needsDisplay = true } }
    var value: Double = 70 { didSet { needsDisplay = true; setAccessibilityValue("\(title): \(Int(value)) / 100") } }
    var color = Palette.green
    override init(frame:NSRect) { super.init(frame:frame); setAccessibilityElement(true); setAccessibilityRole(.progressIndicator) }
    required init?(coder:NSCoder) { fatalError() }
    override func draw(_ dirtyRect:NSRect) {
        drawText(title,NSRect(x:0,y:22,width:bounds.width,height:18),size:11,color:Palette.muted,weight:.medium)
        drawText("\(Int(value))",NSRect(x:bounds.width-35,y:22,width:35,height:18),size:11,color:Palette.ink,alignment:.right)
        fill(NSRect(x:0,y:8,width:bounds.width,height:6),Palette.ink.withAlphaComponent(0.08),radius:3)
        fill(NSRect(x:0,y:8,width:bounds.width*CGFloat(value/100),height:6),color,radius:3)
    }
}

enum RailInput { case tap(Double), move(Double), release(Double), pause, pad(Int) }
final class PetRailView: NSView {
    var archive = PetArchive() { didSet { needsDisplay = true } }
    var session: GameSession? { didSet { needsDisplay = true } }
    var world = CompanionWorld() { didSet { needsDisplay = true } }
    var tool: PlaygroundTool = .follow
    var clock: Double = 0 { didSet { needsDisplay = true } }
    var motion = true
    var onInput: ((RailInput) -> Void)?
    var gestureStart: Double?
    override init(frame:NSRect) {
        super.init(frame:frame); allowedTouchTypes = [.direct]
        setAccessibilityElement(true); setAccessibilityRole(.button)
        setAccessibilityLabel("Touch Bar playground. Click or tap. Space: play, P: pause, arrows: move, 1–4: memory pads.")
    }
    required init?(coder:NSCoder) { fatalError() }
    override var acceptsFirstResponder: Bool { true }
    var arena: NSRect { NSRect(x:10,y:3,width:max(1,bounds.width-20),height:max(1,bounds.height-6)) }
    func position(_ point:NSPoint) -> Double { min(1,max(0,Double((point.x-arena.minX)/arena.width))) }
    override func mouseDown(with event:NSEvent) { window?.makeFirstResponder(self); let x=position(convert(event.locationInWindow,from:nil)); gestureStart=x; onInput?(.tap(x)) }
    override func mouseDragged(with event:NSEvent) { onInput?(.move(position(convert(event.locationInWindow,from:nil)))) }
    override func mouseUp(with event:NSEvent) { let x=position(convert(event.locationInWindow,from:nil)); if let start=gestureStart, abs(x-start)>0.03 { onInput?(.release(x)) }; gestureStart=nil }
    override func touchesBegan(with event:NSEvent) { if let touch=event.touches(matching:.began,in:self).first { let x=position(touch.location(in:self)); gestureStart=x; onInput?(.tap(x)) } }
    override func touchesMoved(with event:NSEvent) { if let touch=event.touches(matching:.touching,in:self).first { onInput?(.move(position(touch.location(in:self)))) } }
    override func touchesEnded(with event:NSEvent) { if let touch=event.touches(matching:.ended,in:self).first { let x=position(touch.location(in:self)); if let start=gestureStart, abs(x-start)>0.03 { onInput?(.release(x)) } }; gestureStart=nil }
    override func touchesCancelled(with event:NSEvent) { gestureStart=nil }
    override func keyDown(with event:NSEvent) {
        guard !event.isARepeat || [123,124].contains(event.keyCode) else { return }
        switch event.keyCode {
        case 49: onInput?(.tap(session?.player ?? world.position))
        case 123: onInput?(.move((session?.player ?? world.target)-0.08))
        case 124: onInput?(.move((session?.player ?? world.target)+0.08))
        case 53: onInput?(.pause)
        default:
            if event.charactersIgnoringModifiers?.lowercased() == "p" { onInput?(.pause) }
            else if let n = Int(event.charactersIgnoringModifiers ?? ""), (1...4).contains(n) { onInput?(.pad(n-1)) }
            else { super.keyDown(with:event) }
        }
    }
    override func accessibilityPerformPress() -> Bool { onInput?(.tap(session?.player ?? world.position)); return true }
    override func draw(_ dirtyRect:NSRect) {
        fill(bounds,Palette.rail,radius:8)
        guard let game=session else {
            NSGraphicsContext.saveGraphicsState(); NSBezierPath(rect:bounds).addClip()
            line(NSPoint(x:arena.minX,y:3),NSPoint(x:arena.maxX,y:3),Palette.green.withAlphaComponent(0.55),width:1)
            let h = min(bounds.height-3,40), w = h * 1.25
            let x = arena.minX + CGFloat(world.position) * arena.width
            drawLivingPet(NSRect(x:x-w/2,y:2,width:w,height:h),archive:archive,world:world,motion:motion)
            let objectX = world.carrying ? x + CGFloat(world.facing) * w * 0.43 : arena.minX + CGFloat(world.objectPosition) * arena.width
            drawPlayObject(NSPoint(x:objectX,y:world.carrying ? h * 0.46 : 6 + (motion ? CGFloat(world.objectLift) * (h * 0.52) : 0)),size:min(10,h * 0.35),world:world,motion:motion)
            if !archive.adopted { drawText(t(archive.language,"Önce Dost seç","Choose a pet first"),NSRect(x:arena.minX,y:arena.midY-7,width:arena.width,height:18),size:11,color:Palette.paper,alignment:.center) }
            NSGraphicsContext.restoreGraphicsState()
            return
        }
        let h=arena.height, width=arena.width
        NSGraphicsContext.saveGraphicsState(); NSBezierPath(rect:arena).addClip()
        switch game.game {
        case .stars:
            line(NSPoint(x:arena.minX,y:arena.minY+3),NSPoint(x:arena.maxX,y:arena.minY+3),Palette.green.withAlphaComponent(0.45),width:2)
            star(NSPoint(x:arena.minX+CGFloat(game.target)*width,y:arena.midY+2),radius:min(9,h*0.32),color:Palette.gold.withAlphaComponent(max(0.35,game.targetLife/1.5)))
            let size=min(28,h)
            drawPet(NSRect(x:arena.minX+CGFloat(game.player)*width-size/2,y:arena.minY,width:size,height:size),archive:archive,clock:clock,motion:false)
        case .rally:
            fill(NSRect(x:arena.minX+CGFloat(game.target)*width-width*0.10,y:arena.minY+2,width:width*0.20,height:h-4),Palette.green.withAlphaComponent(0.55),radius:4)
            ellipse(NSRect(x:arena.minX+CGFloat(game.ball)*width-6,y:arena.midY-6,width:12,height:12),Palette.gold)
            drawText("↓",NSRect(x:arena.minX+CGFloat(game.target)*width-9,y:arena.midY-8,width:18,height:20),size:14,color:Palette.paper,alignment:.center)
        case .memory:
            for i in 0..<4 {
                let colors=[Palette.coral,Palette.gold,Palette.green,NSColor(calibratedRed:0.48,green:0.62,blue:0.75,alpha:1)]
                let lit=game.shownPad==i || (game.flash==i && game.flashTime>0)
                let r=NSRect(x:arena.minX+CGFloat(i)*width/4+3,y:arena.minY+1,width:width/4-6,height:h-2)
                fill(r,colors[i].withAlphaComponent(lit ? 1 : 0.28),radius:4)
                drawText("\(i+1)",NSRect(x:r.minX,y:r.midY-8,width:r.width,height:18),size:12,color:Palette.paper,weight:.semibold,alignment:.center)
            }
        }
        if game.phase != .running {
            fill(arena,Palette.rail.withAlphaComponent(0.88),radius:6)
            let title: String
            switch game.phase { case .ready: title=t(archive.language,"Dokun · başla","Tap · start"); case .paused: title=t(archive.language,"Duraklatıldı · dokun","Paused · tap"); case .finished: title=t(archive.language,"Tur bitti · \(game.score) puan","Round over · \(game.score) points"); case .running: title="" }
            drawText(title,NSRect(x:arena.minX,y:arena.midY-8,width:arena.width,height:20),size:11,color:Palette.paper,weight:.medium,alignment:.center)
        }
        NSGraphicsContext.restoreGraphicsState()
    }
}
