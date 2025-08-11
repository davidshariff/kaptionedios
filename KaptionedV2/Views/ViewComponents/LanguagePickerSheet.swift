import SwiftUI

struct LanguagePickerSheet: View {
    @Binding var isPresented: Bool
    let onLanguageSelected: (String) -> Void
    let hasExistingSubtitles: Bool
    let isFromNewProject: Bool
    
    @State private var selectedLanguage: String = ConfigurationManager.shared.getDefaultLanguage()
    @State private var showReplaceWarning: Bool = false
    
    // Languages for transcription - use supported languages from config
    private var languages: [(String, String)] {
        let supportedLanguages = ConfigurationManager.shared.getSupportedLanguages()
        let languageNames: [String: String] = [
            "en": "English",
            "es": "Spanish", 
            "fr": "French",
            "de": "German",
            "it": "Italian",
            "pt": "Portuguese",
            "ru": "Russian",
            "ja": "Japanese",
            "ko": "Korean",
            "zh": "Chinese",
            "ar": "Arabic",
            "hi": "Hindi",
            "nl": "Dutch",
            "sv": "Swedish",
            "no": "Norwegian",
            "da": "Danish",
            "fi": "Finnish",
            "pl": "Polish",
            "tr": "Turkish"
        ]
        
        return supportedLanguages.compactMap { code in
            guard let name = languageNames[code] else { return nil }
            return (name, code)
        }.sorted { $0.0 < $1.0 } // Sort by language name
    }
    
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
