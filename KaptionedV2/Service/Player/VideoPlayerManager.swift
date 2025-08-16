//
//  VideoPlayerManager.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 14.04.2023.
//

import Foundation
import Combine
import AVKit
import PhotosUI
import SwiftUI


final class VideoPlayerManager: ObservableObject{
    
    @Published var currentTime: Double = .zero
    @Published var selectedItem: PhotosPickerItem?
    @Published var loadState: LoadState = .unknown
    @Published private(set) var videoPlayer = AVPlayer()
    @Published private(set) var isPlaying: Bool = false
    @Published var isMuted: Bool = false
    private var cancellable = Set<AnyCancellable>()
    private var timeObserver: Any?
    private var currentDurationRange: ClosedRange<Double>?
    
    
    deinit {
        removeTimeObserver()
    }
    
    init(){
        onSubsUrl()
    }
    
    
    var scrubState: PlayerScrubState = .reset {
        didSet {
            switch scrubState {
            case .scrubEnded(let seekTime):
                pause()
                seek(seekTime, player: videoPlayer)

            default : break
            }
        }
    }
    
    func action(_ video: Video){
        self.currentDurationRange = 0...video.originalDuration
        if isPlaying{
            pause()
        }else{
            play()
        }
    }
    

    
    private func onSubsUrl(){
        $loadState
            .dropFirst()
            .receive(on: DispatchQueue.main)
            
            .sink {[weak self] returnLoadState in
                guard let self = self else {return}
                
                switch returnLoadState {
                case .loaded(let url):
                    self.pause()
                    self.videoPlayer = AVPlayer(url: url)
                    self.startStatusSubscriptions()
                    print("AVPlayer set url:", url.absoluteString)
                case .failed, .loading, .unknown:
                    break
                }
            }
            .store(in: &cancellable)
    }
    
    
    private func startStatusSubscriptions(){
        videoPlayer.publisher(for: \.timeControlStatus)
            .sink { [weak self] status in
                guard let self = self else {return}
                switch status {
                case .playing:
                    self.isPlaying = true
                    self.startTimer()
                case .paused:
                    self.isPlaying = false
                case .waitingToPlayAtSpecifiedRate:
                    break
                @unknown default:
                    break
                }
            }
            .store(in: &cancellable)
    }
    
    
    func pause(){
        if isPlaying{
            videoPlayer.pause()
        }
    }
    
    func setVolume(_ value: Float){
        pause()
        videoPlayer.volume = value
    }
    
    func toggleMute() {
        isMuted.toggle()
        if isMuted {
            videoPlayer.volume = 0
        } else {
            videoPlayer.volume = 1
        }
    }

    private func play(){
        
        AVAudioSession.sharedInstance().configurePlaybackSession()
        
        if let currentDurationRange{
            if currentTime >= currentDurationRange.upperBound{
                seek(currentDurationRange.lowerBound, player: videoPlayer)
            }else{
                seek(videoPlayer.currentTime().seconds, player: videoPlayer)
            }
        }
        videoPlayer.play()
        
        if let currentDurationRange, videoPlayer.currentItem?.duration.seconds ?? 0 >= currentDurationRange.upperBound{
            NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: videoPlayer.currentItem, queue: .main) { _ in
                self.playerDidFinishPlaying()
            }
        }
    }
    
    func seek(_ seconds: Double, player: AVPlayer){
        player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
    }
    
    func seekToTime(_ seconds: Double) {
        seek(seconds, player: videoPlayer)
        // Update currentTime immediately so the UI reflects the new position
        currentTime = seconds
    }
    
    private func startTimer() {
        
        let interval = CMTimeMake(value: 1, timescale: 10)
        timeObserver = videoPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            if self.isPlaying{
                let time = time.seconds
                
                if let currentDurationRange = self.currentDurationRange, time >= currentDurationRange.upperBound{
                    self.pause()
                }

                switch self.scrubState {
                case .reset:
                    self.currentTime = time
                case .scrubEnded:
                    self.scrubState = .reset
                case .scrubStarted:
                    break
                }
            }
        }
    }
    
    
    private func playerDidFinishPlaying() {
        self.videoPlayer.seek(to: .zero)
    }
    
    private func removeTimeObserver(){
        if let timeObserver = timeObserver {
            videoPlayer.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }
    
    /// Completely unloads the video player and frees memory
    func unloadVideo() {
        // Pause any playing video
        pause()
        
        // Remove time observer
        removeTimeObserver()
        
        // Clear players by replacing with empty ones
        videoPlayer = AVPlayer()
        
        // Reset state
        currentTime = .zero
        loadState = .unknown
        isPlaying = false
        currentDurationRange = nil
        scrubState = .reset
        
        // Cancel all subscriptions
        cancellable.removeAll()
        
        // Re-initialize subscriptions for future use
        onSubsUrl()
        
        print("Video player unloaded and memory freed")
    }
    
}

extension VideoPlayerManager{
    
    @MainActor
    func loadVideoItem(_ selectedItem: PhotosPickerItem?) async{
        do {
            loadState = .loading

            if let video = try await selectedItem?.loadTransferable(type: VideoItem.self) {
                loadState = .loaded(video.url)
            } else {
                loadState = .failed
            }
        } catch {
            loadState = .failed
        }
    }
}


extension VideoPlayerManager{
    


}

enum LoadState: Identifiable, Equatable {
    case unknown, loading, loaded(URL), failed
    
    var id: Int{
        switch self {
        case .unknown: return 0
        case .loading: return 1
        case .loaded: return 2
        case .failed: return 3
        }
    }
}


enum PlayerScrubState{
    case reset
    case scrubStarted
    case scrubEnded(Double)
}



