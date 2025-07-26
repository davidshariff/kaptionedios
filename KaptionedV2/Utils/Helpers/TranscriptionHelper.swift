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
        let url = URL(string: "http://127.0.0.1:8000/transcribe")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        var data = Data()
        
        // Add file
        let filename = fileURL.lastPathComponent
        let mimetype = "video/quicktime"
        guard let fileData = try? Data(contentsOf: fileURL) else {
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
        
        let task = URLSession.shared.uploadTask(with: request, from: data) { responseData, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let responseData = responseData else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            
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
                completion(.success(textBoxes))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
} 