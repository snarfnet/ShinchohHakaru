import Foundation
import ARKit
import Combine

class MeasureManager: NSObject, ObservableObject, ARSessionDelegate {
    @Published var isARAvailable = false
    @Published var isMeasuring = false
    @Published var currentHeight: Double? // cm
    @Published var floorDetected = false
    @Published var personDetected = false
    @Published var statusMessage = ""
    @Published var history: [HeightRecord] = []

    @Published private(set) var arSession: ARSession?

    override init() {
        super.init()
        isARAvailable = ARBodyTrackingConfiguration.isSupported || ARWorldTrackingConfiguration.isSupported
        loadHistory()
    }

    // MARK: - AR Session
    func startSession() {
        guard isARAvailable else {
            statusMessage = NSLocalizedString("status_no_ar", comment: "")
            return
        }

        let session = ARSession()
        session.delegate = self

        if ARBodyTrackingConfiguration.isSupported {
            // Use body tracking config for reliable body detection
            let config = ARBodyTrackingConfiguration()
            config.planeDetection = [.horizontal]
            session.run(config, options: [.resetTracking, .removeExistingAnchors])
        } else {
            // Fallback to world tracking with body detection frame semantics
            let config = ARWorldTrackingConfiguration()
            config.planeDetection = [.horizontal]
            if ARWorldTrackingConfiguration.supportsFrameSemantics(.bodyDetection) {
                config.frameSemantics.insert(.bodyDetection)
            }
            session.run(config, options: [.resetTracking, .removeExistingAnchors])
        }

        arSession = session
        isMeasuring = true
        currentHeight = nil
        statusMessage = NSLocalizedString("status_scanning", comment: "")
    }

    func stopSession() {
        arSession?.pause()
        arSession = nil
        isMeasuring = false
        floorDetected = false
        personDetected = false
    }

    // MARK: - ARSessionDelegate
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Check for body anchor
        if let bodyAnchor = frame.anchors.compactMap({ $0 as? ARBodyAnchor }).first {
            personDetected = true
            calculateHeight(bodyAnchor: bodyAnchor)
        }

        // Check floor detection
        let planes = frame.anchors.compactMap { $0 as? ARPlaneAnchor }
        if planes.contains(where: { $0.classification == .floor || $0.alignment == .horizontal }) {
            if !floorDetected {
                floorDetected = true
                statusMessage = NSLocalizedString("status_floor_found", comment: "")
            }
        }
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let plane = anchor as? ARPlaneAnchor, plane.alignment == .horizontal {
                floorDetected = true
                statusMessage = NSLocalizedString("status_floor_found", comment: "")
            }
            if anchor is ARBodyAnchor {
                personDetected = true
                statusMessage = NSLocalizedString("status_person_found", comment: "")
            }
        }
    }

    private func calculateHeight(bodyAnchor: ARBodyAnchor) {
        let skeleton = bodyAnchor.skeleton

        // Get head and foot positions
        guard let headTransform = skeleton.modelTransform(for: .head),
              let leftFootTransform = skeleton.modelTransform(for: .leftFoot),
              let rightFootTransform = skeleton.modelTransform(for: .rightFoot) else { return }

        let headY = headTransform.columns.3.y
        let leftFootY = leftFootTransform.columns.3.y
        let rightFootY = rightFootTransform.columns.3.y
        let footY = min(leftFootY, rightFootY)

        // Height in meters, add ~10cm for top of head above joint
        let heightM = Double(headY - footY) + 0.10
        let heightCm = heightM * 100

        DispatchQueue.main.async {
            // Smooth the measurement
            if let current = self.currentHeight {
                self.currentHeight = current * 0.7 + heightCm * 0.3
            } else {
                self.currentHeight = heightCm
            }
            self.statusMessage = NSLocalizedString("status_measuring", comment: "")
        }
    }

    // MARK: - Manual measurement (fallback without LiDAR)
    func manualMeasure(referenceHeightCm: Double, referencePixels: Double, personPixels: Double) {
        let height = referenceHeightCm * personPixels / referencePixels
        currentHeight = height
    }

    // MARK: - Save result
    func saveResult(label: String = "") {
        guard let height = currentHeight else { return }
        let record = HeightRecord(heightCm: height, personLabel: label)
        history.append(record)
        if history.count > 50 { history.removeFirst() }
        saveHistory()
    }

    // MARK: - Persistence
    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: "height_history")
        }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "height_history"),
           let decoded = try? JSONDecoder().decode([HeightRecord].self, from: data) {
            history = decoded
        }
    }

    func clearHistory() {
        history = []
        saveHistory()
    }
}
