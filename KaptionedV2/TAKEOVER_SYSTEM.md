# 🚨 Takeover System Documentation

The Kaptioned app includes a powerful full-screen takeover system that allows you to display important messages, force upgrades, announce maintenance, or handle critical situations remotely through configuration.

## 🎯 Overview

The takeover system provides a beautiful, animated full-screen overlay that can be controlled entirely through remote configuration. It supports multiple types of takeovers with customizable styling and behavior.

## 🏗️ Architecture

### Core Components

1. **TakeoverConfig** - Configuration model defining takeover behavior
2. **TakeoverType** - Enum defining different takeover types
3. **TakeoverView** - Beautiful animated UI component
4. **TakeoverManager** - Singleton managing takeover state and logic
5. **ConfigurationManager** - Handles remote configuration loading

### Integration Points

- **App Startup**: Takeovers are checked after configuration loads
- **Configuration Changes**: Takeovers automatically activate when config changes
- **User Actions**: Handles button taps and dismissal logic

## 🎨 Takeover Types

### 1. Upgrade Takeover (`upgrade`)
- **Purpose**: Encourage users to upgrade to premium
- **Default Icon**: `crown.fill`
- **Default Color**: Purple
- **Action**: Opens RevenueCat paywall

### 2. Maintenance Takeover (`maintenance`)
- **Purpose**: Inform users about scheduled maintenance
- **Default Icon**: `wrench.and.screwdriver.fill`
- **Default Color**: Orange
- **Action**: Can open status page URL

### 3. Announcement Takeover (`announcement`)
- **Purpose**: Share new features or important updates
- **Default Icon**: `megaphone.fill`
- **Default Color**: Green
- **Action**: Can open external URL

### 4. Error Takeover (`error`)
- **Purpose**: Handle critical errors or service issues
- **Default Icon**: `exclamationmark.triangle.fill`
- **Default Color**: Red
- **Action**: Retry or acknowledge

### 5. Message Takeover (`message`)
- **Purpose**: General informational messages
- **Default Icon**: `message.circle.fill`
- **Default Color**: Blue
- **Action**: Simple acknowledgment

## ⚙️ Configuration

### Server Configuration JSON

The takeover is controlled through the `/configs` endpoint. Here's the structure:

```json
{
  "success": true,
  "config": {
    "takeover": {
      "isEnabled": true,
      "type": "upgrade",
      "title": "Upgrade to Premium",
      "message": "Unlock unlimited video processing and advanced features.",
      "actionButtonText": "Upgrade Now",
      "cancelButtonText": "Maybe Later",
      "actionURL": null,
      "backgroundColor": "#8B5CF6",
      "textColor": "#FFFFFF",
      "buttonColor": "#7C3AED",
      "icon": "crown.fill",
      "dismissible": true,
      "forceUpgrade": false
    }
  }
}
```

### Configuration Fields

| Field | Type | Description | Default |
|-------|------|-------------|---------|
| `isEnabled` | Boolean | Whether takeover is active | `false` |
| `type` | String | Type of takeover (see types above) | `"message"` |
| `title` | String | Main heading text | `""` |
| `message` | String | Body text content | `""` |
| `actionButtonText` | String | Primary button text | `"OK"` |
| `cancelButtonText` | String | Secondary button text | `"Cancel"` |
| `actionURL` | String? | URL to open on action (optional) | `null` |
| `backgroundColor` | String? | Hex color for background | Type default |
| `textColor` | String? | Hex color for text | `"#FFFFFF"` |
| `buttonColor` | String? | Hex color for buttons | Type default |
| `icon` | String? | SF Symbol name (optional) | Type default |
| `dismissible` | Boolean | Can user dismiss takeover | `true` |
| `forceUpgrade` | Boolean | Prevents dismissal after action | `false` |

## 🎭 Usage Examples

### 1. Force Upgrade
```json
{
  "takeover": {
    "isEnabled": true,
    "type": "upgrade",
    "title": "Update Required",
    "message": "A new version is required to continue.",
    "actionButtonText": "Update Now",
    "cancelButtonText": "Later",
    "actionURL": "https://apps.apple.com/app/kaptioned",
    "backgroundColor": "#DC2626",
    "dismissible": false,
    "forceUpgrade": true
  }
}
```

### 2. Maintenance Notice
```json
{
  "takeover": {
    "isEnabled": true,
    "type": "maintenance",
    "title": "Scheduled Maintenance",
    "message": "We're performing maintenance for 30 minutes.",
    "actionButtonText": "Check Status",
    "cancelButtonText": "OK",
    "actionURL": "https://status.kaptioned.com",
    "backgroundColor": "#F59E0B"
  }
}
```

### 3. Feature Announcement
```json
{
  "takeover": {
    "isEnabled": true,
    "type": "announcement",
    "title": "🎉 New Features!",
    "message": "Try our new karaoke subtitles and advanced styling!",
    "actionButtonText": "Learn More",
    "cancelButtonText": "Dismiss",
    "actionURL": "https://kaptioned.com/whats-new",
    "backgroundColor": "#10B981"
  }
}
```

### 4. Disable Takeover
```json
{
  "takeover": {
    "isEnabled": false
  }
}
```

## 🎨 Customization

### Colors
Use hex color codes (with or without #):
- `"#8B5CF6"` - Purple
- `"#F59E0B"` - Orange  
- `"#10B981"` - Green
- `"#EF4444"` - Red
- `"#3B82F6"` - Blue

### Icons
Use SF Symbol names:
- `"crown.fill"`
- `"wrench.and.screwdriver.fill"`
- `"megaphone.fill"`
- `"exclamationmark.triangle.fill"`
- `"message.circle.fill"`
- `"gift.fill"`

### Behavior Control
- `"dismissible": false` - User cannot dismiss
- `"forceUpgrade": true` - Takeover stays after action
- `"actionURL": "https://..."` - Opens URL on action

## 🔧 Development

### Testing Takeovers

In DEBUG mode, use the "Test Takeover" button in the toolbar to test different takeover types.

### Local Testing

You can test takeovers by modifying the configuration in `TakeoverExamples.swift`:

```swift
// Test a specific takeover
let testConfig = TakeoverExamples.upgradeTakeover
TakeoverManager.shared.currentTakeoverConfig = testConfig
TakeoverManager.shared.isTakeoverActive = true
```

### Adding New Takeover Types

1. Add new case to `TakeoverType` enum
2. Update `displayName`, `defaultIcon`, and `defaultBackgroundColor`
3. Add handling in `TakeoverManager.handleActionButton()`

## 🚀 Deployment

### Production Setup

1. **Server Configuration**: Set up your `/configs` endpoint to return takeover configuration
2. **Testing**: Test with `isEnabled: false` first
3. **Gradual Rollout**: Enable for small user groups initially
4. **Monitoring**: Monitor user engagement and conversion rates

### Best Practices

1. **Clear Messaging**: Use concise, actionable titles and messages
2. **Appropriate Timing**: Don't show takeovers too frequently
3. **User Control**: Allow dismissal unless absolutely necessary
4. **A/B Testing**: Test different messages and colors
5. **Analytics**: Track takeover performance and user actions

## 🔍 Troubleshooting

### Common Issues

1. **Takeover not showing**: Check `isEnabled` and required fields
2. **Wrong colors**: Verify hex color format
3. **Missing icons**: Ensure SF Symbol name is correct
4. **Action not working**: Check URL format and RevenueCat integration

### Debug Information

Enable debug logging to see takeover activity:
```
[TakeoverManager] Activating takeover: upgrade
[TakeoverManager] Action button tapped for takeover: upgrade
[TakeoverManager] Dismissing takeover
```

## 📱 User Experience

The takeover system provides a smooth, professional experience with:

- **Smooth Animations**: Spring-based animations for natural feel
- **Responsive Design**: Adapts to different screen sizes
- **Accessibility**: Proper contrast and readable text
- **Touch Feedback**: Visual feedback on button interactions
- **Dismissal Options**: Tap outside or cancel button when allowed

## 🔄 Integration with Existing Systems

- **RevenueCat**: Upgrade takeovers automatically open paywall
- **ConfigurationManager**: Seamless integration with remote config
- **SubscriptionManager**: Respects existing subscription state
- **App Lifecycle**: Activates on app startup and config changes

This takeover system provides a powerful way to communicate with users and drive important actions while maintaining a beautiful, professional user experience.
