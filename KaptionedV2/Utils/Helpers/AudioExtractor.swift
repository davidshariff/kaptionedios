//
//  AudioExtractor.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 04.05.2023.
//

import AVFoundation

class AudioExtractor {
    static func extractAudio(from videoURL: URL, completion: @escaping (URL?) -> Void) {
        let asset = AVAsset(url: videoURL)
        guard let audioTrack = asset.tracks(withMediaType: .audio).first else {
            completion(nil)
            return
        }
        
        let composition = AVMutableComposition()
        guard let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion(nil)
            return
        }
        
        do {
            try compositionAudioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: audioTrack, at: .zero)
            
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("extracted_audio.m4a")
            
            let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)
            exportSession?.outputURL = outputURL
            exportSession?.outputFileType = .m4a
            
            exportSession?.exportAsynchronously {
                DispatchQueue.main.async {
                    if exportSession?.status == .completed {
                        completion(outputURL)
                    } else {
                        completion(nil)
                    }
                }
            }
        } catch {
            completion(nil)
        }
    }
}
