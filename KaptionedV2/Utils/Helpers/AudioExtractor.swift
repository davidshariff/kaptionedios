import Foundation
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
            let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".m4a")
            guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
                completion(nil)
                return
            }
            exporter.outputURL = outputURL
            exporter.outputFileType = .m4a
            exporter.exportAsynchronously {
                DispatchQueue.main.async {
                    completion(exporter.status == .completed ? outputURL : nil)
                }
            }
        } catch {
            completion(nil)
        }
    }
} 