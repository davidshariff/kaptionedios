//
//  AudioExtractor.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 04.05.2023.
//

import AVFoundation

class AudioExtractor {
    static func extractAudio(from videoURL: URL, completion: @escaping (URL?) -> Void) {
        Task {
            do {
                let asset = AVAsset(url: videoURL)
                let audioTracks = try await asset.loadTracks(withMediaType: .audio)
                
                guard let audioTrack = audioTracks.first else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                
                let composition = AVMutableComposition()
                guard let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                
                let duration = try await asset.load(.duration)
                try compositionAudioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: audioTrack, at: .zero)
                
                let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".m4a")
                
                guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                
                exportSession.outputURL = outputURL
                exportSession.outputFileType = .m4a
                
                await exportSession.export()
                
                DispatchQueue.main.async {
                    if exportSession.status == .completed {
                        completion(outputURL)
                    } else {
                        print("❌ [AudioExtractor] Export failed with status: \(exportSession.status.rawValue)")
                        if let error = exportSession.error {
                            print("❌ [AudioExtractor] Export error: \(error)")
                        }
                        completion(nil)
                    }
                }
            } catch {
                print("❌ [AudioExtractor] Error extracting audio: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
}
