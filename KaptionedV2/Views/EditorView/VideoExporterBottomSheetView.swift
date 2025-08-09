//
//  VideoExporterBottomSheetView.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 24.04.2023.
//

import SwiftUI

struct VideoExporterBottomSheetView: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel: ExporterViewModel
    
    init(isPresented: Binding<Bool>, video: Video) {
        self._isPresented = isPresented
        self._viewModel = StateObject(wrappedValue: ExporterViewModel(video: video))
    }
    var body: some View {
        SheetView(isPresented: $isPresented, bgOpacity: 0.1) {
            VStack(alignment: .leading){
                
                switch viewModel.renderState{
                case .unknown:
                    list
                case .failed:
                    Text("Failed")
                case .loading, .loaded:
                    loadingView
                case .saved:
                    saveView
                }
            }
            .hCenter()
            .frame(height: getRect().height / 2.8)
        }
        .ignoresSafeArea()
        .alert("Save video", isPresented: $viewModel.showAlert) {}
        .disabled(viewModel.renderState == .loading)
        .animation(.easeInOut, value: viewModel.renderState)
    }
}

struct VideoQualityPopapView2_Previews: PreviewProvider {
    static var previews: some View {
        ZStack(alignment: .bottom){
            Color.secondary.opacity(0.5)
            VideoExporterBottomSheetView(isPresented: .constant(true), video: Video.mock)
        }
    }
}

extension VideoExporterBottomSheetView{
    
    
    private var list: some View{
        Group{
            qualityListSection
            
            HStack {
                saveButton
                shareButton
            }
            .padding(.top, 10)
        }
    }
    
    private var loadingView: some View{
        VStack(spacing: 24){
            // Stage indicator with icon
            VStack(spacing: 16) {
                Image(systemName: viewModel.currentStage.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.blue)
                    .scaleEffect(viewModel.renderState == .loading ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: viewModel.renderState == .loading)
                
                Text(viewModel.currentStage.rawValue)
                    .font(.title2.bold())
                
                Text(viewModel.currentStage.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Progress bar
            VStack(spacing: 8) {
                ProgressView(value: viewModel.overallProgress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .scaleEffect(y: 2)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.overallProgress)
                
                HStack {
                    Text("\(Int(viewModel.overallProgress * 100))%")
                        .font(.caption.bold())
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    // Animated dots instead of timer
                    AnimatedDotsView()
                }
            }
            
            // Stage indicators
            HStack(spacing: 12) {
                ForEach(ExporterViewModel.ExportStage.allCases, id: \.self) { stage in
                    stageIndicator(for: stage)
                }
            }
            .padding(.top, 8)
            
            Text("Do not close the app or lock the screen")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private func stageIndicator(for stage: ExporterViewModel.ExportStage) -> some View {
        let isActive = viewModel.currentStage == stage
        let isCompleted = ExporterViewModel.ExportStage.allCases.firstIndex(of: viewModel.currentStage)! >= ExporterViewModel.ExportStage.allCases.firstIndex(of: stage)!
        
        VStack(spacing: 4) {
            Circle()
                .fill(isCompleted ? Color.blue : Color.gray.opacity(0.3))
                .frame(width: 8, height: 8)
                .scaleEffect(isActive ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isActive)
            
            Text(stage.rawValue.prefix(8) + (stage.rawValue.count > 8 ? "..." : ""))
                .font(.system(size: 8, weight: isActive ? .semibold : .regular))
                .foregroundColor(isActive ? .blue : .secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    
    private var saveView: some View{
        VStack(spacing: 20){
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(.green)
            
            Text("Video saved to Photos")
                .font(.title2.bold())
            
            Button {
                openPhotosApp()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle")
                    Text("Open in Photos")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .foregroundColor(.white)
                .background(Color.blue, in: RoundedRectangle(cornerRadius: 20))
            }
            
            Button {
                viewModel.renderState = .unknown
            } label: {
                Text("Done")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func openPhotosApp() {
        if let url = URL(string: "photos-redirect://") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    private var qualityListSection: some View{
        ForEach(VideoQuality.allCases.reversed(), id: \.self) { type in
            
            HStack{
                VStack(alignment: .leading) {
                    Text(type.title)
                        .font(.headline)
                    Text(type.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if let value = type.calculateVideoSize(duration: viewModel.video.totalDuration){
                    Text(String(format: "%.1fMb", value))
                }
            }
            .padding(10)
            .hLeading()
            .background{
                if viewModel.selectedQuality == type{
                    RoundedRectangle(cornerRadius: 10)
                        .fill( Color(.systemGray5))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.selectedQuality = type
            }
        }
    }
    
    
    private var saveButton: some View{
        Button {
            mainAction(.save)
        } label: {
            buttonLabel("Save", icon: "square.and.arrow.down")
        }
        .hCenter()
    }
    
    private var shareButton: some View{
        Button {
            mainAction(.share)
        } label: {
            buttonLabel("Share", icon: "square.and.arrow.up")
        }
        .hCenter()
    }
    
    private func buttonLabel(_ label: String, icon: String) -> some View{
        
        VStack{
            Image(systemName: icon)
                .imageScale(.large)
                .padding(10)
                .background(Color(.systemGray), in: Circle())
            Text(label)
        }
        .foregroundColor(.white)
    }
    
    
    private func mainAction(_ action: ExporterViewModel.ActionEnum){
        Task{
           await viewModel.action(action)
        }
    }

}







// MARK: - Animated Dots View
struct AnimatedDotsView: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 4, height: 4)
                    .scaleEffect(1.0 + animationOffset)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: animationOffset
                    )
            }
        }
        .onAppear {
            animationOffset = 0.5
        }
    }
}

extension UIViewController {
    
    func presentInKeyWindow(animated: Bool = true, completion: (() -> Void)? = nil) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            window.rootViewController?.present(self, animated: animated, completion: completion)
        }
    }
}
