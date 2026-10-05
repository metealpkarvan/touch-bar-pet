import AppKit
import PetCore

func sceneName(_ scene:SceneTheme,_ l:Language)->String {
    switch scene { case .garden: return t(l,"Bahçe","Garden"); case .seaside: return t(l,"Sahil","Seaside"); case .room: return t(l,"Sıcak Oda","Cozy Room"); case .moonlight: return t(l,"Ay Bahçesi","Moon Garden"); case .snowfield: return t(l,"Kar Yaylası","Snowfield") }
}
func daylightName(_ value:Daylight,_ l:Language)->String {
    switch value { case .day: return t(l,"Gündüz","Day"); case .sunset: return t(l,"Günbatımı","Sunset"); case .night: return t(l,"Gece","Night") }
}
func weatherName(_ value:SceneWeather,_ l:Language)->String {
    switch value { case .clear: return t(l,"Açık","Clear"); case .rain: return t(l,"Yağmur","Rain"); case .snow: return t(l,"Kar","Snow") }
}
func decorationName(_ value:Decoration,_ l:Language)->String {
    switch value { case .none: return t(l,"Doğal","Natural"); case .cushion: return t(l,"Minder","Cushion"); case .flowers: return t(l,"Çiçekler","Flowers"); case .lantern: return t(l,"Fener","Lantern"); case .tent: return t(l,"Çadır","Tent") }
}
func adventureName(_ value:Adventure,_ l:Language)->String {
    switch value { case .firstSteps: return t(l,"İlk Patiler","First Paws"); case .playmates: return t(l,"Oyun Arkadaşları","Playmates"); case .explorers: return t(l,"Birlikte Kaşif","Explorers Together") }
}
func badgeName(_ value:Badge,_ l:Language)->String {
    switch value {
    case .firstFetch: return t(l,"İlk Getirme","First Fetch")
    case .tenFetches: return t(l,"Oyuncak Avcısı","Toy Hunter")
    case .twentyFiveFetches: return t(l,"Usta Getirici","Fetch Master")
    case .fiveMeals: return t(l,"Sofra Dostu","Meal Mate")
    case .threeRounds: return t(l,"Oyun Dostu","Play Buddy")
    case .firstChallenge: return t(l,"İlk Meydan Okuma","First Challenge")
    case .fiveChallenges: return t(l,"Takım Yıldızı","Team Star")
    }
}
private func rgb(_ r:CGFloat,_ g:CGFloat,_ b:CGFloat)->NSColor { NSColor(calibratedRed:r,green:g,blue:b,alpha:1) }

/// Five original vector environments, shared by the large habitat and physical strip.
func drawScenery(_ rect:NSRect,progress:PlaygroundProgress,clock:Double,motion:Bool,compact:Bool) {
    NSGraphicsContext.saveGraphicsState(); NSBezierPath(roundedRect:rect,xRadius:compact ? 7 : 14,yRadius:compact ? 7 : 14).addClip()
    let tx=NSAffineTransform(); tx.translateX(by:rect.minX,yBy:rect.minY); tx.scaleX(by:rect.width/600,yBy:rect.height/260); tx.concat()
    let night=progress.daylight == .night || progress.scene == .moonlight
    let sky=night ? rgb(0.13,0.20,0.34) : progress.daylight == .sunset ? rgb(0.96,0.72,0.57) : rgb(0.76,0.87,0.90)
    let horizon=night ? rgb(0.29,0.34,0.47) : rgb(0.94,0.95,0.84)
    NSGradient(starting:sky,ending:horizon)?.draw(in:NSRect(x:0,y:0,width:600,height:260),angle:270)
    if night {
        ellipse(NSRect(x:470,y:183,width:45,height:45),rgb(0.96,0.91,0.68))
        ellipse(NSRect(x:485,y:195,width:37,height:37),sky)
        for i in 0..<16 {
            let x=CGFloat((i*83+21)%585),y=CGFloat(128+(i*41)%115)
            let alpha:CGFloat=motion ? 0.65+CGFloat(sin(clock*1.2+Double(i)))*0.20 : 0.75
            star(NSPoint(x:x,y:y),radius:compact ? 3 : 2.4,color:Palette.paper.withAlphaComponent(alpha))
        }
    } else {
        ellipse(NSRect(x:468,y:183,width:42,height:42),Palette.gold.withAlphaComponent(0.8))
        for i in 0..<3 { let x=CGFloat(50+i*172)+(motion ? CGFloat(sin(clock*0.12+Double(i)))*8 : 0); fill(NSRect(x:x,y:179+CGFloat(i%2)*35,width:82,height:17),NSColor.white.withAlphaComponent(0.42),radius:12) }
    }
    let greenery=night ? rgb(0.16,0.32,0.29) : rgb(0.58,0.74,0.53)
    switch progress.scene {
    case .garden:
        ellipse(NSRect(x:-80,y:-100,width:430,height:245),greenery.withAlphaComponent(0.55))
        ellipse(NSRect(x:210,y:-135,width:490,height:260),greenery.withAlphaComponent(0.8))
        fill(NSRect(x:0,y:0,width:600,height:48),greenery,radius:0)
        for i in 0..<9 { let x=CGFloat(i*68+12); line(NSPoint(x:x,y:42),NSPoint(x:x+5,y:55),Palette.green,width:2); ellipse(NSRect(x:x+1,y:51,width:6,height:6),i%2==0 ? Palette.gold : Palette.coral) }
    case .seaside:
        fill(NSRect(x:0,y:40,width:600,height:69),night ? rgb(0.15,0.36,0.46) : rgb(0.36,0.67,0.75))
        for i in 0..<4 { let y=CGFloat(48+i*15); for j in 0..<8 { let x=CGFloat(j*83)+(motion ? CGFloat(sin(clock*1.5+Double(i)))*7 : 0); line(NSPoint(x:x,y:y),NSPoint(x:x+37,y:y+1),NSColor.white.withAlphaComponent(0.35),width:2) } }
        fill(NSRect(x:0,y:0,width:600,height:41),night ? rgb(0.48,0.46,0.43) : rgb(0.87,0.78,0.58))
        for x:CGFloat in [58,198,432,561] { ellipse(NSRect(x:x,y:22,width:6,height:4),Palette.paper.withAlphaComponent(0.6)) }
    case .room:
        fill(NSRect(x:0,y:0,width:600,height:260),night ? rgb(0.30,0.27,0.36) : rgb(0.84,0.77,0.69))
        fill(NSRect(x:190,y:115,width:195,height:117),Palette.paper,radius:5)
        fill(NSRect(x:199,y:124,width:177,height:99),sky,radius:3)
        line(NSPoint(x:286,y:124),NSPoint(x:286,y:223),Palette.paper,width:7)
        line(NSPoint(x:199,y:172),NSPoint(x:376,y:172),Palette.paper,width:7)
        fill(NSRect(x:0,y:0,width:600,height:57),night ? rgb(0.43,0.35,0.32) : rgb(0.68,0.53,0.41))
        for x in stride(from:CGFloat(0),to:600,by:75) { line(NSPoint(x:x,y:0),NSPoint(x:x+26,y:57),Palette.paper.withAlphaComponent(0.18)) }
        fill(NSRect(x:70,y:20,width:450,height:23),Palette.coral.withAlphaComponent(0.45),radius:12)
    case .moonlight:
        for (x,h) in [(CGFloat(24),CGFloat(160)),(100,126),(497,143),(558,175)] {
            fill(NSRect(x:x,y:45,width:9,height:h),rgb(0.20,0.28,0.33),radius:3)
            ellipse(NSRect(x:x-29,y:h-11,width:69,height:74),rgb(0.19,0.34,0.36))
        }
        fill(NSRect(x:0,y:0,width:600,height:47),rgb(0.23,0.36,0.34))
        for i in 0..<10 { let x=CGFloat(25+i*58), y:CGFloat=70+CGFloat((i*31)%83)+(motion ? CGFloat(sin(clock*1.4+Double(i)))*6 : 0); ellipse(NSRect(x:x,y:y,width:4,height:4),Palette.gold.withAlphaComponent(0.7)) }
    case .snowfield:
        for (x,h) in [(CGFloat(-45),CGFloat(135)),(110,190),(350,153)] {
            let mountain=NSBezierPath(); mountain.move(to:NSPoint(x:x,y:32)); mountain.line(to:NSPoint(x:x+125,y:h)); mountain.line(to:NSPoint(x:x+255,y:32)); mountain.close(); (night ? rgb(0.46,0.57,0.69) : rgb(0.68,0.80,0.87)).setFill(); mountain.fill()
            let cap=NSBezierPath(); cap.move(to:NSPoint(x:x+90,y:h-42)); cap.line(to:NSPoint(x:x+125,y:h)); cap.line(to:NSPoint(x:x+162,y:h-42)); cap.close(); Palette.paper.setFill(); cap.fill()
        }
        fill(NSRect(x:0,y:0,width:600,height:44),night ? rgb(0.72,0.79,0.84) : rgb(0.94,0.96,0.96))
    }
    // Cozy-room precipitation stays outside its window; other worlds show a light overlay.
    if progress.weather != .clear {
        NSGraphicsContext.saveGraphicsState()
        if progress.scene == .room { NSBezierPath(rect:NSRect(x:199,y:124,width:177,height:99)).addClip() }
        for i in 0..<25 {
            let x=CGFloat((i*97+13)%598)
            let y=CGFloat((Double((i*53)%260)+(motion ? clock*(progress.weather == .rain ? 105 : 29) : 0)).truncatingRemainder(dividingBy:260))
            if progress.weather == .rain { line(NSPoint(x:x,y:260-y),NSPoint(x:x-4,y:247-y),NSColor.white.withAlphaComponent(0.34),width:compact ? 1.7 : 1) }
            else { ellipse(NSRect(x:x,y:260-y,width:3.8,height:3.8),Palette.paper.withAlphaComponent(0.75)) }
        }
        NSGraphicsContext.restoreGraphicsState()
    }
    switch progress.decoration {
    case .none: break
    case .cushion: fill(NSRect(x:84,y:18,width:86,height:18),Palette.coral,radius:9); line(NSPoint(x:93,y:28),NSPoint(x:161,y:28),Palette.paper.withAlphaComponent(0.4),width:2)
    case .flowers:
        fill(NSRect(x:76,y:18,width:31,height:24),Palette.coral,radius:5)
        for (x,y) in [(CGFloat(80),CGFloat(62)),(93,74),(106,57)] { line(NSPoint(x:91,y:36),NSPoint(x:x,y:y),Palette.green,width:3); ellipse(NSRect(x:x-7,y:y-7,width:14,height:14),Palette.gold); ellipse(NSRect(x:x-2,y:y-2,width:4,height:4),Palette.coral) }
    case .lantern:
        ellipse(NSRect(x:64,y:7,width:74,height:92),Palette.gold.withAlphaComponent(0.16))
        fill(NSRect(x:85,y:24,width:31,height:41),Palette.gold,radius:5)
        fill(NSRect(x:81,y:20,width:39,height:5),Palette.ink,radius:2); line(NSPoint(x:91,y:65),NSPoint(x:91,y:76),Palette.ink,width:3); line(NSPoint(x:91,y:76),NSPoint(x:111,y:76),Palette.ink,width:3)
    case .tent:
        let tent=NSBezierPath(); tent.move(to:NSPoint(x:62,y:20)); tent.line(to:NSPoint(x:115,y:96)); tent.line(to:NSPoint(x:181,y:20)); tent.close(); Palette.coral.setFill(); tent.fill()
        let door=NSBezierPath(); door.move(to:NSPoint(x:100,y:20)); door.line(to:NSPoint(x:116,y:67)); door.line(to:NSPoint(x:137,y:20)); door.close(); Palette.ink.withAlphaComponent(0.5).setFill(); door.fill()
    }
    NSGraphicsContext.restoreGraphicsState()
}
