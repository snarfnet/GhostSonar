import Foundation
import CoreLocation

struct GhostReading: Identifiable {
    let id = UUID()
    let timestamp: Date
    let type: GhostSignalType
    let intensity: Double // 0.0 - 1.0
    let angle: Double // radians on radar
    let distance: Double // 0.0 - 1.0 from center
    let description: String

    var threatLevel: ThreatLevel {
        switch intensity {
        case 0.0..<0.3: return .low
        case 0.3..<0.6: return .medium
        case 0.6..<0.85: return .high
        default: return .critical
        }
    }
}

enum GhostSignalType: String, CaseIterable {
    case emf = "EMF"
    case evp = "EVP"
    case pressure = "PRESSURE"
    case vibration = "VIBRATION"
    case multiSensor = "MULTI"

    var label: String {
        switch self {
        case .emf: return "EMF ANOMALY"
        case .evp: return "EVP SIGNAL"
        case .pressure: return "PRESSURE DROP"
        case .vibration: return "VIBRATION"
        case .multiSensor: return "MULTI-SENSOR"
        }
    }

    var icon: String {
        switch self {
        case .emf: return "bolt.fill"
        case .evp: return "waveform"
        case .pressure: return "barometer"
        case .vibration: return "waveform.path.ecg"
        case .multiSensor: return "exclamationmark.triangle.fill"
        }
    }
}

enum ThreatLevel: String {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    case critical = "CRITICAL"

    var color: String {
        switch self {
        case .low: return "sonarGreen"
        case .medium: return "sonarYellow"
        case .high: return "sonarOrange"
        case .critical: return "sonarRed"
        }
    }
}

struct SensorSnapshot {
    var magneticField: (x: Double, y: Double, z: Double) = (0, 0, 0)
    var magneticMagnitude: Double = 0
    var pressure: Double = 0
    var pressureDelta: Double = 0
    var audioLevel: Double = 0
    var audioFreqPeak: Double = 0
    var accelerationMagnitude: Double = 0
    var gyroMagnitude: Double = 0
}
