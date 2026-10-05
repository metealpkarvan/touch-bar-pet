import AppKit
import PetCore

func toolName(_ tool: PlaygroundTool, _ language: Language) -> String {
    switch tool {
    case .follow: return t(language, "Takip", "Follow")
    case .ball: return t(language, "Top", "Ball")
    case .bone: return t(language, "Kemik", "Bone")
    case .food: return t(language, "Mama bırak", "Place food")
    }
}
func activityName(_ world: CompanionWorld, _ language: Language) -> String {
    switch world.activity {
    case .idle: return t(language, "Etrafı izliyor", "Looking around")
    case .walking: return t(language, world.careInProgress ? "Mamaya gidiyor" : "Geziniyor", world.careInProgress ? "Walking to food" : "Walking")
    case .running: return t(language, "Yanına koşuyor", "Running to you")
    case .chasing: return t(language, "Oyuncağı kovalıyor", "Chasing the toy")
    case .returning: return t(language, "Sana geri getiriyor", "Bringing it back")
    case .eating: return t(language, "Afiyetle yiyor", "Enjoying a meal")
    case .cuddling: return t(language, "Sevilmenin keyfi", "Enjoying a cuddle")
    case .washing: return t(language, "Pırıl pırıl oluyor", "Getting clean")
    case .celebrating: return t(language, "Bir daha oynayalım!", "Let's play again!")
    case .sleeping: return t(language, "Dinleniyor", "Resting")
    }
}

/// Original side-view character with four articulated paws, species ears and a wagging tail.
/// Translation always communicates input; Reduce Motion suppresses decorative movement.
func drawLivingPet(_ rect: NSRect, archive: PetArchive, world: CompanionWorld, motion: Bool) {
    NSGraphicsContext.saveGraphicsState()
    let transform = NSAffineTransform(); transform.translateX(by: rect.minX, yBy: rect.minY)
    transform.scale(by: min(rect.width / 100, rect.height / 80)); transform.concat()
    if world.facing < 0 { let flip = NSAffineTransform(); flip.translateX(by: 100, yBy: 0); flip.scaleX(by: -1, yBy: 1); flip.concat() }
    let running = [.running, .chasing, .returning].contains(world.activity)
    let cycle = world.clock * (running ? 17 : 9)
    let stride: CGFloat = motion && world.moving ? (running ? 7 : 4) : 0
    let bounce: CGFloat = motion && world.moving ? abs(CGFloat(sin(cycle))) * (running ? 4 : 1.5) : 0
    let breathe: CGFloat = motion && !world.moving && world.activity != .sleeping ? CGFloat(sin(world.clock * 2.5)) * 0.6 : 0
    let bob = bounce + breathe
    let fur = Palette.fur(archive.fur), dark = Palette.ink
    let shaded = fur.blended(withFraction: 0.18, of: dark)!
    ellipse(NSRect(x: 10, y: 1, width: 77, height: 5), dark.withAlphaComponent(0.13))
    // Far legs precede the body; near legs use the opposite walking phase.
    for (x, phase, color) in [(CGFloat(28), 0.0, shaded), (CGFloat(62), Double.pi, shaded), (CGFloat(32), Double.pi, fur), (CGFloat(68), 0.0, fur)] {
        let shift = stride * CGFloat(sin(cycle + phase))
        let lift = stride * 0.32 * max(0, CGFloat(cos(cycle + phase)))
        line(NSPoint(x: x, y: 25 + bob), NSPoint(x: x + shift, y: 8 + lift), color, width: 8)
        fill(NSRect(x: x + shift - 5, y: 4 + lift, width: 13, height: 6), color, radius: 3)
    }
    let wag: CGFloat = motion && world.activity != .sleeping ? CGFloat(sin(world.clock * (running ? 12 : 5))) * (running ? 7 : 4) : 0
    if archive.species == .rabbit { ellipse(NSRect(x: 8, y: 22 + bob, width: 12, height: 12), Palette.paper) }
    else {
        let tail = NSBezierPath(); tail.move(to: NSPoint(x: 20, y: 27 + bob))
        tail.curve(to: NSPoint(x: 6, y: 48 + bob + wag), controlPoint1: NSPoint(x: -3, y: 27 + bob), controlPoint2: NSPoint(x: 1, y: 39 + bob + wag))
        tail.lineWidth = archive.species == .dog ? 7 : 5; tail.lineCapStyle = .round; fur.setStroke(); tail.stroke()
    }
    fill(NSRect(x: 16, y: 18 + bob, width: 62, height: 29), fur, radius: 14)
    ellipse(NSRect(x: 29, y: 20 + bob, width: 36, height: 18), Palette.paper.withAlphaComponent(0.55))
    let eat = world.activity == .eating
    let headY: CGFloat = (eat ? 23 : 34) + bob + (motion && eat ? CGFloat(sin(world.clock * 13)) * 1.5 : 0)
    switch archive.species {
    case .cat:
        for x: CGFloat in [63, 78] {
            let ear = NSBezierPath(); ear.move(to: NSPoint(x: x, y: headY + 21)); ear.line(to: NSPoint(x: x - 1, y: headY + 33)); ear.line(to: NSPoint(x: x + 10, y: headY + 24)); ear.close(); fur.setFill(); ear.fill()
        }
    case .dog: fill(NSRect(x: 60, y: headY + 8, width: 13, height: 27), shaded, radius: 6)
    case .rabbit:
        let sway: CGFloat = motion && world.moving ? CGFloat(sin(cycle)) * 2 : 0
        fill(NSRect(x: 65 + sway, y: headY + 19, width: 7, height: 21), fur, radius: 4)
        fill(NSRect(x: 77 - sway, y: headY + 19, width: 7, height: 21), fur, radius: 4)
        fill(NSRect(x: 67 + sway, y: headY + 22, width: 3, height: 14), Palette.coral.withAlphaComponent(0.5), radius: 2)
    }
    fill(NSRect(x: 59, y: headY, width: 32, height: 29), fur, radius: 13)
    fill(NSRect(x: 79, y: headY + 1, width: 17, height: 13), Palette.paper.withAlphaComponent(0.7), radius: 6)
    ellipse(NSRect(x: 91, y: headY + 8, width: 5, height: 4), Palette.coral)
    let closed = archive.sleeping || world.activity == .cuddling || (motion && world.clock.truncatingRemainder(dividingBy: 4.8) > 4.6)
    if closed { line(NSPoint(x: 77, y: headY + 17), NSPoint(x: 82, y: headY + 17), dark, width: 1.6) }
    else { ellipse(NSRect(x: 78, y: headY + 14, width: 3.5, height: 5), dark); ellipse(NSRect(x: 79, y: headY + 17, width: 1, height: 1), Palette.paper) }
    line(NSPoint(x: 87, y: headY + 4), NSPoint(x: 92, y: headY + 4), dark, width: 1)
    switch archive.accessory {
    case .none: break
    case .scarf: fill(NSRect(x: 58, y: 28 + bob, width: 7, height: 21), Palette.green, radius: 2)
    case .star: star(NSPoint(x: 61, y: 35 + bob), radius: 5, color: Palette.gold)
    case .crown: star(NSPoint(x: 76, y: headY + 33), radius: 6, color: Palette.gold)
    }
    if world.activity == .cuddling || world.activity == .celebrating {
        let lift: CGFloat = motion ? CGFloat(sin(world.activityTime * .pi)) * 6 : 0
        star(NSPoint(x: 42, y: 54 + lift), radius: 5, color: Palette.coral)
    }
    if world.activity == .washing {
        for (x, y, r) in [(CGFloat(32), CGFloat(48), CGFloat(4)), (55, 57, 3), (48, 40, 5)] { ellipse(NSRect(x: x, y: y, width: r * 2, height: r * 2), NSColor.systemTeal.withAlphaComponent(0.45)) }
    }
    if archive.sleeping { drawText("z", NSRect(x: 32, y: 49, width: 20, height: 20), size: 13, color: Palette.green) }
    NSGraphicsContext.restoreGraphicsState()
}

func drawPlayObject(_ center: NSPoint, size: CGFloat, world: CompanionWorld, motion: Bool) {
    guard let object = world.object else { return }
    NSGraphicsContext.saveGraphicsState()
    let transform = NSAffineTransform(); transform.translateX(by: center.x, yBy: center.y)
    if motion && world.isFlying { transform.rotate(byRadians: CGFloat(world.objectRotation)) }; transform.concat()
    switch object {
    case .ball:
        ellipse(NSRect(x: -size / 2, y: -size / 2, width: size, height: size), Palette.gold)
        line(NSPoint(x: -size * 0.35, y: 0), NSPoint(x: size * 0.35, y: 0), Palette.paper, width: max(1, size * 0.10))
        ellipse(NSRect(x: -size * 0.22, y: size * 0.1, width: size * 0.20, height: size * 0.20), NSColor.white.withAlphaComponent(0.55))
    case .bone:
        fill(NSRect(x: -size * 0.45, y: -size * 0.16, width: size * 0.9, height: size * 0.32), Palette.paper, radius: 2)
        for x in [-size * 0.45, size * 0.35] { for y in [-size * 0.25, CGFloat(0)] { ellipse(NSRect(x: x - size * 0.13, y: y, width: size * 0.32, height: size * 0.32), Palette.paper) } }
    case .meal, .treat:
        fill(NSRect(x: -size * 0.65, y: -size * 0.25, width: size * 1.3, height: size * 0.5), Palette.coral, radius: size * 0.15)
        let portion = CGFloat(1 - world.eatingProgress)
        for offset: CGFloat in [-0.3, 0, 0.3] { ellipse(NSRect(x: size * offset - size * 0.12, y: size * 0.10, width: size * 0.24 * portion, height: size * 0.19 * portion), object == .treat ? Palette.gold : Palette.fur(.cocoa)) }
    }
    NSGraphicsContext.restoreGraphicsState()
}
