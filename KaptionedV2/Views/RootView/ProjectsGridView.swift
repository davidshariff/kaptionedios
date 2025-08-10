import SwiftUI
import PhotosUI

struct ProjectsGridView: View {
    @ObservedObject var rootVM: RootViewModel
    @Binding var item: PhotosPickerItem?
    @Binding var showDeleteConfirmation: Bool
    @Binding var projectToDelete: ProjectEntity?
    
    let columns = [
        GridItem(.adaptive(minimum: 150)),
        GridItem(.adaptive(minimum: 150)),
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("My projects")
                .font(.headline)
            
            // Regular grid with projects
            LazyVGrid(columns: columns, alignment: .center, spacing: 10) {
                newProjectButton
                
                ForEach(rootVM.projects) { project in
                    NavigationLink {
                        MainEditorView(project: project)
                    } label: {
                        cellView(project)
                    }
                }
            }
        }
    }
    
    private var newProjectButton: some View {
        PhotosPicker(selection: $item, matching: .videos) {
            VStack(spacing: 10) {
                Image(systemName: "plus")
                Text("New project")
            }
            .hCenter()
            .frame(height: 150)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 5))
            .foregroundColor(.white)
        }
    }
    
    private func cellView(_ project: ProjectEntity) -> some View {
        ZStack {
            Color.white
            Image(uiImage: project.uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
            LinearGradient(colors: [.black.opacity(0.35), .black.opacity(0.2), .black.opacity(0.1)], startPoint: .bottom, endPoint: .top)
        }
        .hCenter()
        .frame(height: 150)
        .cornerRadius(5)
        .clipped()
        .overlay {
            VStack {
                Button {
                    projectToDelete = project
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 5)
                }
                .hTrailing()
                Spacer()
                Text(project.createAt?.formatted(date: .abbreviated, time: .omitted) ?? "")
                    .foregroundColor(.white)
                    .hLeading()
            }
            .font(.footnote.weight(.medium))
            .padding(10)
        }
    }
}
