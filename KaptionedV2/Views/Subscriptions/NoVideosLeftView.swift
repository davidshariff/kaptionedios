import SwiftUI

struct NoVideosLeftView: View {
    let subscriptionTier: SubscriptionTier
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
                // Header with warning icon
                VStack(spacing: 16) {
                    // Warning icon
                    ZStack {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 35, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    // Title
                    Text("Video Limit Reached")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    // Subtitle
                    Text("You've used all your videos for this month")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)
                .padding(.horizontal, 24)
                
                // Current plan info
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
                            Text("Videos Used")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(subscriptionTier.maxVideos)/\(subscriptionTier.maxVideos)")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    // Progress bar
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Monthly Usage")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("100%")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        
                        ProgressView(value: 1.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                    }
                    
                    if let expiryDate = expiryDate {
                        Divider()
                        
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                
                                Text("Your plan renews in \(daysUntilRenewal(expiryDate)) days")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.green)
                                
                                Text("You'll get \(subscriptionTier.maxVideos) new videos on \(formatDate(expiryDate))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
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
                
                // What you can do section
                VStack(alignment: .leading, spacing: 16) {
                    Text("What you can do:")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 12) {
                        optionRow(
                            icon: "clock.fill",
                            iconColor: .blue,
                            title: "Wait for renewal",
                            description: "Get \(subscriptionTier.maxVideos) new videos when your plan renews"
                        )
                        
                        optionRow(
                            icon: "pencil.and.outline",
                            iconColor: .purple,
                            title: "Edit existing videos",
                            description: "You can still edit and export your current projects"
                        )
                        
                        optionRow(
                            icon: "square.and.arrow.down",
                            iconColor: .green,
                            title: "Download your videos",
                            description: "Save your completed videos to your device"
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // Action buttons
                VStack(spacing: 12) {
                    // Primary button - Continue with current plan
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Continue with \(subscriptionTier.displayName)")
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
    
    private func optionRow(icon: String, iconColor: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
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
            print("[NoVideosLeftView] Opening iOS native subscription management")
        } else {
            print("[NoVideosLeftView] ⚠️ Failed to create subscription management URL")
        }
    }
}

#Preview {
    NoVideosLeftView(
        subscriptionTier: .pro,
        expiryDate: Calendar.current.date(byAdding: .day, value: 12, to: Date()),
        isPresented: .constant(true)
    )
}
