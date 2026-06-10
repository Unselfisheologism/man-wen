import Foundation
import CoreML
import Vision

actor NSFWDetector {

    static let shared = NSFWDetector()

    private var model: VNCoreMLModel?
    private let modelName = "NSFW"

    private init() {
        loadModel()
    }

    private func loadModel() {
        guard let coreMLModel = try? MLModel(contentsOf: Bundle.main.url(forResource: modelName, withExtension: "mlmodelc")!)
        else {
            print("[NSFWDetector] Failed to load CoreML model")
            return
        }

        do {
            model = try VNCoreMLModel(for: coreMLModel)
            print("[NSFWDetector] Model loaded successfully")
        } catch {
            print("[NSFWDetector] VNCoreMLModel creation failed: \(error)")
        }
    }

    func isAvailable() -> Bool { model != nil }

    func detect(pixelBuffer: CVPixelBuffer) async -> DetectionResult {
        guard let model = model else { return .safe }

        let request = VNCoreMLRequest(model: model) { [weak self] request, _ in
            self?.processResults(request)
        }
        request.imageCropAndScaleOption = .scaleFill

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([request])
            if let result = await currentResult { return result }
            return .safe
        } catch {
            print("[NSFWDetector] Inference failed: \(error)")
            return .safe
        }
    }

    nonisolated var currentResult: DetectionResult? = nil

    func processResults(_ request: VNRequest) {
        guard let results = request.results as? [VNClassificationObservation] else { return }
        currentResult = DetectionResult.from(results)
    }

    struct DetectionResult {
        let probabilities: [String: Float]
        let topClass: String
        let topConfidence: Float
        let isNSFW: Bool
        let pornConfidence: Float
        let hentaiConfidence: Float

        static func from(_ observations: [VNClassificationObservation]) -> DetectionResult {
            let probs = Dictionary(uniqueKeysWithValues: observations.map { ($0.identifier, $0.confidence) })
            let sorted = observations.sorted { $0.confidence > $1.confidence }
            let top = sorted.first
            let topClass = top?.identifier ?? "Neutral"
            let topConf = top?.confidence ?? 0

            let porn = probs["Porn"] ?? 0
            let hentai = probs["Hentai"] ?? 0
            let isNSFW = porn > 0.75 || hentai > 0.75

            return DetectionResult(
                probabilities: probs,
                topClass: topClass,
                topConfidence: topConf,
                isNSFW: isNSFW,
                pornConfidence: porn,
                hentaiConfidence: hentai
            )
        }

        static let safe = DetectionResult(
            probabilities: ["Neutral": 0.9, "Drawing": 0.05, "Porn": 0.03, "Sexy": 0.01, "Hentai": 0.01],
            topClass: "Neutral",
            topConfidence: 0.9,
            isNSFW: false,
            pornConfidence: 0.03,
            hentaiConfidence: 0.01
        )
    }
}