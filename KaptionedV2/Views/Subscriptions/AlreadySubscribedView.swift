import SwiftUI

struct AlreadySubscribedView: View {
    let subscriptionTier: SubscriptionTier
    let videosRemaining: Int
    let expiryDate: Date?
    @Binding var isPresented: Bool
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        ZStack {
            // Blurred background overlay
            Color.clear
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Main card
            VStack(spacing: 0) {
                // Header with checkmark
                VStack(spacing: 16) {
                    // Success checkmark
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    // Title
                    Text("Already Subscribed!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    // Subscription info
                    VStack(spacing: 8) {
                        Text("You're currently on the \(subscriptionTier.displayName) plan")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        if videosRemaining == Int.max {
                            Text("Unlimited videos remaining")
                                .font(.headline)
                                .foregroundColor(.green)
                        } else {
                            Text("\(videosRemaining) video\(videosRemaining == 1 ? "" : "s") remaining")
                                .font(.headline)
                                .foregroundColor(videosRemaining > 0 ? .green : .orange)
                        }
                    }
                }
                .padding(.top, 32)
                .padding(.horizontal, 24)
                
                // Subscription details card
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Plan")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(subscriptionTier.displayName)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Videos Left")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if videosRemaining == Int.max {
                                Text("∞")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            } else {
                                Text("\(videosRemaining)")
                                    .font(.headline)
                                    .foregroundColor(videosRemaining > 0 ? .green : .orange)
                            }
                        }
                    }
                    
                    if let expiryDate = expiryDate {
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Renews")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(formatDate(expiryDate))
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Days Left")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("\(daysUntilRenewal(expiryDate))")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // Benefits section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your \(subscriptionTier.displayName) Benefits")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 8) {
                        benefitRow(
                            icon: "video.fill",
                            text: videosRemaining == Int.max ? "Unlimited videos" : "\(subscriptionTier.maxVideos) videos per month",
                            isActive: true
                        )
                        
                        benefitRow(
                            icon: "wand.and.stars",
                            text: "Advanced editing tools",
                            isActive: true
                        )
                        
                        benefitRow(
                            icon: "textformat.size",
                            text: "Custom text styles",
                            isActive: true
                        )
                        
                        if subscriptionTier == .unlimited {
                            benefitRow(
                                icon: "infinity",
                                text: "No monthly limits",
                                isActive: true
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // Action buttons
                VStack(spacing: 12) {
                    // Primary button - Continue
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.blue)
                            )
                    }
                    
                    // Secondary button - Manage subscription
                    Button(action: {
                        openNativeSubscriptionManagement()
                    }) {
                        Text("Manage Subscription")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 32)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
            )
            .padding(.horizontal, 20)
        }
    }
    
    private func benefitRow(icon: String, text: String, isActive: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isActive ? .green : .gray)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
                .foregroundColor(isActive ? .primary : .secondary)
            
            Spacer()
            
            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.green)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func daysUntilRenewal(_ date: Date) -> Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: date).day ?? 0
        return max(0, days)
    }
    
    private func openNativeSubscriptionManagement() {
        // Close the current view first
        isPresented = false
        
        // Open iOS native subscription management
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            openURL(url)
            print("[AlreadySubscribedView] Opening iOS native subscription management")
        } else {
            print("[AlreadySubscribedView] ⚠️ Failed to create subscription management URL")
        }
    }
}

#Preview {
    AlreadySubscribedView(
        subscriptionTier: .pro,
        videosRemaining: 2,
        expiryDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()),
        isPresented: .constant(true)
    )
}
