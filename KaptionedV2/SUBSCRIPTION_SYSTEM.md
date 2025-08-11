# Subscription System

This document explains how the subscription system works in KaptionedV2.

## 🎯 **Overview**

The subscription system enforces video creation limits based on subscription tiers:

- **Free Tier**: 1 video only
- **Premium Tier**: 10 videos
- **Unlimited Tier**: Unlimited videos

## 🔐 **Security Features**

### **Encrypted Storage**
- Subscription data is encrypted using AES-GCM with a device-specific key
- Device key is generated from: UUID + Bundle ID + Device Vendor ID
- Data cannot be bypassed by clearing app cache or reinstalling

### **Device Binding**
- Each device gets a unique identifier that's used for encryption
- Subscription data is tied to the specific device
- Prevents simple workarounds like app reinstallation

## 🏗️ **Architecture**

### **Core Components**

1. **SubscriptionModel.swift** - Defines subscription tiers and status
2. **SubscriptionManager.swift** - Manages subscription logic and encrypted storage
3. **RevenueCat Integration** - Professional paywall and subscription management
4. **Integration Points** - EditorViewModel, RootView, MainEditorView

### **Data Flow**

```
User tries to create video → EditorViewModel.setNewVideo() → 
SubscriptionManager.canCreateNewVideo() → 
If false: Show RevenueCat paywall
If true: SubscriptionManager.recordVideoCreation() → Continue
```

## 🧪 **Testing**

### **Development Testing**

1. **Reset Subscription** (Debug builds only):
   - Use the "Test Subscription Reset" button in the empty state
   - This resets to free tier with 0 videos created

2. **Simulate Upgrades**:
   - When the upgrade view appears, tap "Upgrade Now"
   - Choose "Simulate Premium Upgrade" or "Simulate Unlimited Upgrade"

3. **Test Limits**:
   - Create 1 video (should work)
   - Try to create a 2nd video (should show upgrade prompt)
   - Upgrade to premium (should allow 10 videos)
   - Upgrade to unlimited (should allow unlimited videos)

### **Testing Scenarios**

```swift
// Test free tier limit
1. Reset subscription (free tier, 0 videos)
2. Create 1 video (should work)
3. Try to create 2nd video (should show upgrade prompt)

// Test premium tier
1. Upgrade to premium (10 videos)
2. Create videos until limit reached
3. Verify upgrade prompt appears

// Test unlimited tier
1. Upgrade to unlimited
2. Create unlimited videos (should always work)
```

## 🔧 **Configuration**

### **Subscription Tiers**

```swift
enum SubscriptionTier {
    case free      // 1 video
    case premium   // 10 videos  
    case unlimited // unlimited videos
}
```

### **Customizing Limits**

To change video limits, modify the `maxVideos` property in `SubscriptionTier`:

```swift
var maxVideos: Int {
    switch self {
    case .free:
        return 1      // Change this number
    case .premium:
        return 10     // Change this number
    case .unlimited:
        return Int.max
    }
}
```

## 🚀 **Payment Integration**

### **Current State**
- Placeholder implementation with simulated upgrades
- Uses UIAlertController for testing

### **Future Integration**
The app now uses RevenueCat for real payments. Configure your products in the RevenueCat dashboard and they'll automatically appear in the paywall.

1. **StoreKit Integration** for in-app purchases
2. **RevenueCat** for subscription management
3. **Custom payment processor** (Stripe, etc.)

### **Example StoreKit Integration**

```swift
private func handlePurchase(_ product: SKProduct) {
    let payment = SKPayment(product: product)
    SKPaymentQueue.default().add(payment)
}

// In payment queue delegate:
func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKTransaction]) {
    for transaction in transactions {
        switch transaction.transactionState {
        case .purchased:
            // Upgrade subscription based on product ID
            upgradeSubscription(for: transaction.payment.productIdentifier)
            queue.finishTransaction(transaction)
        case .failed:
            queue.finishTransaction(transaction)
        default:
            break
        }
    }
}
```

## 📱 **User Experience**

### **Subscription Status Display**
- Shows current tier in navigation bar (crown icon + tier name)
- Tap to see detailed subscription message
- Clear messaging about limits and upgrades

### **Upgrade Flow**
1. User tries to exceed limit
2. Subscription upgrade view appears
3. User can choose tier and upgrade
4. Seamless continuation after upgrade

### **Error Handling**
- Graceful fallback if encryption fails
- Clear error messages
- No app crashes on subscription issues

## 🔒 **Security Considerations**

### **Encryption**
- Uses AES-GCM for authenticated encryption
- Device-specific keys prevent cross-device sharing
- Keys are derived from device identifiers

### **Tamper Resistance**
- Encrypted storage prevents simple modification
- Device binding prevents easy workarounds
- Requires significant effort to bypass

### **Limitations**
- Not 100% unbreakable (no DRM is)
- Advanced users could potentially reverse engineer
- Focus on making it harder than it's worth

## 📊 **Analytics & Monitoring**

### **Key Metrics to Track**
- Subscription conversion rates
- Video creation patterns
- Upgrade funnel completion
- Revenue per user

### **Implementation**
```swift
// Add analytics calls in SubscriptionManager
func recordVideoCreation() {
    // Existing logic...
    
    // Analytics
    Analytics.track("video_created", properties: [
        "tier": currentStatus.tier.rawValue,
        "videos_created": currentStatus.videosCreated
    ])
}

func upgradeToTier(_ tier: SubscriptionTier) {
    // Existing logic...
    
    // Analytics
    Analytics.track("subscription_upgraded", properties: [
        "from_tier": currentStatus.tier.rawValue,
        "to_tier": tier.rawValue
    ])
}
```

## 🎯 **Next Steps**

1. **Payment Integration**: Implement StoreKit or RevenueCat
2. **Server Validation**: Add server-side subscription verification
3. **Analytics**: Add subscription event tracking
4. **A/B Testing**: Test different pricing and limits
5. **User Feedback**: Collect feedback on subscription experience
