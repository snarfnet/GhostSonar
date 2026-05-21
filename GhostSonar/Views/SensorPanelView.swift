import SwiftUI

struct SensorPanelView: View {
    @EnvironmentObject var sensorManager: SensorManager
    @EnvironmentObject var ghostEngine: GhostDetectionEngine

    var body: some View {
        VStack(spacing: 8) {
            // Sensor gauges row
            HStack(spacing: 12) {
                SensorGauge(
                    label: "EMF",
                    value: sensorManager.emfLevel,
                    icon: "bolt.fill",
                    unit: "mG"
                )
                SensorGauge(
                    label: "EVP",
                    value: sensorManager.audioLevel,
                    icon: "waveform",
                    unit: "dB"
                )
                SensorGauge(
                    label: "PRES",
                    value: sensorManager.pressureLevel,
                    icon: "barometer",
                    unit: "hPa"
                )
                SensorGauge(
                    label: "VIB",
                    value: sensorManager.vibrationLevel,
                    icon: "waveform.path.ecg",
                    unit: "g"
                )
            }
            .padding(.horizontal)
        }
    }
}

struct SensorGauge: View {
    let label: String
    let value: Double
    let icon: String
    let unit: String

    private var gaugeColor: Color {
        switch value {
        case 0..<0.3: return Color("sonarGreen")
        case 0.3..<0.6: return Color("sonarYellow")
        case 0.6..<0.85: return Color("sonarOrange")
        default: return Color("sonarRed")
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(gaugeColor)

            // Label
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(Color("sonarGreen").opacity(0.7))

            // Bar gauge
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    // Background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color("sonarGreen").opacity(0.1))

                    // Fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(gaugeColor.opacity(0.8))
                        .frame(height: geo.size.height * value)

                    // Segments
                    VStack(spacing: 1) {
                        ForEach(0..<10, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.black.opacity(0.3))
                                .frame(height: 1)
                        }
                    }
                }
            }
            .frame(width: 20, height: 50)

            // Value
            Text("\(Int(value * 100))")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(gaugeColor)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Detection Log
struct DetectionLogView: View {
    @EnvironmentObject var ghostEngine: GhostDetectionEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: "list.bullet")
                    .font(.system(size: 13))
                Text("DETECTION LOG")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                Spacer()
                Text("\(ghostEngine.detectionCount) CONTACTS")
                    .font(.system(size: 12, design: .monospaced))
            }
            .foregroundColor(Color("sonarGreen").opacity(0.7))
            .padding(.horizontal)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 1) {
                    ForEach(ghostEngine.detections.suffix(8).reversed()) { detection in
                        DetectionLogRow(detection: detection)
                    }
                }
            }
            .frame(maxHeight: 120)
        }
    }
}

struct DetectionLogRow: View {
    let detection: GhostReading
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    private var rowColor: Color {
        switch detection.threatLevel {
        case .low: return Color("sonarGreen")
        case .medium: return Color("sonarYellow")
        case .high: return Color("sonarOrange")
        case .critical: return Color("sonarRed")
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(dateFormatter.string(from: detection.timestamp))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(Color("sonarGreen").opacity(0.5))

            Image(systemName: detection.type.icon)
                .font(.system(size: 11))
                .foregroundColor(rowColor)

            Text(detection.type.rawValue)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(rowColor)
                .frame(width: 45, alignment: .leading)

            Text(detection.description)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(rowColor.opacity(0.7))
                .lineLimit(1)

            Spacer()

            Text("\(Int(detection.intensity * 100))%")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(rowColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
        .background(rowColor.opacity(0.05))
    }
}
