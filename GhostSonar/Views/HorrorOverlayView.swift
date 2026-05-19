import SwiftUI

struct HorrorOverlayView: View {
    @EnvironmentObject var horrorManager: HorrorEffectManager

    var body: some View {
        ZStack {
            // Red flash overlay
            Color.red
                .opacity(horrorManager.redFlashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Static noise
            if horrorManager.staticNoiseOpacity > 0 {
                StaticNoiseView()
                    .opacity(horrorManager.staticNoiseOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // Scanlines
            ScanlinesView()
                .opacity(0.08)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Interference lines
            if horrorManager.interferenceLines {
                InterferenceLinesView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // Horror text flash
            if horrorManager.horrorTextVisible {
                HorrorTextView(text: horrorManager.horrorText)
                    .allowsHitTesting(false)
            }

            // Screen flicker
            if horrorManager.screenFlicker {
                Color.black
                    .opacity(Double.random(in: 0...0.3))
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // Vignette (always on for atmosphere)
            RadialGradient(
                gradient: Gradient(colors: [
                    .clear,
                    Color.black.opacity(0.5),
                    Color.black.opacity(0.8)
                ]),
                center: .center,
                startRadius: 150,
                endRadius: 400
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Static Noise
struct StaticNoiseView: View {
    @State private var phase = 0

    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        Canvas { context, size in
            let cellSize: CGFloat = 3
            for x in stride(from: 0, to: size.width, by: cellSize) {
                for y in stride(from: 0, to: size.height, by: cellSize) {
                    let brightness = Double.random(in: 0...1)
                    context.fill(
                        Path(CGRect(x: x, y: y, width: cellSize, height: cellSize)),
                        with: .color(.white.opacity(brightness * 0.3))
                    )
                }
            }
        }
        .onReceive(timer) { _ in
            phase += 1 // Force redraw
        }
        .id(phase)
    }
}

// MARK: - Scanlines
struct ScanlinesView: View {
    var body: some View {
        Canvas { context, size in
            for y in stride(from: 0, to: size.height, by: 2) {
                context.fill(
                    Path(CGRect(x: 0, y: y, width: size.width, height: 1)),
                    with: .color(.black)
                )
            }
        }
    }
}

// MARK: - Interference Lines
struct InterferenceLinesView: View {
    @State private var offset: CGFloat = 0

    var body: some View {
        Canvas { context, size in
            let lineCount = Int.random(in: 3...8)
            for _ in 0..<lineCount {
                let y = CGFloat.random(in: 0...size.height)
                let height: CGFloat = CGFloat.random(in: 1...4)
                context.fill(
                    Path(CGRect(x: 0, y: y, width: size.width, height: height)),
                    with: .color(Color("sonarGreen").opacity(Double.random(in: 0.1...0.4)))
                )
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 0.1).repeatForever(autoreverses: false)) {
                offset = 100
            }
        }
    }
}

// MARK: - Horror Text
struct HorrorTextView: View {
    let text: String
    @State private var glitchOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Red shadow
            Text(text)
                .font(.system(size: 42, weight: .black, design: .monospaced))
                .foregroundColor(.red.opacity(0.5))
                .offset(x: 3, y: 3)

            // Cyan shadow
            Text(text)
                .font(.system(size: 42, weight: .black, design: .monospaced))
                .foregroundColor(.cyan.opacity(0.3))
                .offset(x: -2, y: -2)

            // Main text
            Text(text)
                .font(.system(size: 42, weight: .black, design: .monospaced))
                .foregroundColor(.white)

        }
        .offset(x: glitchOffset)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.05).repeatForever(autoreverses: true)) {
                glitchOffset = CGFloat.random(in: -5...5)
            }
        }
    }
}
