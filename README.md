# VideoEditorSwiftUI

Video editing application with great functionality of tools and the ability to export video in different formats.

## Features

- **Creating a video project and saving its progress**
- **Cropping video**
- **Changing the video duration**
- **Adding filters and effects to videos**
- **Adding text to a video**
- **Recording and editing audio**
- **Adding frames to videos**
- **Saving or share videos in different sizes**

## Includes

- SwiftUI
- iOS 16+
- MVVM
- Combine
- Core Data
- AVFoundation
- AVKit

## Screenshots 📷

### Projects and editor views

  <div align="center">
  <img src="screenshots/mainScreen.png" height="350" alt="Screenshot"/>
  <img src="screenshots/editor_screen.png" height="350" alt="Screenshot"/>
  <img src="screenshots/fullscreen.png" height="350" alt="Screenshot"/>
  <img src="screenshots/export_screen.png" height="350" alt="Screenshot"/>
  </div>
  
### Editor tools

  <div align="center">
  <img src="screenshots/tool_cut.png" height="350" alt="Screenshot"/>
  <img src="screenshots/tool_speed.png" height="350" alt="Screenshot"/>
  <img src="screenshots/tool_audio.png" height="350" alt="Screenshot"/>
  <img src="screenshots/tool_filters.png" height="350" alt="Screenshot"/>
  <img src="screenshots/tool_crop.png" height="350" alt="Screenshot"/>
  <img src="screenshots/tool_frame.png" height="350" alt="Screenshot"/>
  <img src="screenshots/tool_text.png" height="350" alt="Screenshot"/>
  <img src="screenshots/tool_corrections.png" height="350" alt="Screenshot"/>
  </div>


### Text Features

This app always tries to ensure WYSIWYG (what you see is what you get) consistency between the editor, overlay, and exported video. This is important for accurate subtitle and caption editing.

### Implementation Summary
- **Model**: The `TextBox` model now includes shadow properties: `shadowColor`, `shadowRadius`, `shadowX`, `shadowY`, and `shadowOpacity`.
- **UI**: A new bottom sheet ("Shadow") was added to the text editor, allowing users to adjust shadow color, blur, offset, and opacity. Live preview is provided.
- **Editor/Overlay**: Both the text editor and overlay views use SwiftUI's `.shadow` modifier to render the shadow exactly as configured.
- **Export**: The export logic in `VideoEditor.swift` was updated to render the shadow using CoreGraphics, so the burned-in video matches the editor preview.

**Note:** When adding new text features, ensure changes are reflected in:
- The `TextBox` model
- The text editing UI (bottom sheets, controls)
- The overlay and editor rendering (SwiftUI views)
- The export logic (CoreGraphics/AVFoundation)

This guarantees that all text features are WYSIWYG and consistent across the app and exported videos.

## 🎬 Native TikTok-Style Subtitle Burning Implementation

This app implements professional-grade subtitle burning using **native iOS frameworks** (AVFoundation + Core Animation) instead of FFmpeg, following the same approach used by apps like CapCut, InShot, and VLLO.

### 🎯 Core Architecture

The app uses a **two-pass rendering pipeline** in `VideoEditor.swift`:

1. **First Pass**: `resizeAndLayerOperation()` - Handles video resizing, text overlay composition, and basic effects
2. **Second Pass**: `applyFiltersOperations()` - Applies color filters and final processing

### 🚀 Native Text Rendering (No FFmpeg)

The subtitle burning happens in the `createLayers()` method using **Core Animation layers**:

```swift
// Creates a layer tree with video + text overlays
let outputLayer = CALayer()
outputLayer.addSublayer(bgLayer)      // Background
outputLayer.addSublayer(videoLayer)   // Video content
// Add text layers for each subtitle
video.textBoxes.forEach { text in
    let textLayer = createTextLayer(with: text, ...)
    outputLayer.addSublayer(textLayer)
}
```

### ⏰ Frame-Accurate Timing

The app achieves frame-accurate timing through:

1. **CMTime-based synchronization**: Text layers are positioned using `CMTime` for precise timing
2. **CABasicAnimation for timing**: Each text layer gets animations with `beginTime` set to the subtitle's start time
3. **30fps rendering**: `videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)`

### 🎨 Advanced Styling Support

The `TextBox` model supports rich styling that gets rendered natively:

- **Text styling**: Font size, color, stroke, shadow
- **Background styling**: Background color, padding, corner radius
- **Multi-line text**: Automatic line breaks with center alignment
- **Karaoke effects**: Word-by-word highlighting with multi-line support
- **Animations**: Fade in/out with precise timing

#### 📝 Regular Text Multi-Line Implementation

**Player Preview (SwiftUI)**:
- Uses `UIViewRepresentable` with `UILabel` for native text rendering
- `numberOfLines = 0` and `lineBreakMode = .byWordWrapping` for automatic wrapping
- Detects explicit line breaks (`\n`) and applies center alignment automatically

```swift
// AttributedTextOverlay handles regular text
func makeUIView(context: Context) -> UILabel {
    let label = UILabel()
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    
    let hasExplicitLineBreaks = attributedString.string.contains("\n")
    label.textAlignment = hasExplicitLineBreaks ? .center : .natural
    return label
}
```

**Export Pipeline (Core Graphics)**:
- Uses `NSAttributedString` with `NSMutableParagraphStyle` for text formatting
- Applies center alignment and word wrapping for multi-line text
- Uses `draw(in: CGRect)` instead of `draw(at: CGPoint)` to respect paragraph alignment

```swift
// Regular text export with center alignment
let paragraphStyle = NSMutableParagraphStyle()
paragraphStyle.alignment = .center
paragraphStyle.lineBreakMode = .byWordWrapping

let drawingRect = CGRect(x: padding, y: padding, width: width, height: height)
attributedString.draw(in: drawingRect) // Respects paragraph alignment
```

### 🎤 Karaoke Subtitle System

The app has sophisticated karaoke support with three modes:

1. **Letter-by-letter**: `KaraokeType.letter` - Highlights each letter progressively
2. **Word-by-word**: `KaraokeType.word` - Highlights each word
3. **Word background**: `KaraokeType.wordbg` - Adds background highlighting per word

#### 🎯 Multi-Line Karaoke Implementation

**Player Preview (SwiftUI)**:
- Uses custom `KaraokeTextLayout` to handle explicit line breaks (`\n`)
- Implements `KaraokeWrappingLayout` (iOS 16+ Layout protocol) for word positioning
- Center-aligns multi-line karaoke text automatically
- Consistent behavior: only explicit line breaks create new lines (no auto-wrapping)

```swift
// KaraokeTextLayout handles explicit line breaks
struct KaraokeTextLayout<Content: View>: View {
    private func organizeWordsIntoLines() -> [[WordWithTiming]] {
        let textLines = originalText.components(separatedBy: .newlines)
        // Maps words to their corresponding text lines
    }
    
    var body: some View {
        let lines = organizeWordsIntoLines()
        let hasMultipleLines = lines.count > 1
        
        VStack(alignment: hasMultipleLines ? .center : .leading, spacing: lineSpacing) {
            ForEach(0..<lines.count, id: \.self) { lineIndex in
                KaraokeLineLayout(words: lines[lineIndex], ...)
            }
        }
    }
}
```

**Export Pipeline (Core Graphics)**:
- Custom `calculateKaraokeWordPositions()` function for precise word placement
- Handles coordinate system differences (Y-axis inversion) between SwiftUI and Core Graphics
- Frame-accurate timing with `CMTime` synchronization
- Center-aligned multi-line rendering matching preview exactly

```swift
// Creates animated highlight layers for each word with precise positioning
let highlightLayer = CATextLayer()
highlightLayer.foregroundColor = UIColor(model.highlightColor).cgColor
let highlightAnim = CABasicAnimation(keyPath: "opacity")
highlightAnim.beginTime = word.start  // Frame-accurate timing
highlightAnim.duration = word.end - word.start
highlightLayer.frame = CGRect(x: wordPosition.x, y: wordPosition.y, ...)
```

#### 🔄 Text Parsing & Word Timing

**Consistent Word Splitting**: Both preview and export use `text.split { $0.isWhitespace }` to handle all whitespace characters (spaces, tabs, line breaks) uniformly.

**WordWithTiming Structure**:
```swift
struct WordWithTiming {
    let word: String
    let start: Double  // Start time in seconds
    let end: Double    // End time in seconds
}
```

### 🎬 Export Pipeline

The burning process uses **AVVideoCompositionCoreAnimationTool**:

```swift
// For device builds
videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
    postProcessingAsVideoLayer: videoLayer,
    in: outputLayer)

// For simulator (workaround)
videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
    additionalLayer: outputLayer,
    asTrackID: overlayTrackID)
```

### 🔄 WYSIWYG Preview

The preview matches the final output because:

1. **Same render tree**: The same `CALayer` hierarchy used in preview is burned during export
2. **Native rendering**: Uses Core Animation's hardware-accelerated rendering
3. **Real-time sync**: Text timing is synchronized with video playback using the same timing system

#### 🎯 Text Rendering Consistency

**Karaoke Text**: Perfect preview-export consistency achieved through:
- Identical word positioning algorithms in SwiftUI (`KaraokeTextLayout`) and Core Graphics
- Same text parsing logic (`text.split { $0.isWhitespace }`) in both contexts
- Coordinate system normalization (Y-axis inversion handling)
- Frame-accurate word timing preservation

**Regular Text**: WYSIWYG guaranteed by:
- Same `NSAttributedString` rendering in preview (`UILabel`) and export (Core Graphics)
- Identical paragraph styling and alignment detection
- Consistent multi-line behavior using `draw(in: CGRect)` for proper alignment
- Matching font, stroke, shadow, and background rendering

**Key Principle**: Both karaoke and regular text use **explicit line breaks only** - no auto-wrapping differences between preview and export.

### 🚀 Performance Benefits

- **Hardware acceleration**: Core Animation uses Metal for GPU rendering
- **No FFmpeg dependency**: Pure native iOS APIs
- **Battery efficient**: Optimized for mobile devices
- **Real-time preview**: Live editing with immediate visual feedback

### 📱 iOS Compliance

This approach is fully compliant with iOS App Store guidelines because:

- Uses only Apple's native frameworks (AVFoundation, Core Animation)
- No GPL-licensed dependencies like FFmpeg
- Leverages iOS's built-in video processing capabilities
- Hardware-accelerated rendering for smooth performance

This implementation demonstrates exactly how professional video editing apps achieve high-quality subtitle burning with frame-accurate timing and rich styling, all while maintaining iOS compliance and performance standards.

  
  
