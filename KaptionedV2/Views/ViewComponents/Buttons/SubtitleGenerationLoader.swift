import SwiftUI

// MARK: - Animated Dot Component
struct AnimatedDot: View {
    let delay: Double
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.4
    
    var body: some View {
        Circle()
            .fill(Color.white.opacity(opacity))
            .frame(width: 8, height: 8)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    scale = 1.4
                    opacity = 0.9
                }
            }
    }
}

// MARK: - Subtitle Generation Loader
struct SubtitleGenerationLoader: View {
    @State private var animationPhase: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            // Backdrop blur
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .background(.ultraThinMaterial)
            
            VStack(spacing: 24) {
                // Animated subtitle generation icon
                ZStack {
                    // Outer pulsing ring
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulseScale)
                        .opacity(2.0 - pulseScale)
                    
                    // Inner rotating ring
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(rotationAngle))
                    
                    // Center icon
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .scaleEffect(1.0 + sin(animationPhase) * 0.1)
                }
                
                VStack(spacing: 12) {
                    // Main title with gradient
                    Text("Generating Subtitles")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    // Animated dots
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { index in
                            AnimatedDot(delay: Double(index) * 0.3)
                        }
                    }
                    
                    // Subtitle text
                    Text("Processing video and creating captions...")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.3))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .scaleEffect(1.0 + sin(animationPhase * 0.5) * 0.02) // Subtle breathing effect
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Start all animations
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.3
            }
            
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                animationPhase = .pi * 2
            }
        }
    }
}

// MARK: - Preview
struct SubtitleGenerationLoader_Previews: PreviewProvider {
    static var previews: some View {
        SubtitleGenerationLoader()
            .preferredColorScheme(.dark)
    }
}
