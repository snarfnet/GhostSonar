import SwiftUI

struct SonarRadarView: View {
    @EnvironmentObject var sensorManager: SensorManager
    @EnvironmentObject var ghostEngine: GhostDetectionEngine
    @EnvironmentObject var horrorManager: HorrorEffectManager

    @State private var sweepAngle: Double = 0
    @State private var pingScale: CGFloat = 0
    @State private var pingOpacity: Double = 0
    @State private var trailAngles: [Double] = []

    let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()
    let sweepSpeed: Double = 1.2 // radians per second

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = size / 2 - 10

            ZStack {
                // Background grid
                radarGrid(center: center, radius: radius)

                // Sweep trail (sonar afterglow)
                sweepTrail(center: center, radius: radius)

                // Sweep line
                sweepLine(center: center, radius: radius)

                // Ghost blips
                ForEach(ghostEngine.detections.suffix(15)) { detection in
                    ghostBlip(detection: detection, center: center, radius: radius)
                }

                // Ping wave
                Circle()
                    .stroke(Color("sonarGreen").opacity(pingOpacity), lineWidth: 2)
                    .frame(width: size * pingScale, height: size * pingScale)
                    .position(center)

                // Center dot
                Circle()
                    .fill(Color("sonarGreen"))
                    .frame(width: 8, height: 8)
                    .shadow(color: Color("sonarGreen"), radius: 6)
                    .position(center)

                // Cardinal markers
                cardinalMarkers(center: center, radius: radius)
            }
            .onReceive(timer) { _ in
                withAnimation(.linear(duration: 0.016)) {
                    sweepAngle += sweepSpeed * 0.016
                    if sweepAngle >= 2 * .pi {
                        sweepAngle -= 2 * .pi
                        triggerPing()
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Radar Grid
    private func radarGrid(center: CGPoint, radius: CGFloat) -> some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(Color("sonarGreen").opacity(0.4), lineWidth: 1.5)
                .frame(width: radius * 2, height: radius * 2)
                .position(center)

            // Inner rings
            ForEach([0.75, 0.5, 0.25], id: \.self) { scale in
                Circle()
                    .stroke(Color("sonarGreen").opacity(0.15), lineWidth: 0.8)
                    .frame(width: radius * 2 * scale, height: radius * 2 * scale)
                    .position(center)
            }

            // Cross lines
            ForEach(0..<12) { i in
                let angle = Double(i) * .pi / 6
                Path { path in
                    path.move(to: center)
                    path.addLine(to: CGPoint(
                        x: center.x + cos(angle) * radius,
                        y: center.y + sin(angle) * radius
                    ))
                }
                .stroke(Color("sonarGreen").opacity(i % 3 == 0 ? 0.2 : 0.08), lineWidth: 0.5)
            }

            // Distance markers
            ForEach([0.25, 0.5, 0.75], id: \.self) { scale in
                Text("\(Int(scale * 100))m")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color("sonarGreen").opacity(0.3))
                    .position(x: center.x + radius * scale + 14, y: center.y - 4)
            }
        }
    }

    // MARK: - Sweep Line
    private func sweepLine(center: CGPoint, radius: CGFloat) -> some View {
        Path { path in
            path.move(to: center)
            path.addLine(to: CGPoint(
                x: center.x + cos(sweepAngle) * radius,
                y: center.y + sin(sweepAngle) * radius
            ))
        }
        .stroke(
            Color("sonarGreen"),
            style: StrokeStyle(lineWidth: 2, lineCap: .round)
        )
        .shadow(color: Color("sonarGreen"), radius: 4)
    }

    // MARK: - Sweep Trail
    private func sweepTrail(center: CGPoint, radius: CGFloat) -> some View {
        Path { path in
            let segments = 60
            for i in 0..<segments {
                let trailAngle = sweepAngle - Double(i) * 0.02
                let opacity = 1.0 - Double(i) / Double(segments)
                let endX = center.x + cos(trailAngle) * radius
                let endY = center.y + sin(trailAngle) * radius
                path.move(to: center)
                path.addLine(to: CGPoint(x: endX, y: endY))
            }
        }
        .stroke(Color("sonarGreen").opacity(0.06), lineWidth: 1)
    }

    // MARK: - Ghost Blips
    private func ghostBlip(detection: GhostReading, center: CGPoint, radius: CGFloat) -> some View {
        let x = center.x + cos(detection.angle) * radius * detection.distance
        let y = center.y + sin(detection.angle) * radius * detection.distance
        let blipSize: CGFloat = CGFloat(6 + detection.intensity * 10)

        let blipColor: Color = {
            switch detection.threatLevel {
            case .low: return Color("sonarGreen")
            case .medium: return Color("sonarYellow")
            case .high: return Color("sonarOrange")
            case .critical: return Color("sonarRed")
            }
        }()

        // Fade based on age
        let age = Date().timeIntervalSince(detection.timestamp)
        let fadeOpacity = max(0, 1.0 - age / 8.0)

        return ZStack {
            // Outer glow
            Circle()
                .fill(blipColor.opacity(0.3 * fadeOpacity))
                .frame(width: blipSize * 2, height: blipSize * 2)

            // Core blip
            Circle()
                .fill(blipColor.opacity(0.8 * fadeOpacity))
                .frame(width: blipSize, height: blipSize)

            // Bright center
            Circle()
                .fill(Color.white.opacity(0.6 * fadeOpacity))
                .frame(width: blipSize * 0.4, height: blipSize * 0.4)
        }
        .shadow(color: blipColor.opacity(0.5 * fadeOpacity), radius: 8)
        .position(x: x, y: y)
    }

    // MARK: - Cardinal Markers
    private func cardinalMarkers(center: CGPoint, radius: CGFloat) -> some View {
        let markers: [(String, Double)] = [
            ("N", -.pi / 2), ("E", 0), ("S", .pi / 2), ("W", .pi)
        ]
        return ForEach(markers, id: \.0) { label, angle in
            Text(label)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(Color("sonarGreen").opacity(0.6))
                .position(
                    x: center.x + cos(angle) * (radius + 16),
                    y: center.y + sin(angle) * (radius + 16)
                )
        }
    }

    private func triggerPing() {
        pingScale = 0
        pingOpacity = 0.6
        withAnimation(.easeOut(duration: 1.5)) {
            pingScale = 1.0
            pingOpacity = 0
        }
        horrorManager.triggerSonarPing()
    }
}
