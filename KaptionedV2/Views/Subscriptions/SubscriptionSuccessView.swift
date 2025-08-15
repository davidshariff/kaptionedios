import SwiftUI

struct SubscriptionSuccessView: View {
    @Binding var isPresented: Bool
    let subscriptionTier: String
    @State private var confettiAnimating = false
    @State private var pulseAnimation = false
    @State private var rotationAnimation = false
    @State private var sparkleAnimation = false
    @State private var textGradientAnimation = false
    @State private var buttonGradientAnimation = false
    
    var body: some View {
        ZStack {
            // Blurred background overlay
            Color.clear
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissView()
                }
            
            // Confetti background animation
            ForEach(0..<20, id: \.self) { index in
                ConfettiParticle(
                    color: [Color.yellow, Color.orange, Color.pink, Color.purple, Color.blue, Color.green].randomElement() ?? .yellow,
                    isAnimating: confettiAnimating
                )
                .offset(
                    x: CGFloat.random(in: -200...200),
                    y: CGFloat.random(in: -400...400)
                )
            }
            
            // Success card
            VStack(spacing: 24) {
                // Enhanced success animation and icon
                VStack(spacing: 20) {
                    // Multi-layered animated checkmark circle with glow
                    ZStack {
                        // Outer glow ring
                        Circle()
                            .fill(Color.green.opacity(0.3))
                            .frame(width: 120, height: 120)
                            .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                            .opacity(pulseAnimation ? 0.0 : 1.0)
                            .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: pulseAnimation)
                        
                        // Middle ring
                        Circle()
                            .fill(Color.green.opacity(0.6))
                            .frame(width: 100, height: 100)
                            .scaleEffect(isPresented ? 1.0 : 0.3)
                            .animation(.spring(response: 0.8, dampingFraction: 0.5).delay(0.1), value: isPresented)
                        
                        // Main checkmark circle with gradient
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.green, Color.mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .scaleEffect(isPresented ? 1.0 : 0.1)
                            .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2), value: isPresented)
                            .shadow(color: .green.opacity(0.5), radius: 10, x: 0, y: 5)
                        
                        // Checkmark with bounce
                        Image(systemName: "checkmark")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(isPresented ? 1.0 : 0.1)
                            .animation(.spring(response: 0.4, dampingFraction: 0.3).delay(0.4), value: isPresented)
                    }
                    
                    // Enhanced crown with sparkles and rotation
                    ZStack {
                        // Sparkle effects around crown
                        ForEach(0..<8, id: \.self) { index in
                            Image(systemName: "sparkle")
                                .font(.system(size: 12))
                                .foregroundColor(.yellow)
                                .offset(
                                    x: cos(Double(index) * .pi / 4) * 40,
                                    y: sin(Double(index) * .pi / 4) * 40
                                )
                                .scaleEffect(sparkleAnimation ? 1.0 : 0.0)
                                .opacity(sparkleAnimation ? 1.0 : 0.0)
                                .animation(
                                    .easeInOut(duration: 0.8)
                                    .delay(0.6 + Double(index) * 0.1)
                                    .repeatForever(autoreverses: true),
                                    value: sparkleAnimation
                                )
                        }
                        
                        // Crown with gradient and rotation
                        Image(systemName: "crown.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.yellow, Color.orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(isPresented ? 1.0 : 0.2)
                            .rotationEffect(.degrees(rotationAnimation ? 360 : 0))
                            .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.5), value: isPresented)
                            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false), value: rotationAnimation)
                            .shadow(color: .yellow.opacity(0.6), radius: 8, x: 0, y: 4)
                    }
                }
                
                // Success text
                VStack(spacing: 16) {
                    Text("Welcome to \(subscriptionTier)!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue, Color.purple, Color.blue, Color.purple],
                                startPoint: UnitPoint(x: textGradientAnimation ? 0.0 : -1.0, y: 0.5),
                                endPoint: UnitPoint(x: textGradientAnimation ? 1.0 : 0.0, y: 0.5)
                            )
                        )
                        .scaleEffect(isPresented ? 1.0 : 0.5)
                        .opacity(isPresented ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.7), value: isPresented)
                        .onAppear {
                            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                                textGradientAnimation = true
                            }
                        }
                    
                    Text("🎉 Your subscription is now active!")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .scaleEffect(isPresented ? 1.0 : 0.8)
                        .opacity(isPresented ? 1.0 : 0.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.8), value: isPresented)
                    
                    Text("Enjoy creating stunning captions for your videos.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .offset(y: isPresented ? 0 : 20)
                        .opacity(isPresented ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.6).delay(0.9), value: isPresented)
                }
                
                // Enhanced continue button with hover effect
                Button {
                    dismissView()
                } label: {
                    HStack(spacing: 8) {
                        Text("Continue")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        ZStack {
                            // Animated gradient background
                            LinearGradient(
                                colors: [Color.blue, Color.purple, Color.blue, Color.purple],
                                startPoint: UnitPoint(x: buttonGradientAnimation ? 0.0 : -1.0, y: 0.5),
                                endPoint: UnitPoint(x: buttonGradientAnimation ? 1.0 : 0.0, y: 0.5)
                            )
                            
                            // Shimmer effect
                            LinearGradient(
                                colors: [Color.clear, Color.white.opacity(0.3), Color.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .offset(x: pulseAnimation ? 200 : -200)
                            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false), value: pulseAnimation)
                        }
                    )
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .scaleEffect(isPresented ? 1.0 : 0.8)
                .opacity(isPresented ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(1.0), value: isPresented)
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        buttonGradientAnimation = true
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 12)
                    .shadow(color: .black.opacity(0.1), radius: 40, x: 0, y: 20)
            )
            .padding(.horizontal, 30)
            .scaleEffect(isPresented ? 1.0 : 0.8)
            .opacity(isPresented ? 1.0 : 0.0)
            .animation(.spring(response: 0.7, dampingFraction: 0.8), value: isPresented)
        }
        .onAppear {
            // Trigger all animations when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                confettiAnimating = true
                pulseAnimation = true
                rotationAnimation = true
                sparkleAnimation = true
                textGradientAnimation = true
                buttonGradientAnimation = true
            }
        }
    }
    
    private func dismissView() {
        withAnimation(.easeInOut(duration: 0.3)) {
            confettiAnimating = false
            pulseAnimation = false
            rotationAnimation = false
            sparkleAnimation = false
            textGradientAnimation = false
            buttonGradientAnimation = false
            isPresented = false
        }
    }
}



// Confetti particle animation component
struct ConfettiParticle: View {
    let color: Color
    let isAnimating: Bool
    @State private var opacity: Double = 1.0
    @State private var yOffset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 8, height: 8)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(y: yOffset)
            .animation(
                .easeOut(duration: Double.random(in: 2.0...4.0))
                .delay(Double.random(in: 0...1.0)),
                value: isAnimating
            )
            .onAppear {
                if isAnimating {
                    startAnimation()
                }
            }
            .onChange(of: isAnimating) { newValue in
                if newValue {
                    startAnimation()
                } else {
                    resetAnimation()
                }
            }
    }
    
    private func startAnimation() {
        yOffset = CGFloat.random(in: 300...600)
        rotation = Double.random(in: 0...720)
        opacity = 0.0
        scale = CGFloat.random(in: 0.5...1.5)
    }
    
    private func resetAnimation() {
        yOffset = 0
        rotation = 0
        opacity = 1.0
        scale = 1.0
    }
}

// Environment key for isPresented
private struct IsPresentedKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isPresented: Bool {
        get { self[IsPresentedKey.self] }
        set { self[IsPresentedKey.self] = newValue }
    }
}

#Preview {
    SubscriptionSuccessView(
        isPresented: .constant(true),
        subscriptionTier: "Kaptioned Pro"
    )
}
