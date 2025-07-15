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

  
  
