//
//  TranscriptionHelper.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 24.04.2023.
//

import Foundation
import SwiftUI

class TranscriptionHelper {
    static let shared = TranscriptionHelper()
    
    private init() {}
    
    func transcribeVideo(
        fileURL: URL,
        language: String? = nil,
        max_words_per_line: Int? = nil,
        completion: @escaping (Result<[TextBox], Error>) -> Void
    ) {
        // Use configuration manager for defaults
        let configManager = ConfigurationManager.shared
        let defaultLanguage = language ?? configManager.getDefaultLanguage()
        let defaultMaxWordsPerLine = max_words_per_line ?? configManager.getDefaultMaxWordsPerLine()
        // Start audio extraction from the provided video file
        print("[TranscriptionHelper] Starting audio extraction from video: \(fileURL)")

        AudioExtractor.extractAudio(from: fileURL) { audioURL in

            // Check if audio extraction succeeded
            guard let audioURL = audioURL else {
                print("[TranscriptionHelper] Audio extraction failed for video: \(fileURL)")
                completion(.failure(NSError(domain: "Audio extraction failed", code: 0)))
                return
            }

            print("[TranscriptionHelper] Audio extracted: \(audioURL)")

            // Prepare the API endpoint and request using configuration manager
            let url = configManager.getTranscriptionURL()
            var request = URLRequest(url: url)
            request.httpMethod = "POST"

            // Set up multipart form boundary and headers
            let boundary = UUID().uuidString
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "accept")

            var data = Data()

            // --- Add audio file to multipart form data ---
            let filename = audioURL.lastPathComponent
            let mimetype = "audio/m4a"

            guard let fileData = try? Data(contentsOf: audioURL) else {
                print("[TranscriptionHelper] Failed to read audio file data: \(audioURL)")
                completion(.failure(NSError(domain: "File error", code: 0)))
                return
            }

            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: \(mimetype)\r\n\r\n".data(using: .utf8)!)
            data.append(fileData)
            data.append("\r\n".data(using: .utf8)!)

            // --- Add primary language field to multipart form data ---
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"primary_lang\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(defaultLanguage)\r\n".data(using: .utf8)!)
            
            // --- Add max_words_per_line field to multipart form data ---
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"max_words_per_line\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(defaultMaxWordsPerLine)\r\n".data(using: .utf8)!)
            data.append("--\(boundary)--\r\n".data(using: .utf8)!)

            print("[TranscriptionHelper] Starting upload to API: \(url)")

            // Start the upload task to the transcription API
            let task = URLSession.shared.uploadTask(with: request, from: data) { responseData, response, error in

                // Handle upload/network error
                if let error = error {
                    print("[TranscriptionHelper] Upload error: \(error)")
                    completion(.failure(error))
                    return
                }

                // Ensure we received data from the API
                guard let responseData = responseData else {
                    print("[TranscriptionHelper] No data received from API")
                    completion(.failure(NSError(domain: "No data", code: 0)))
                    return
                }

                if String(data: responseData, encoding: .utf8) == nil {
                    print("[TranscriptionHelper] Could not decode API response as UTF-8 string ")
                }

                print("[TranscriptionHelper] Received response from API, decoding...")

                do {
                    // Decode the API response into our model
                    let decoder = JSONDecoder()
                    let result = try decoder.decode(TranscriptionResponse.self, from: responseData)

                    // Map API segments to TextBox models
                    let textBoxes = result.segments.map { segment in
                        let start = segment.words.first?.start ?? 0
                        let end = segment.words.last?.end ?? (start + 1)

                        // Build karaoke word timing array
                        let wordTimings = segment.words.map { w in
                            WordWithTiming(text: w.word, start: w.start, end: w.end)
                        }

                        // Create a TextBox for each segment
                        return TextBox(
                            text: segment.sentence,
                            timeRange: start...end,
                            wordTimings: wordTimings,
                            presetName: configManager.getDefaultPreset()
                        )
                    }

                    print("[TranscriptionHelper] Decoding successful, returning \(textBoxes.count) text boxes.")
                    completion(.success(textBoxes))

                } catch {
                    // Handle JSON decoding error
                    print("[TranscriptionHelper] Decoding error: \(error)")
                    // Print the raw response again for easier debugging
                    if let rawString = String(data: responseData, encoding: .utf8) {
                        print("[TranscriptionHelper] Raw response (on error):\n\(rawString)")
                    }
                    completion(.failure(error))
                }
            }

            // Start the network request
            task.resume()
        }
    }

} 