import SwiftUI

struct LanguagePickerSheet: View {
    @Binding var isPresented: Bool
    let onLanguageSelected: (String) -> Void
    let hasExistingSubtitles: Bool
    let isFromNewProject: Bool
    
    @State private var selectedLanguage: String = ConfigurationManager.shared.getDefaultLanguage()
    @State private var showReplaceWarning: Bool = false
    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool
    
    // Languages for transcription - use supported languages from config
    private var languages: [(String, String)] {
        let supportedLanguages = ConfigurationManager.shared.getSupportedLanguages()
        let languageNames: [String: String] = [
            "en": "English",
            "es": "Spanish - Español", 
            "fr": "French - Français",
            "de": "German - Deutsch",
            "it": "Italian - Italiano",
            "pt": "Portuguese - Português",
            "ru": "Russian - Русский",
            "ja": "Japanese - 日本語",
            "ko": "Korean - 한국어",
            "zh": "Chinese - 中文",
            "ar": "Arabic - العربية",
            "hi": "Hindi - हिन्दी",
            "nl": "Dutch - Nederlands",
            "sv": "Swedish - Svenska",
            "no": "Norwegian - Norsk",
            "da": "Danish - Dansk",
            "fi": "Finnish - Suomi",
            "pl": "Polish - Polski",
            "tr": "Turkish - Türkçe"
        ]
        
        let allLanguages: [(String, String)] = supportedLanguages.compactMap { code in
            guard let name = languageNames[code] else { return nil }
            return (name, code)
        }
        
        // Filter languages based on search text
        if searchText.isEmpty {
            return allLanguages
        } else {
            return allLanguages.filter { language in
                language.0.localizedCaseInsensitiveContains(searchText) ||
                language.1.localizedCaseInsensitiveContains(searchText)
            }
        }
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
                
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                    
                    TextField("Search languages...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.body)
                        .focused($isSearchFocused)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 16))
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
                
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
                                // Dismiss keyboard when language is selected
                                isSearchFocused = false
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
