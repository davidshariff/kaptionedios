import SwiftUI

/// View shown when user needs to upgrade their subscription
struct SubscriptionUpgradeView: View {
    @Binding var isPresented: Bool
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    @State private var selectedTier: SubscriptionTier?
    @State private var showSuccessScreen: Bool = false
    @State private var upgradedTier: SubscriptionTier?
    
    // Check if the selected tier is a valid upgrade
    private var isValidUpgradeSelected: Bool {
        guard let selectedTier = selectedTier else { return false }
        let currentTier = subscriptionManager.currentStatus.tier
        
        // Valid if it's not the current tier and not a downgrade
        return selectedTier != currentTier && !isDowngrade(from: currentTier, to: selectedTier)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.yellow)
                
                Text("Upgrade Your Plan")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(subscriptionManager.getSubscriptionMessage())
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Current status
            VStack(spacing: 8) {
                Text("Current Plan: \(subscriptionManager.currentStatus.tier.displayName)")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Subscription tiers
            VStack(spacing: 16) {
                ForEach(SubscriptionTier.allCases, id: \.self) { tier in
                    let currentTier = subscriptionManager.currentStatus.tier
                    let isCurrentTier = currentTier == tier
                    let isDowngrade = isDowngrade(from: currentTier, to: tier)
                    let isDisabled = isCurrentTier || isDowngrade
                    
                    SubscriptionTierCard(
                        tier: tier,
                        isCurrentTier: isCurrentTier,
                        isSelected: selectedTier == tier,
                        isDisabled: isDisabled,
                        disabledReason: getDisabledReason(for: tier, currentTier: currentTier)
                    ) {
                        // Only allow selection if not disabled
                        if !isDisabled {
                            selectedTier = tier
                            handleTierSelection(tier)
                        }
                    }
                }
            }
            
            // Action buttons
            VStack(spacing: 12) {
                Button {
                    // Placeholder for payment integration
                    if let selectedTier = selectedTier {
                        showPaymentPlaceholder(for: selectedTier)
                    } else {
                        // Show alert to select a tier first
                        showSelectTierAlert()
                    }
                } label: {
                    Text("Upgrade Now")
                        .foregroundColor(.white)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValidUpgradeSelected ? Color.blue : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!isValidUpgradeSelected)
                
                Button {
                    isPresented = false
                } label: {
                    Text("Maybe Later")
                        .foregroundColor(.secondary)
                        .font(.body)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
        .onAppear {
            // Set current tier as selected when view appears
            selectedTier = subscriptionManager.currentStatus.tier
            
            // Debug logging for subscription details
            logSubscriptionDetails()
        }
        .overlay {
            if showSuccessScreen {
                SuccessOverlayView(
                    tier: upgradedTier ?? .free,
                    onContinue: {
                        isPresented = false
                    }
                )
                .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showSuccessScreen)
    }
    
    private func handleTierSelection(_ tier: SubscriptionTier) {
        // This will be replaced with actual payment logic
        print("Selected tier: \(tier.displayName)")
    }
    
    private func showSelectTierAlert() {
        let alert = UIAlertController(
            title: "Select a Plan",
            message: "Please select a subscription tier before upgrading.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        // Present the alert using a more reliable method
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                
                // Find the topmost presented view controller
                var topController = rootViewController
                while let presentedController = topController.presentedViewController {
                    topController = presentedController
                }
                
                topController.present(alert, animated: true)
            }
        }
    }
    
    private func logSubscriptionDetails() {
        let status = subscriptionManager.currentStatus
        print("🔍 [SubscriptionUpgradeView] === SUBSCRIPTION DEBUG INFO ===")
        print("🔍 [SubscriptionUpgradeView] Current Tier: \(status.tier.displayName)")
        print("🔍 [SubscriptionUpgradeView] Videos Created: \(status.videosCreated)")
        print("🔍 [SubscriptionUpgradeView] Max Videos Allowed: \(status.tier.maxVideos)")
        print("🔍 [SubscriptionUpgradeView] Can Create New Video: \(status.canCreateNewVideo)")
        print("🔍 [SubscriptionUpgradeView] Is Active: \(status.isActive)")
        if let expiryDate = status.subscriptionExpiryDate {
            print("🔍 [SubscriptionUpgradeView] Expiry Date: \(expiryDate)")
        } else {
            print("🔍 [SubscriptionUpgradeView] Expiry Date: None (Free tier)")
        }
        print("🔍 [SubscriptionUpgradeView] Remaining Videos: \(status.remainingVideos)")
        print("🔍 [SubscriptionUpgradeView] =================================")
    }
    
    private func isDowngrade(from currentTier: SubscriptionTier, to newTier: SubscriptionTier) -> Bool {
        // Define tier hierarchy (higher index = higher tier)
        let tierHierarchy: [SubscriptionTier] = [.free, .premium, .unlimited]
        
        guard let currentIndex = tierHierarchy.firstIndex(of: currentTier),
              let newIndex = tierHierarchy.firstIndex(of: newTier) else {
            return false
        }
        
        return newIndex < currentIndex
    }
    
    private func getDisabledReason(for tier: SubscriptionTier, currentTier: SubscriptionTier) -> String? {
        if tier == currentTier {
            return "Current Plan"
        }
        
        // Don't show reason for downgrades, just disable them silently
        return nil
    }
    
    private func showPaymentPlaceholder(for tier: SubscriptionTier) {
        // Placeholder alert for payment integration
        let alert = UIAlertController(
            title: "Upgrade to \(tier.displayName)",
            message: "This is where payment processing would be integrated. For now, we'll simulate an upgrade to \(tier.displayName).",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Simulate Upgrade", style: .default) { _ in
            print("🎯 [SubscriptionUpgradeView] Simulating upgrade to \(tier.displayName)")
            subscriptionManager.upgradeToTier(tier)
            upgradedTier = tier
            showSuccessScreen = true
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Present the alert using a more reliable method
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                
                // Find the topmost presented view controller
                var topController = rootViewController
                while let presentedController = topController.presentedViewController {
                    topController = presentedController
                }
                
                topController.present(alert, animated: true)
            }
        }
    }
}

/// Individual subscription tier card
struct SubscriptionTierCard: View {
    let tier: SubscriptionTier
    let isCurrentTier: Bool
    let isSelected: Bool
    let isDisabled: Bool
    let disabledReason: String?
    let onTap: () -> Void
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.blue.opacity(0.1)
        } else if isDisabled {
            return Color(.systemGray5)
        } else {
            return Color(.systemGray6)
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return Color.blue
        } else if isDisabled {
            return Color.gray
        } else {
            return Color.clear
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(tier.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        if isCurrentTier {
                            Text("CURRENT")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(4)
                        } else if isDisabled, let reason = disabledReason {
                            Text(reason)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.gray)
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                    
                    Text("\(tier.maxVideos == Int.max ? "Unlimited" : "\(tier.maxVideos)") videos")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if tier == .free {
                    Text("FREE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                } else {
                    Text("$\(getPrice(for: tier))/month")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: 2)
                    )
            )
            .opacity(isDisabled && !isSelected ? 0.6 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getPrice(for tier: SubscriptionTier) -> String {
        switch tier {
        case .free:
            return "0"
        case .premium:
            return "9.99"
        case .unlimited:
            return "19.99"
        }
    }
}

/// Beautiful success overlay shown after successful upgrade
struct SuccessOverlayView: View {
    let tier: SubscriptionTier
    let onContinue: () -> Void
    @State private var showCheckmark: Bool = false
    @State private var showConfetti: Bool = false
    
    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { } // Prevent background taps
            
            // Success card
            VStack(spacing: 24) {
                // Animated checkmark
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 80, height: 80)
                        .scaleEffect(showCheckmark ? 1.0 : 0.5)
                        .opacity(showCheckmark ? 1.0 : 0.0)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(showCheckmark ? 1.0 : 0.0)
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2), value: showCheckmark)
                
                // Success message
                VStack(spacing: 12) {
                    Text("🎉 Upgrade Successful!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Welcome to \(tier.displayName)!")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    Text("You now have access to \(tier.maxVideos == Int.max ? "unlimited" : "\(tier.maxVideos)") videos per month.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Benefits list
                VStack(spacing: 8) {
                    BenefitRow(icon: "infinity", text: "Unlimited subtitle generation")
                    BenefitRow(icon: "sparkles", text: "Advanced styling options")
                    BenefitRow(icon: "crown.fill", text: "Priority support")
                }
                .padding(.vertical, 8)
                
                // Continue button
                Button {
                    onContinue()
                } label: {
                    Text("Start Creating!")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 40)
            .scaleEffect(showCheckmark ? 1.0 : 0.8)
            .opacity(showCheckmark ? 1.0 : 0.0)
            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1), value: showCheckmark)
        }
        .onAppear {
            showCheckmark = true
            showConfetti = true
        }
    }
}

/// Individual benefit row in the success screen
struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.green)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

#Preview {
    SubscriptionUpgradeView(isPresented: .constant(true))
        .padding()
}
