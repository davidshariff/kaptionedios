import SwiftUI

struct LanguagePickerSheet: View {
    @Binding var isPresented: Bool
    let onLanguageSelected: (String) -> Void
    let hasExistingSubtitles: Bool
    let isFromNewProject: Bool
    
    @State private var selectedLanguage: String = "en"
    @State private var showReplaceWarning: Bool = false
    
    // Common languages for transcription
    private let languages = [
        ("English", "en"),
        ("Spanish", "es"),
        ("French", "fr"),
        ("German", "de"),
        ("Italian", "it"),
        ("Portuguese", "pt"),
        ("Russian", "ru"),
        ("Japanese", "ja"),
        ("Korean", "ko"),
        ("Chinese", "zh"),
        ("Arabic", "ar"),
        ("Hindi", "hi"),
        ("Dutch", "nl"),
        ("Swedish", "sv"),
        ("Norwegian", "no"),
        ("Danish", "da"),
        ("Finnish", "fi"),
        ("Polish", "pl"),
        ("Turkish", "tr")
    ]
    
    var body: some View {
        BottomSheetView(
            isPresented: $isPresented,
            bgOpacity: 0.4,
            allowDismiss: !isFromNewProject
        ) {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Text("Select Language")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                // Description
                Text(isFromNewProject ? 
                     "Choose the primary language spoken in your video for accurate transcription. This is required to continue." :
                     "Choose the primary language spoken in your video for accurate transcription.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                // Language list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(languages, id: \.1) { language in
                            LanguageRow(
                                languageName: language.0,
                                languageCode: language.1,
                                isSelected: selectedLanguage == language.1
                            ) {
                                selectedLanguage = language.1
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)
                
                // Generate button
                Button {
                    if hasExistingSubtitles {
                        showReplaceWarning = true
                    } else {
                        onLanguageSelected(selectedLanguage)
                        isPresented = false
                    }
                } label: {
                    Text("Generate Subtitles")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .disabled(selectedLanguage.isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .confirmationDialog(
            "Replace Existing Subtitles?",
            isPresented: $showReplaceWarning,
            titleVisibility: .visible
        ) {
            Button("Replace", role: .destructive) {
                onLanguageSelected(selectedLanguage)
                isPresented = false
            }
            Button("Cancel", role: .cancel) {
                // Do nothing, just dismiss the dialog
            }
        } message: {
            Text("This will replace all existing subtitles with new ones in \(languages.first(where: { $0.1 == selectedLanguage })?.0 ?? "the selected language"). This action cannot be undone.")
        }
    }
}

struct LanguageRow: View {
    let languageName: String
    let languageCode: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(languageName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(languageCode.uppercased())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        
        Divider()
            .padding(.leading, 16)
    }
}

#Preview {
    LanguagePickerSheet(
        isPresented: .constant(true),
        onLanguageSelected: { language in
            print("Selected language: \(language)")
        },
        hasExistingSubtitles: true,
        isFromNewProject: false
    )
}
