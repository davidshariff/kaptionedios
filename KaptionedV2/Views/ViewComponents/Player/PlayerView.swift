//
//  PlayerView.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 18.04.2023.
//

import SwiftUI
import AVKit

struct PlayerView: UIViewControllerRepresentable {
    
    var player: AVPlayer
    var showGrid: Bool = false
    
    typealias UIViewControllerType = AVPlayerViewController
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let view = AVPlayerViewController()
        view.player = player
        view.showsPlaybackControls = false
        view.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
   
}

struct PlayerViewWithGrid: View {
    var player: AVPlayer
    var showGrid: Bool = false
    var originalVideoSize: CGSize = CGSize(width: 1920, height: 1080)
    
    var body: some View {
        ZStack {
            PlayerView(player: player)
            
            if showGrid {
                GridTestView(
                    gridSpacing: 50,
                    gridColor: .white.opacity(0.2),
                    textColor: .white.opacity(0.8),
                    originalVideoSize: originalVideoSize
                )
                .allowsHitTesting(false)
            }
        }
    }
}
