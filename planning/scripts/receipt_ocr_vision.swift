import Foundation
import Vision
import AppKit

if CommandLine.arguments.count < 2 {
    fputs("Usage: swift receipt_ocr_vision.swift <image-path>\n", stderr)
    exit(1)
}

let path = CommandLine.arguments[1]
let url = URL(fileURLWithPath: path)

guard let image = NSImage(contentsOf: url) else {
    fputs("Failed to load image at: \(path)\n", stderr)
    exit(1)
}

var rect = NSRect(origin: .zero, size: image.size)
guard let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
    fputs("Failed to create CGImage from image\n", stderr)
    exit(1)
}

let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.usesLanguageCorrection = false

let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
try handler.perform([request])

let observations = (request.results ?? []) as [VNRecognizedTextObservation]

let imageWidth = Double(cgImage.width)
let imageHeight = Double(cgImage.height)

let lines: [[String: Any]] = observations.compactMap { observation in
    guard let candidate = observation.topCandidates(1).first else {
        return nil
    }

    let box = observation.boundingBox
    let left = Double(box.minX) * imageWidth
    let right = Double(box.maxX) * imageWidth
    let top = (1.0 - Double(box.maxY)) * imageHeight
    let bottom = (1.0 - Double(box.minY)) * imageHeight

    return [
        "text": candidate.string,
        "left": left,
        "top": top,
        "right": right,
        "bottom": bottom,
    ]
}.sorted { lhs, rhs in
    let lhsTop = lhs["top"] as? Double ?? 0
    let rhsTop = rhs["top"] as? Double ?? 0
    if lhsTop != rhsTop {
        return lhsTop < rhsTop
    }
    let lhsLeft = lhs["left"] as? Double ?? 0
    let rhsLeft = rhs["left"] as? Double ?? 0
    return lhsLeft < rhsLeft
}

let payload: [String: Any] = [
    "image_width": imageWidth,
    "image_height": imageHeight,
    "lines": lines,
]

let json = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted])
FileHandle.standardOutput.write(json)
