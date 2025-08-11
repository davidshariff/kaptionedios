import SwiftUI

/// A view that displays the current configuration status
struct ConfigurationStatusView: View {
    @ObservedObject var configManager = ConfigurationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Configuration Status")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if configManager.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: configManager.errorMessage == nil ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(configManager.errorMessage == nil ? .green : .orange)
                }
            }
            
            if let lastUpdate = configManager.lastUpdateTime {
                Text("Last updated: \(lastUpdate, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let error = configManager.errorMessage {
                Text("Error: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(4)
            }
            
            // Display current configuration summary
            VStack(alignment: .leading, spacing: 4) {
                Text("API Base URL: \(configManager.currentConfig.api.baseURL)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Default Language: \(configManager.currentConfig.transcription.defaultLanguage)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Max Words Per Line: \(configManager.currentConfig.transcription.maxWordsPerLine)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Karaoke Enabled: \(configManager.currentConfig.features.enableKaraoke ? "Yes" : "No")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

#Preview {
    ConfigurationStatusView()
        .padding()
}
