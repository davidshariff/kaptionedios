//
//  MainEditorView.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 14.04.2023.
//
import AVKit
import SwiftUI
import PhotosUI

struct MainEditorView: View {

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    var project: ProjectEntity?
    var selectedVideoURl: URL?
    @State var isFullScreen: Bool = false
    @State var showVideoQualitySheet: Bool = false
    @State var showRecordView: Bool = false
    @State var showCustomSubslistSheet: Bool = false
    @StateObject var editorVM = EditorViewModel()
    @StateObject var audioRecorder = AudioRecorderManager()
    @StateObject var videoPlayer = VideoPlayerManager()
    @StateObject var textEditor = TextEditorViewModel()
    
    var body: some View {
        ZStack{
            GeometryReader { proxy in
                VStack(spacing: 0){
                    headerView(safeAreaTop: proxy.safeAreaInsets.top)
                    // video player
                    PlayerHolderView(isFullScreen: $isFullScreen, editorVM: editorVM, videoPlayer: videoPlayer, textEditor: textEditor)
                        .frame(height: proxy.size.height / (isFullScreen ?  1.25 : 1.8))
                    // player control
                    PlayerControl(isFullScreen: $isFullScreen, recorderManager: audioRecorder, editorVM: editorVM, videoPlayer: videoPlayer, textEditor: textEditor)
                    Spacer()
                    // tools section
                    ToolsSectionView(videoPlayer: videoPlayer, editorVM: editorVM, textEditor: textEditor, showCustomSubslistSheet: $showCustomSubslistSheet)
                        .opacity(isFullScreen ? 0 : 1)
                        .padding(.bottom, 20)
                }
                .onAppear{
                    setVideo(proxy)
                }
            }
            
            if showVideoQualitySheet, let video = editorVM.currentVideo{
                VideoExporterBottomSheetView(isPresented: $showVideoQualitySheet, video: video)
            }
            // Loading overlay for subtitle generation
            if editorVM.isLoading {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    ProgressView("Generating subtitles...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .foregroundColor(.white)
                        .padding(32)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .ignoresSafeArea()
            }
            // Error overlay for subtitle generation
            if editorVM.showErrorAlert {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        Text("Error")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text(editorVM.errorMessage)
                            .font(.body)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                        Button(action: { editorVM.showErrorAlert = false }) {
                            Text("Dismiss")
                                .fontWeight(.semibold)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding(32)
                    .background(Color(.systemGray6).opacity(0.95))
                    .cornerRadius(20)
                    .shadow(radius: 20)
                    .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .transition(.opacity)
                .animation(.easeInOut, value: editorVM.showErrorAlert)
            }
            
            // Custom subslist sheet
            if showCustomSubslistSheet {
                SubslistView(isPresented: $showCustomSubslistSheet, textEditor: textEditor, videoPlayer: videoPlayer)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1000)
                    .animation(.easeInOut(duration: 0.5), value: showCustomSubslistSheet)
            }
        }
        .background(Color.black)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .ignoresSafeArea(.all, edges: .top)
        .fullScreenCover(isPresented: $showRecordView) {
            RecordVideoView{ url in
                videoPlayer.loadState = .loaded(url)
            }
        }
        .statusBar(hidden: true)
        .onChange(of: scenePhase) { phase in
            saveProject(phase)
        }
        .blur(radius: textEditor.showEditor ? 10 : 0)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .overlay {
            if textEditor.showEditor{
                TextEditorView(viewModel: textEditor, onSave: editorVM.setText)
            }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        MainEditorView(selectedVideoURl: URL(string: "file:///Users/bogdanzykov/Library/Developer/CoreSimulator/Devices/86D65E8C-7D49-47AF-A511-BFA631289CB1/data/Containers/Data/Application/52E5EF3C-9E78-4676-B3EA-03BD22CCD09A/Documents/video_copy.mp4"))
    }
}

extension MainEditorView{
        private func headerView(safeAreaTop: CGFloat) -> some View{
        HStack{
            Button {
                editorVM.updateProject()
                dismiss()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "folder.fill")
                    Text("Back")
                        .font(.caption2)
                }
                .padding(.top, 8)
                .padding(.leading, 8)
            }

            Spacer()
            
            Button {
                // Ensure text boxes are synced before export
                editorVM.setText(textEditor.textBoxes)
                editorVM.selectedTools = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                    showVideoQualitySheet.toggle()
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up.fill")
                    Text("Export")
                    .font(.caption2)
                }
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .frame(height: 50)
        .padding(.top, safeAreaTop + 40)
        .padding(.bottom)
    }
    
    private func saveProject(_ phase: ScenePhase){
        switch phase{
        case .background, .inactive:
            editorVM.updateProject()
        default:
            break
        }
    }
    
    private func setVideo(_ proxy: GeometryProxy){
        if let selectedVideoURl{
            videoPlayer.loadState = .loaded(selectedVideoURl)
            editorVM.setNewVideo(selectedVideoURl, geo: proxy)
        }
        
        if let project, let url = project.videoURL{
            videoPlayer.loadState = .loaded(url)
            editorVM.setProject(project, geo: proxy)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                videoPlayer.setFilters(mainFilter: CIFilter(name: project.filterName ?? ""), colorCorrection: editorVM.currentVideo?.colorCorrection)
            }
        }
    }
}



