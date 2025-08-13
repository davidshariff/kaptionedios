import SwiftUI

struct TakeoverView: View {
    let config: TakeoverConfig
    let onAction: () -> Void
    let onCancel: () -> Void
    
    @State private var isVisible = false
    @State private var backgroundOpacity = 0.0
    @State private var cardScale = 0.8
    @State private var cardOpacity = 0.0
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black
                .opacity(backgroundOpacity)
                .ignoresSafeArea()
                .onTapGesture {
                    if config.dismissible {
                        dismiss()
                    }
                }
            
            // Main content card
            VStack(spacing: 0) {
                // Header with icon
                VStack(spacing: 20) {
                    // Icon
                    Image(systemName: config.icon ?? config.type.defaultIcon)
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(iconColor)
                        .scaleEffect(isVisible ? 1.0 : 0.5)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: isVisible)
                    
                    // Title
                    Text(config.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(textColor)
                        .multilineTextAlignment(.center)
                        .opacity(isVisible ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.5).delay(0.2), value: isVisible)
                    
                    // Message
                    Text(config.message)
                        .font(.body)
                        .foregroundColor(textColor.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .opacity(isVisible ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.5).delay(0.3), value: isVisible)
                }
                .padding(.horizontal, 32)
                .padding(.top, 40)
                .padding(.bottom, 40)
                
                // Buttons
                VStack(spacing: 16) {
                    // Action button
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            onAction()
                        }
                    }) {
                        Text(config.actionButtonText)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(buttonColor)
                                    .shadow(color: buttonColor.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                    }
                    .scaleEffect(isVisible ? 1.0 : 0.9)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4), value: isVisible)
                    
                    // Cancel button (only if dismissible)
                    if config.dismissible {
                        Button(action: {
                            dismiss()
                        }) {
                            Text(config.cancelButtonText)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(textColor.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(textColor.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .scaleEffect(isVisible ? 1.0 : 0.9)
                        .opacity(isVisible ? 1.0 : 0.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5), value: isVisible)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(backgroundColor)
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
            .padding(.horizontal, 24)
        }
        .onAppear {
            show()
        }
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        if let colorString = config.backgroundColor {
            return Color(colorString) ?? defaultBackgroundColor
        }
        return defaultBackgroundColor
    }
    
    private var textColor: Color {
        if let colorString = config.textColor {
            return Color(colorString) ?? .white
        }
        return .white
    }
    
    private var buttonColor: Color {
        if let colorString = config.buttonColor {
            return Color(colorString) ?? defaultButtonColor
        }
        return defaultButtonColor
    }
    
    private var iconColor: Color {
        return textColor
    }
    
    private var defaultBackgroundColor: Color {
        switch config.type {
        case .message: return Color.blue
        case .upgrade: return Color.purple
        case .maintenance: return Color.orange
        case .announcement: return Color.green
        case .error: return Color.red
        }
    }
    
    private var defaultButtonColor: Color {
        switch config.type {
        case .message: return Color.blue
        case .upgrade: return Color.purple
        case .maintenance: return Color.orange
        case .announcement: return Color.green
        case .error: return Color.red
        }
    }
    
    // MARK: - Animations
    
    private func show() {
        withAnimation(.easeOut(duration: 0.3)) {
            backgroundOpacity = 0.8
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
            cardScale = 1.0
            cardOpacity = 1.0
        }
        
        withAnimation(.easeInOut(duration: 0.3).delay(0.2)) {
            isVisible = true
        }
    }
    
    private func dismiss() {
        withAnimation(.easeIn(duration: 0.2)) {
            backgroundOpacity = 0.0
            cardScale = 0.8
            cardOpacity = 0.0
            isVisible = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onCancel()
        }
    }
}

// MARK: - Color Extension

extension Color {
    init?(_ hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview {
    TakeoverView(
        config: TakeoverConfig(
            isEnabled: true,
            type: .upgrade,
            title: "Upgrade Required",
            message: "This feature requires a premium subscription. Upgrade now to unlock unlimited video processing and advanced features.",
            actionButtonText: "Upgrade Now",
            cancelButtonText: "Maybe Later",
            actionURL: nil,
            backgroundColor: nil,
            textColor: nil,
            buttonColor: nil,
            icon: nil,
            dismissible: true,
            forceUpgrade: false
        ),
        onAction: {
            print("Action tapped")
        },
        onCancel: {
            print("Cancel tapped")
        }
    )
}
