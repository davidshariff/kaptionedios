import Foundation

// MARK: - API Response Models
struct TranscriptionResponse: Codable {
    let segments: [TranscriptionSegment]
}

struct TranscriptionSegment: Codable {
    let sentence: String
    let words: [TranscriptionWord]
}

struct TranscriptionWord: Codable {
    let word: String
    let start: Double
    let end: Double
    let probability: Double
} 