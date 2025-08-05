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
        completion: @escaping (Result<[TextBox], Error>) -> Void
    ) {
        print("[TranscriptionHelper] Starting audio extraction from video: \(fileURL)")
        AudioExtractor.extractAudio(from: fileURL) { audioURL in
            guard let audioURL = audioURL else {
                print("[TranscriptionHelper] Audio extraction failed for video: \(fileURL)")
                completion(.failure(NSError(domain: "Audio extraction failed", code: 0)))
                return
            }
            print("[TranscriptionHelper] Audio extracted: \(audioURL)")
            let url = URL(string: "https://premium-tetra-together.ngrok-free.app/transcribe")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            let boundary = UUID().uuidString
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "accept")
            var data = Data()
            // Add file
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
            // Add primary_lang
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"primary_lang\"\r\n\r\n".data(using: .utf8)!)
            data.append("en\r\n".data(using: .utf8)!)
            data.append("--\(boundary)--\r\n".data(using: .utf8)!)
            print("[TranscriptionHelper] Starting upload to API: \(url)")
            let task = URLSession.shared.uploadTask(with: request, from: data) { responseData, response, error in
                if let error = error {
                    print("[TranscriptionHelper] Upload error: \(error)")
                    completion(.failure(error))
                    return
                }
                guard let responseData = responseData else {
                    print("[TranscriptionHelper] No data received from API")
                    completion(.failure(NSError(domain: "No data", code: 0)))
                    return
                }
                print("[TranscriptionHelper] Received response from API, decoding...")
                do {
                    let decoder = JSONDecoder()
                    let result = try decoder.decode(TranscriptionResponse.self, from: responseData)
                    let textBoxes = result.segments.map { segment in
                        let start = segment.words.first?.start ?? 0
                        let end = segment.words.last?.end ?? (start + 1)
                        let karaokeWords = segment.words.map { w in
                            KaraokeWord(text: w.word, start: w.start, end: w.end)
                        }
                        return TextBox(
                            text: segment.sentence,
                            timeRange: start...end,
                            karaokeWords: karaokeWords,
                            karaokeType: .word
                        )
                    }
                    print("[TranscriptionHelper] Decoding successful, returning \(textBoxes.count) text boxes.")
                    completion(.success(textBoxes))
                } catch {
                    print("[TranscriptionHelper] Decoding error: \(error)")
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
} 