import SwiftUI

// Custom chunky Shape glyphs — NO SF Symbols, NO emoji anywhere.

struct FHDSnowflakeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        for i in 0..<6 {
            let a = Double(i) * .pi / 3
            let tip = CGPoint(x: c.x + CGFloat(cos(a)) * r, y: c.y + CGFloat(sin(a)) * r)
            p.move(to: c)
            p.addLine(to: tip)
            // branches
            let mid = CGPoint(x: c.x + CGFloat(cos(a)) * r * 0.55, y: c.y + CGFloat(sin(a)) * r * 0.55)
            let bl = r * 0.28
            p.move(to: mid)
            p.addLine(to: CGPoint(x: mid.x + CGFloat(cos(a + 0.8)) * bl, y: mid.y + CGFloat(sin(a + 0.8)) * bl))
            p.move(to: mid)
            p.addLine(to: CGPoint(x: mid.x + CGFloat(cos(a - 0.8)) * bl, y: mid.y + CGFloat(sin(a - 0.8)) * bl))
        }
        return p
    }
}

struct FHDFlameShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addCurve(to: CGPoint(x: rect.minX + w * 0.1, y: rect.minY + h * 0.62),
                   control1: CGPoint(x: rect.minX + w * 0.05, y: rect.minY + h * 0.30),
                   control2: CGPoint(x: rect.minX, y: rect.minY + h * 0.42))
        p.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY),
                   control1: CGPoint(x: rect.minX + w * 0.18, y: rect.maxY),
                   control2: CGPoint(x: rect.midX - w * 0.05, y: rect.maxY))
        p.addCurve(to: CGPoint(x: rect.maxX - w * 0.1, y: rect.minY + h * 0.62),
                   control1: CGPoint(x: rect.midX + w * 0.05, y: rect.maxY),
                   control2: CGPoint(x: rect.maxX - w * 0.18, y: rect.maxY))
        p.addCurve(to: CGPoint(x: rect.midX, y: rect.minY),
                   control1: CGPoint(x: rect.maxX, y: rect.minY + h * 0.42),
                   control2: CGPoint(x: rect.maxX - w * 0.05, y: rect.minY + h * 0.30))
        return p
    }
}

struct FHDSwordShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX
        // blade
        p.move(to: CGPoint(x: cx, y: rect.minY))
        p.addLine(to: CGPoint(x: cx + rect.width * 0.13, y: rect.minY + rect.height * 0.12))
        p.addLine(to: CGPoint(x: cx + rect.width * 0.10, y: rect.minY + rect.height * 0.62))
        p.addLine(to: CGPoint(x: cx - rect.width * 0.10, y: rect.minY + rect.height * 0.62))
        p.addLine(to: CGPoint(x: cx - rect.width * 0.13, y: rect.minY + rect.height * 0.12))
        p.closeSubpath()
        // crossguard
        p.addRect(CGRect(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.60,
                         width: rect.width * 0.64, height: rect.height * 0.09))
        // hilt
        p.addRect(CGRect(x: cx - rect.width * 0.06, y: rect.minY + rect.height * 0.69,
                         width: rect.width * 0.12, height: rect.height * 0.26))
        return p
    }
}

struct FHDShieldShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.18))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.55))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY),
                       control: CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.1))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.55),
                       control: CGPoint(x: rect.minX, y: rect.maxY - rect.height * 0.1))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.18))
        p.closeSubpath()
        return p
    }
}

struct FHDPotionShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.addRect(CGRect(x: rect.midX - w * 0.13, y: rect.minY, width: w * 0.26, height: h * 0.20))
        p.move(to: CGPoint(x: rect.midX - w * 0.10, y: rect.minY + h * 0.20))
        p.addLine(to: CGPoint(x: rect.midX - w * 0.10, y: rect.minY + h * 0.36))
        p.addQuadCurve(to: CGPoint(x: rect.midX - w * 0.40, y: rect.maxY),
                       control: CGPoint(x: rect.minX, y: rect.minY + h * 0.55))
        p.addQuadCurve(to: CGPoint(x: rect.midX + w * 0.40, y: rect.maxY),
                       control: CGPoint(x: rect.midX, y: rect.maxY + h * 0.18))
        p.addQuadCurve(to: CGPoint(x: rect.midX + w * 0.10, y: rect.minY + h * 0.36),
                       control: CGPoint(x: rect.maxX, y: rect.minY + h * 0.55))
        p.addLine(to: CGPoint(x: rect.midX + w * 0.10, y: rect.minY + h * 0.20))
        p.closeSubpath()
        return p
    }
}

struct FHDScrollShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addRoundedRect(in: CGRect(x: rect.minX + rect.width * 0.12, y: rect.minY,
                                    width: rect.width * 0.76, height: rect.height),
                         cornerSize: CGSize(width: 4, height: 4))
        p.addRect(CGRect(x: rect.minX, y: rect.minY + rect.height * 0.10,
                         width: rect.width * 0.14, height: rect.height * 0.80))
        p.addRect(CGRect(x: rect.maxX - rect.width * 0.14, y: rect.minY + rect.height * 0.10,
                         width: rect.width * 0.14, height: rect.height * 0.80))
        return p
    }
}

struct FHDRingShape: Shape {
    func path(in rect: CGRect) -> Path {
        let d = min(rect.width, rect.height)
        let outer = CGRect(x: rect.midX - d/2, y: rect.midY - d/2, width: d, height: d)
        let inner = outer.insetBy(dx: d * 0.28, dy: d * 0.28)
        var p = Path()
        p.addEllipse(in: outer)
        p.addEllipse(in: inner)
        return p
    }
}

struct FHDWandShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + rect.width * 0.2, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.25, y: rect.minY + rect.height * 0.25))
        p = p.strokedPath(.init(lineWidth: max(2, rect.width * 0.10), lineCap: .round))
        // star tip
        let star = FHDStarShape(points: 4)
        let tip = CGRect(x: rect.maxX - rect.width * 0.45, y: rect.minY,
                         width: rect.width * 0.42, height: rect.height * 0.42)
        p.addPath(star.path(in: tip))
        return p
    }
}

struct FHDStarShape: Shape {
    var points: Int = 5
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.45
        let n = points * 2
        for i in 0..<n {
            let r = i % 2 == 0 ? outer : inner
            let a = -Double.pi / 2 + Double(i) * .pi / Double(points)
            let pt = CGPoint(x: c.x + CGFloat(cos(a)) * r, y: c.y + CGFloat(sin(a)) * r)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

struct FHDKeyShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let d = rect.width * 0.4
        p.addEllipse(in: CGRect(x: rect.minX, y: rect.midY - d/2, width: d, height: d))
        p.addRect(CGRect(x: rect.minX + d * 0.8, y: rect.midY - rect.height * 0.06,
                         width: rect.width * 0.6, height: rect.height * 0.12))
        p.addRect(CGRect(x: rect.maxX - rect.width * 0.18, y: rect.midY,
                         width: rect.width * 0.08, height: rect.height * 0.20))
        p.addRect(CGRect(x: rect.maxX - rect.width * 0.34, y: rect.midY,
                         width: rect.width * 0.08, height: rect.height * 0.20))
        return p
    }
}

struct FHDSkullShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.addRoundedRect(in: CGRect(x: rect.minX + w*0.12, y: rect.minY,
                                    width: w*0.76, height: h*0.66),
                         cornerSize: CGSize(width: w*0.3, height: h*0.3))
        // jaw
        p.addRoundedRect(in: CGRect(x: rect.minX + w*0.26, y: rect.minY + h*0.55,
                                    width: w*0.48, height: h*0.32),
                         cornerSize: CGSize(width: 4, height: 4))
        return p
    }
}

struct FHDHeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.28))
        p.addCurve(to: CGPoint(x: rect.minX, y: rect.minY + h * 0.30),
                   control1: CGPoint(x: rect.midX - w*0.18, y: rect.minY),
                   control2: CGPoint(x: rect.minX, y: rect.minY))
        p.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY),
                   control1: CGPoint(x: rect.minX, y: rect.minY + h*0.58),
                   control2: CGPoint(x: rect.midX - w*0.1, y: rect.minY + h*0.72))
        p.addCurve(to: CGPoint(x: rect.maxX, y: rect.minY + h*0.30),
                   control1: CGPoint(x: rect.midX + w*0.1, y: rect.minY + h*0.72),
                   control2: CGPoint(x: rect.maxX, y: rect.minY + h*0.58))
        p.addCurve(to: CGPoint(x: rect.midX, y: rect.minY + h*0.28),
                   control1: CGPoint(x: rect.maxX, y: rect.minY),
                   control2: CGPoint(x: rect.midX + w*0.18, y: rect.minY))
        return p
    }
}

struct FHDBootShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: rect.minX + w*0.32, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + w*0.58, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + w*0.58, y: rect.minY + h*0.62))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + h*0.62))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + w*0.32, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct FHDGearShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let teeth = 8
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.74
        for i in 0..<(teeth * 2) {
            let r = i % 2 == 0 ? outer : inner
            let a = Double(i) * .pi / Double(teeth)
            let pt = CGPoint(x: c.x + CGFloat(cos(a)) * r, y: c.y + CGFloat(sin(a)) * r)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        let hole = outer * 0.42
        p.addEllipse(in: CGRect(x: c.x - hole, y: c.y - hole, width: hole*2, height: hole*2))
        return p
    }
}

struct FHDChestShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addRoundedRect(in: CGRect(x: rect.minX, y: rect.minY + rect.height*0.32,
                                    width: rect.width, height: rect.height*0.68),
                         cornerSize: CGSize(width: 3, height: 3))
        p.addArc(center: CGPoint(x: rect.midX, y: rect.minY + rect.height*0.32),
                 radius: rect.width*0.5, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addRect(CGRect(x: rect.midX - rect.width*0.06, y: rect.minY + rect.height*0.40,
                         width: rect.width*0.12, height: rect.height*0.22))
        return p
    }
}

struct FHDStairsShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let steps = 4
        let sw = rect.width / CGFloat(steps)
        let sh = rect.height / CGFloat(steps)
        for i in 0..<steps {
            p.addRect(CGRect(x: rect.minX + CGFloat(i)*sw, y: rect.minY + CGFloat(i)*sh,
                             width: rect.width - CGFloat(i)*sw, height: sh))
        }
        return p
    }
}

struct FHDBagShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.addRoundedRect(in: CGRect(x: rect.minX, y: rect.minY + h*0.22,
                                    width: w, height: h*0.78),
                         cornerSize: CGSize(width: w*0.2, height: w*0.2))
        p.move(to: CGPoint(x: rect.minX + w*0.28, y: rect.minY + h*0.30))
        p.addLine(to: CGPoint(x: rect.minX + w*0.4, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + w*0.6, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + w*0.72, y: rect.minY + h*0.30))
        return p
    }
}

struct FHDEyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control: CGPoint(x: rect.midX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.midY), control: CGPoint(x: rect.midX, y: rect.maxY))
        let d = rect.height * 0.42
        p.addEllipse(in: CGRect(x: rect.midX - d/2, y: rect.midY - d/2, width: d, height: d))
        return p
    }
}

struct FHDChevronShape: Shape {
    var dir: Int // 0 up,1 down,2 left,3 right
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let m = min(rect.width, rect.height)
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let pts: [CGPoint]
        switch dir {
        case 0: pts = [CGPoint(x: c.x - m*0.4, y: c.y + m*0.2), CGPoint(x: c.x, y: c.y - m*0.2), CGPoint(x: c.x + m*0.4, y: c.y + m*0.2)]
        case 1: pts = [CGPoint(x: c.x - m*0.4, y: c.y - m*0.2), CGPoint(x: c.x, y: c.y + m*0.2), CGPoint(x: c.x + m*0.4, y: c.y - m*0.2)]
        case 2: pts = [CGPoint(x: c.x + m*0.2, y: c.y - m*0.4), CGPoint(x: c.x - m*0.2, y: c.y), CGPoint(x: c.x + m*0.2, y: c.y + m*0.4)]
        default: pts = [CGPoint(x: c.x - m*0.2, y: c.y - m*0.4), CGPoint(x: c.x + m*0.2, y: c.y), CGPoint(x: c.x - m*0.2, y: c.y + m*0.4)]
        }
        p.move(to: pts[0]); p.addLine(to: pts[1]); p.addLine(to: pts[2])
        return p.strokedPath(.init(lineWidth: m*0.14, lineCap: .round, lineJoin: .round))
    }
}

struct FHDCrossShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let m = min(rect.width, rect.height)
        let t = m * 0.16
        p.move(to: CGPoint(x: rect.midX - m*0.35, y: rect.midY - m*0.35))
        p.addLine(to: CGPoint(x: rect.midX + m*0.35, y: rect.midY + m*0.35))
        p.move(to: CGPoint(x: rect.midX + m*0.35, y: rect.midY - m*0.35))
        p.addLine(to: CGPoint(x: rect.midX - m*0.35, y: rect.midY + m*0.35))
        return p.strokedPath(.init(lineWidth: t, lineCap: .round))
    }
}

// Generic glyph renderer used in lists/HUD.
struct FHDGlyph: View {
    enum Kind { case flame, snow, sword, shield, potion, scroll, ring, wand, key, skull, heart, boot, gear, chest, stairs, bag, eye, star, cross }
    var kind: Kind
    var size: CGFloat = 22
    var color: Color = FHDTheme.ivory
    var fill: Bool = true

    var body: some View {
        Group {
            switch kind {
            case .flame: shapeView(FHDFlameShape())
            case .snow: FHDSnowflakeShape().stroke(color, lineWidth: max(1.4, size*0.07))
            case .sword: shapeView(FHDSwordShape())
            case .shield: shapeView(FHDShieldShape())
            case .potion: shapeView(FHDPotionShape())
            case .scroll: shapeView(FHDScrollShape())
            case .ring: FHDRingShape().fill(color, style: FillStyle(eoFill: true))
            case .wand: FHDWandShape().fill(color, style: FillStyle(eoFill: true))
            case .key: shapeView(FHDKeyShape())
            case .skull: shapeView(FHDSkullShape())
            case .heart: shapeView(FHDHeartShape())
            case .boot: shapeView(FHDBootShape())
            case .gear: FHDGearShape().fill(color, style: FillStyle(eoFill: true))
            case .chest: shapeView(FHDChestShape())
            case .stairs: shapeView(FHDStairsShape())
            case .bag: shapeView(FHDBagShape())
            case .eye: FHDEyeShape().stroke(color, lineWidth: max(1.4, size*0.07))
            case .star: shapeView(FHDStarShape())
            case .cross: FHDCrossShape().fill(color)
            }
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder private func shapeView<S: Shape>(_ s: S) -> some View {
        if fill { s.fill(color) } else { s.stroke(color, lineWidth: max(1.4, size*0.08)) }
    }
}
