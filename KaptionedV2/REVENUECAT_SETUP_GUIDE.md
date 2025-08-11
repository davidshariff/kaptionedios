# 🚀 RevenueCat Integration Setup Guide

This guide will walk you through setting up RevenueCat for real subscription payments in your KaptionedV2 app.

## 📋 Prerequisites

- [ ] Active Apple Developer Account
- [ ] RevenueCat account (free to start)
- [ ] Xcode project with In-App Purchase capability enabled

## 🏗️ Step 1: App Store Connect Setup

### 1.1 Create In-App Purchase Products

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app → **Features** → **In-App Purchases**
3. Create these products:

| Product ID | Type | Display Name | Price |
|------------|------|--------------|-------|
| `kaptioned_premium_monthly` | Auto-Renewable Subscription | Premium Monthly | $4.99 |
| `kaptioned_premium_yearly` | Auto-Renewable Subscription | Premium Yearly | $39.99 |
| `kaptioned_unlimited_monthly` | Auto-Renewable Subscription | Unlimited Monthly | $9.99 |
| `kaptioned_unlimited_yearly` | Auto-Renewable Subscription | Unlimited Yearly | $79.99 |

### 1.2 Create Subscription Groups

1. Create a subscription group called "Kaptioned Subscriptions"
2. Add all 4 products to this group
3. Set up subscription levels:
   - **Level 1**: Premium (Monthly & Yearly)
   - **Level 2**: Unlimited (Monthly & Yearly)

### 1.3 Configure Subscription Details

For each subscription:
- Add localizations (English at minimum)
- Set subscription duration
- Configure pricing for all territories
- Add promotional images if desired

## 🔧 Step 2: RevenueCat Dashboard Setup

### 2.1 Create RevenueCat Project

1. Go to [RevenueCat Dashboard](https://app.revenuecat.com)
2. Create a new project: "KaptionedV2"
3. Add iOS app with your bundle identifier

### 2.2 App Store Connect Integration

1. In RevenueCat Dashboard → **Integrations** → **App Store Connect**
2. Upload your App Store Connect API key
3. Select your app and sync products

### 2.3 Create Entitlements

1. Go to **Entitlements** tab
2. Create these entitlements:

| Entitlement ID | Display Name | Description |
|----------------|--------------|-------------|
| `premium_access` | Premium Access | Access to premium features |
| `unlimited_access` | Unlimited Access | Unlimited video creation |

### 2.4 Create Offerings

1. Go to **Offerings** tab
2. Create "Main Offering" with identifier `main_offering`
3. Add packages:
   - **Premium Monthly**: `kaptioned_premium_monthly` → `premium_access`
   - **Premium Yearly**: `kaptioned_premium_yearly` → `premium_access`
   - **Unlimited Monthly**: `kaptioned_unlimited_monthly` → `unlimited_access`
   - **Unlimited Yearly**: `kaptioned_unlimited_yearly` → `unlimited_access`

### 2.5 Get API Keys

1. Go to **API Keys** tab
2. Copy your keys:
   - **Public SDK Key**: Starts with `appl_`
   - Note: Use different keys for debug/release if needed

## 📱 Step 3: Xcode Project Configuration

### 3.1 Add RevenueCat SDK

1. In Xcode: **File** → **Add Package Dependencies**
2. Enter URL: `https://github.com/RevenueCat/purchases-ios`
3. Select latest version and add to your target

### 3.2 Enable In-App Purchase Capability

1. Select your app target
2. Go to **Signing & Capabilities**
3. Click **+ Capability** → **In-App Purchase**

### 3.3 Update API Keys

Edit `KaptionedV2/Utils/Helpers/RevenueCatConfig.swift`:

```swift
struct APIKeys {
    #if DEBUG
    static let debug = "appl_YOUR_ACTUAL_DEBUG_KEY_HERE"
    #else
    static let release = "appl_YOUR_ACTUAL_RELEASE_KEY_HERE"
    #endif
}
```

Replace the placeholder keys with your actual RevenueCat API keys.

## 🧪 Step 4: Testing

### 4.1 Sandbox Testing

1. Create sandbox Apple ID in App Store Connect
2. Sign out of App Store on your test device
3. Build and run the app
4. Try purchasing subscriptions
5. Verify entitlements are granted correctly

### 4.2 Test Scenarios

- [ ] Purchase Premium Monthly
- [ ] Purchase Premium Yearly  
- [ ] Purchase Unlimited Monthly
- [ ] Purchase Unlimited Yearly
- [ ] Restore purchases
- [ ] Test subscription expiry
- [ ] Test upgrade from Premium to Unlimited
- [ ] Test video creation limits

## 🔍 Step 5: Debugging

### 5.1 Enable Detailed Logging

The app already includes comprehensive logging. Look for these log prefixes:
- `[RevenueCatManager]` - RevenueCat operations
- `[SubscriptionManager]` - Local subscription management
- `[SubscriptionUpgradeView]` - UI purchase flows

### 5.2 Common Issues

**Products not loading:**
- Verify product IDs match exactly
- Check App Store Connect product status
- Ensure products are in "Ready to Submit" state

**Purchases failing:**
- Check sandbox Apple ID is signed in
- Verify In-App Purchase capability is enabled
- Check RevenueCat API key is correct

**Entitlements not granted:**
- Verify entitlement IDs match RevenueCat dashboard
- Check offering configuration
- Review product-to-entitlement mappings

## 🚀 Step 6: Production Deployment

### 6.1 App Store Review

1. Submit in-app purchases for review first
2. Wait for approval (usually 24-48 hours)
3. Then submit app update with subscription features

### 6.2 Production Checklist

- [ ] Switch to production RevenueCat API key
- [ ] Test with real Apple ID (but don't publish yet)
- [ ] Verify all purchase flows work
- [ ] Test restore purchases
- [ ] Check subscription management in Settings app
- [ ] Submit app for review

## 📊 Step 7: Analytics & Monitoring

RevenueCat provides built-in analytics for:
- Revenue tracking
- Subscription metrics
- Churn analysis
- Customer lifetime value

Monitor these metrics in the RevenueCat dashboard to optimize your subscription business.

## 🆘 Support

If you encounter issues:

1. **RevenueCat Documentation**: [docs.revenuecat.com](https://docs.revenuecat.com)
2. **RevenueCat Community**: [community.revenuecat.com](https://community.revenuecat.com)
3. **Apple Developer Forums**: For App Store Connect issues
4. **Check app logs**: Look for detailed error messages

## ✅ Migration Benefits

With this RevenueCat integration, you now have:

- ✅ **Real payment processing** instead of simulations
- ✅ **Cross-platform subscription management**
- ✅ **Automatic receipt validation**
- ✅ **Built-in analytics and reporting**
- ✅ **Server-side subscription status**
- ✅ **Easy restore purchases**
- ✅ **Webhook support for backend integration**
- ✅ **A/B testing capabilities**
- ✅ **Promo code support**
- ✅ **Family sharing compatibility**

Your existing subscription logic remains intact while now being powered by a production-ready payment system!
