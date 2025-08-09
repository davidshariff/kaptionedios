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
        SheetView(
            isPresented: $isPresented, 
            bgOpacity: 0.4, 
            allowDismiss: viewModel.renderState != .loading
        ) {
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
            .frame(height: dynamicSheetHeight)
            .frame(maxHeight: dynamicSheetHeight) // Prevent height changes
        }
        .ignoresSafeArea()
        .alert("Save video", isPresented: $viewModel.showAlert) {}
        .disabled(viewModel.renderState == .loading)
        .animation(.easeInOut, value: viewModel.renderState)
    }
    
    private var dynamicSheetHeight: CGFloat {
        switch viewModel.renderState {
        case .loading, .loaded, .saved:
            return getRect().height / 2.2  // Bigger for export states
        default:
            return getRect().height / 2.8  // Normal size for quality selection
        }
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
        VStack(spacing: 32){
            // Main progress section
            VStack(spacing: 24) {
                // Stage indicator with enhanced icon
                VStack(spacing: 20) {
                    ZStack {
                        // Background circle
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        // Animated ring
                        Circle()
                            .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                            .frame(width: 80, height: 80)
                            .scaleEffect(viewModel.currentStage == .firstPass ? 1.3 : 1.0)
                            .opacity(viewModel.currentStage == .firstPass ? 0.3 : 0.8)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: viewModel.currentStage == .firstPass)
                        
                        // Second animated ring for ripple effect
                        if viewModel.currentStage == .firstPass {
                            Circle()
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                .frame(width: 80, height: 80)
                                .scaleEffect(1.6)
                                .opacity(0.2)
                                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.7), value: viewModel.currentStage == .firstPass)
                        }
                        
                        // Main icon with stage-specific animations
                        Image(systemName: viewModel.currentStage.icon)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.blue)
                            .rotationEffect(.degrees(viewModel.currentStage == .firstPass ? 360 : 0))
                            .animation(
                                viewModel.currentStage == .firstPass ? 
                                .linear(duration: 2.0).repeatForever(autoreverses: false) :
                                .easeInOut(duration: 0.3), 
                                value: viewModel.currentStage == .firstPass
                            )
                    }
                    
                    VStack(spacing: 8) {
                        Text(viewModel.currentStage.rawValue)
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                        
                        Text(viewModel.currentStage.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }
                
                // Enhanced progress section
                VStack(spacing: 16) {
                    // Custom progress bar with gradient - fixed container
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                            
                            // Progress fill with gradient
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(8, CGFloat(viewModel.overallProgress) * geometry.size.width), height: 8)
                                .animation(.easeOut(duration: 0.3), value: viewModel.overallProgress)
                        }
                    }
                    .frame(height: 8) // Fixed height for progress bar container
                    
                    // Progress info
                    HStack {
                        // Percentage with enhanced styling
                        HStack(spacing: 4) {
                            Text("\(Int(viewModel.overallProgress * 100))")
                                .font(.title3.bold().monospacedDigit())
                                .foregroundColor(.blue)
                                .contentTransition(.numericText())
                                .animation(.easeOut(duration: 0.2), value: viewModel.overallProgress)
                            
                            Text("%")
                                .font(.caption.bold())
                                .foregroundColor(.blue.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        // Enhanced animated indicator
                        HStack(spacing: 6) {
                            Text("Processing")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            AnimatedDotsView()
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            
            // Minimal stage indicators (simplified)
            HStack(spacing: 16) {
                ForEach(ExporterViewModel.ExportStage.allCases.prefix(3), id: \.self) { stage in
                    enhancedStageIndicator(for: stage)
                }
            }
            
            // Warning text with icon
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Text("Keep the app open during export")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.1))
            )
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private func enhancedStageIndicator(for stage: ExporterViewModel.ExportStage) -> some View {
        let isActive = viewModel.currentStage == stage
        let isCompleted = ExporterViewModel.ExportStage.allCases.firstIndex(of: viewModel.currentStage)! >= ExporterViewModel.ExportStage.allCases.firstIndex(of: stage)!
        
        VStack(spacing: 8) {
            ZStack {
                // Background circle
                Circle()
                    .fill(isCompleted ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                // Active ring with pulse effect - only when active
                if isActive {
                    Circle()
                        .stroke(Color.blue, lineWidth: 2)
                        .frame(width: 32, height: 32)
                        .scaleEffect(1.2)
                        .opacity(0.6)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isActive)
                    
                    // Outer pulse ring - only when active
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        .frame(width: 32, height: 32)
                        .scaleEffect(1.5)
                        .opacity(0.3)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.3), value: isActive)
                }
                
                // Icon or checkmark
                if isCompleted && !isActive {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: stage.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isActive ? .blue : .secondary)
                        .scaleEffect(isActive ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: isActive)
                }
            }
            
            Text(getStageDisplayName(stage))
                .font(.system(size: 10, weight: isActive ? .semibold : .regular))
                .foregroundColor(isActive ? .blue : .secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .scaleEffect(isActive ? 1.05 : 1.0)
        .animation(isActive ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .easeInOut(duration: 0.3), value: isActive)
    }
    
    private func getStageDisplayName(_ stage: ExporterViewModel.ExportStage) -> String {
        switch stage {
        case .preparing: return "Setup"
        case .firstPass: return "Processing"
        case .encoding: return "Finalizing"
        case .saving: return "Saving"
        case .completed: return "Done"
        }
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
        VStack(spacing: 32){
            // Success animation
            VStack(spacing: 24) {
                ZStack {
                    // Background circle with animation
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .scaleEffect(1.2)
                        .opacity(0.8)
                        .animation(.easeOut(duration: 0.5), value: viewModel.renderState == .saved)
                    
                    // Success icon
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundColor(.green)
                        .scaleEffect(1.1)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0), value: viewModel.renderState == .saved)
                }
                
                VStack(spacing: 12) {
                    Text("Export Complete!")
                        .font(.title.bold())
                        .foregroundColor(.primary)
                    
                    Text("Your video has been saved to Photos")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            
            // Action buttons
            VStack(spacing: 12) {
                Button {
                    openPhotosApp()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 16, weight: .medium))
                        Text("Open in Photos")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }
                
                Button {
                    viewModel.renderState = .unknown
                } label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                        )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, 20)
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
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 5, height: 5)
                    .scaleEffect(1.0 + (animationOffset * 0.8))
                    .opacity(0.6 + (animationOffset * 0.4))
                    .animation(
                        .easeInOut(duration: 0.8)
                        .repeatForever()
                        .delay(Double(index) * 0.25),
                        value: animationOffset
                    )
            }
        }
        .onAppear {
            animationOffset = 1.0
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
