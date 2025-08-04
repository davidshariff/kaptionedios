import SwiftUI

// MARK: - Shared Color Palette
struct ColorPalette {
    // Dynamically generate a palette with a wide range of colors, ensuring no duplicate white or black entries
    static let baseColors: [Color] = [
        .clear
    ]
    
    static let vibrantColors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .pink, .brown
    ]
    
    // Reduce the number of grayscale steps to avoid too many dark/grey/white shades
    static let grayscaleSteps: Int = 3
    static var grayscale: [Color] {
        // Only include black, a mid-gray, and white
        (0..<grayscaleSteps).map { i in
            let value = Double(i) / Double(grayscaleSteps - 1)
            return Color(white: value)
        }
    }
    
    static let colors: [Color] = {
        // Combine all, but ensure only one .white and one .black
        var all = baseColors + grayscale + vibrantColors
        // Remove duplicate .white and .black by keeping only the first occurrence
        var seenWhite = false
        var seenBlack = false
        all = all.filter { color in
            if color == .white {
                if seenWhite { return false }
                seenWhite = true
            }
            if color == .black {
                if seenBlack { return false }
                seenBlack = true
            }
            return true
        }
        return all
    }()
}

// MARK: - Reusable Color Row (Horizontal Scrollable)
struct ColorRowView: View {
    let colors: [Color]
    let selectedColor: Color
    let onColorSelected: (Color) -> Void
    
    var body: some View {
        ZStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(colors, id: \.self) { color in
                        Button {
                            onColorSelected(color)
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(color == .clear ? Color.gray.opacity(0.2) : color)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle().stroke(Color.white, lineWidth: selectedColor == color ? 3 : 1)
                                    )
                                if color == .clear {
                                    Image(systemName: "slash.circle")
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .frame(height: 76) // Fixed height for the horizontal row
            
            // Gradient blur indicator on the right side
            HStack {
                Spacer()
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.0),
                        Color.black.opacity(0.3),
                        Color.black.opacity(0.6)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 40)
                .allowsHitTesting(false)
            }
        }
    }
}

struct StyleEditorView: View {
    @ObservedObject var textEditor: TextEditorViewModel
    @Binding var selectedStyleOption: String?
    @State private var showColorPicker = false
    
    var body: some View {
        if let selectedStyleOption = selectedStyleOption {
            switch selectedStyleOption {
            case "Background":
                BackgroundColorPickerView(
                    selectedColor: $textEditor.currentTextBox.bgColor,
                    textEditor: textEditor,
                    onDismiss: {
                        self.selectedStyleOption = nil
                    }
                )
                .onAppear {
                    // Ensure currentTextBox is synchronized with selectedTextBox when entering style mode
                    if let selectedTextBox = textEditor.selectedTextBox {
                        textEditor.currentTextBox = selectedTextBox
                    }
                }
            case "Text\nColor":
                TextColorPickerView(
                    selectedColor: $textEditor.currentTextBox.fontColor,
                    textEditor: textEditor,
                    onDismiss: {
                        self.selectedStyleOption = nil
                    }
                )
                .onAppear {
                    // Ensure currentTextBox is synchronized with selectedTextBox when entering style mode
                    if let selectedTextBox = textEditor.selectedTextBox {
                        textEditor.currentTextBox = selectedTextBox
                    }
                }
            case "Stroke":
                StrokeColorPickerView(
                    selectedColor: $textEditor.currentTextBox.strokeColor,
                    strokeWidth: $textEditor.currentTextBox.strokeWidth,
                    textEditor: textEditor,
                    onDismiss: {
                        self.selectedStyleOption = nil
                    }
                )
                .onAppear {
                    // Ensure currentTextBox is synchronized with selectedTextBox when entering style mode
                    if let selectedTextBox = textEditor.selectedTextBox {
                        textEditor.currentTextBox = selectedTextBox
                    }
                }
            case "Font\nSize":
                FontSizePickerView(
                    fontSize: $textEditor.currentTextBox.fontSize,
                    textEditor: textEditor,
                    onDismiss: {
                        self.selectedStyleOption = nil
                    }
                )
                .onAppear {
                    // Ensure currentTextBox is synchronized with selectedTextBox when entering style mode
                    if let selectedTextBox = textEditor.selectedTextBox {
                        textEditor.currentTextBox = selectedTextBox
                    }
                }
            case "Shadow":
                ShadowPickerView(
                    shadowColor: $textEditor.currentTextBox.shadowColor,
                    shadowRadius: $textEditor.currentTextBox.shadowRadius,
                    shadowX: $textEditor.currentTextBox.shadowX,
                    shadowY: $textEditor.currentTextBox.shadowY,
                    shadowOpacity: $textEditor.currentTextBox.shadowOpacity,
                    textEditor: textEditor,
                    onDismiss: {
                        self.selectedStyleOption = nil
                    }
                )
                .onAppear {
                    // Ensure currentTextBox is synchronized with selectedTextBox when entering style mode
                    if let selectedTextBox = textEditor.selectedTextBox {
                        textEditor.currentTextBox = selectedTextBox
                    }
                }
            default:
                EmptyView()
            }
        } else {
            EmptyView()
        }
    }
}

struct BackgroundColorPickerView: View {
    @Binding var selectedColor: Color
    @ObservedObject var textEditor: TextEditorViewModel
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header (fixed at top)
            HStack {
                Text("Text Background Color")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.gray.opacity(0.3), in: Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
            
            // Scrollable content with blur indicator
            ZStack {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 20) {
                        // Color row
                        ColorRowView(
                            colors: ColorPalette.colors,
                            selectedColor: selectedColor,
                            onColorSelected: { color in
                                selectedColor = color
                                // Update the text box in the main model
                                textEditor.updateSelectedTextBox()
                            }
                        )
                        
                        // Background padding and corner radius sliders
                        VStack(spacing: 16) {
                            // Background Padding Slider
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Background Padding")
                                        .font(.subheadline)
                                        .foregroundColor(selectedColor == .clear ? .gray : .white)
                                    Spacer()
                                    Text("\(Int(textEditor.currentTextBox.backgroundPadding))")
                                        .font(.subheadline)
                                        .foregroundColor(selectedColor == .clear ? .gray.opacity(0.7) : .white.opacity(0.7))
                                }
                                
                                Slider(
                                    value: Binding(
                                        get: { textEditor.currentTextBox.backgroundPadding },
                                        set: { newValue in
                                            textEditor.currentTextBox.backgroundPadding = newValue
                                            textEditor.updateSelectedTextBox()
                                        }
                                    ),
                                    in: 0...40,
                                    step: 1
                                )
                                .accentColor(.white)
                                .disabled(selectedColor == .clear)
                            }
                            
                            // Corner Radius Slider
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Corner Radius")
                                        .font(.subheadline)
                                        .foregroundColor(selectedColor == .clear ? .gray : .white)
                                Spacer()
                                    Text("\(Int(textEditor.currentTextBox.cornerRadius))")
                                        .font(.subheadline)
                                        .foregroundColor(selectedColor == .clear ? .gray.opacity(0.7) : .white.opacity(0.7))
                                }
                                
                                Slider(
                                    value: Binding(
                                        get: { textEditor.currentTextBox.cornerRadius },
                                        set: { newValue in
                                            textEditor.currentTextBox.cornerRadius = newValue
                                            textEditor.updateSelectedTextBox()
                                        }
                                    ),
                                    in: 0...20,
                                    step: 1
                                )
                                .accentColor(.white)
                                .disabled(selectedColor == .clear)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40) // Extra padding for blur indicator
                    }
                }
                
                // Blur gradient indicator at bottom
                VStack {
                    Spacer()
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.0),
                            Color.black.opacity(0.3),
                            Color.black.opacity(0.6)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 30)
                    .allowsHitTesting(false)
                }
            }
        }
        .background(Color.black.opacity(0.9))
        .cornerRadius(16)
    }
}

struct FontSizePickerView: View {
    @Binding var fontSize: CGFloat
    @ObservedObject var textEditor: TextEditorViewModel
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Font Size")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.gray.opacity(0.3), in: Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
            
                            // Font size slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Size")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(fontSize))")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Slider(
                        value: Binding(
                            get: { fontSize },
                            set: { newValue in
                                fontSize = newValue
                                textEditor.updateSelectedTextBox()
                            }
                        ),
                        in: 12...80,
                        step: 1
                    )
                    .accentColor(.white)
                }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            
            Spacer()
        }
        .background(Color.black.opacity(0.9))
        .cornerRadius(16)
    }
}

struct TextColorPickerView: View {
    @Binding var selectedColor: Color
    @ObservedObject var textEditor: TextEditorViewModel
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header (fixed at top)
            HStack {
                Text("Text Color")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.gray.opacity(0.3), in: Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
            
            // Scrollable content with blur indicator
            ZStack {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 20) {
                        // Color row
                        ColorRowView(
                            colors: ColorPalette.colors,
                            selectedColor: selectedColor,
                            onColorSelected: { color in
                                selectedColor = color
                                textEditor.updateSelectedTextBox()
                            }
                        )
                        .padding(.bottom, 40) // Extra padding for blur indicator
                    }
                }
                
                // Blur gradient indicator at bottom
                VStack {
                    Spacer()
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.0),
                            Color.black.opacity(0.3),
                            Color.black.opacity(0.6)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 30)
                    .allowsHitTesting(false)
                }
            }
        }
        .background(Color.black.opacity(0.9))
        .cornerRadius(16)
    }
}

struct ShadowPickerView: View {
    @Binding var shadowColor: Color
    @Binding var shadowRadius: CGFloat
    @Binding var shadowX: CGFloat
    @Binding var shadowY: CGFloat
    @Binding var shadowOpacity: Double
    @ObservedObject var textEditor: TextEditorViewModel
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header (fixed at top)
            HStack {
                Text("Text Shadow")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.gray.opacity(0.3), in: Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
            
            // Scrollable content with blur indicator
            ZStack {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 20) {
                        // Color row
                        ColorRowView(
                            colors: ColorPalette.colors,
                            selectedColor: shadowColor,
                            onColorSelected: { color in
                                shadowColor = color
                                textEditor.updateSelectedTextBox()
                            }
                        )
                        
                        // Shadow controls
                        VStack(spacing: 16) {
                            // Shadow Radius Slider
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Blur")
                                        .font(.subheadline)
                                        .foregroundColor(shadowColor == .clear ? .gray : .white)
                                    Spacer()
                                    Text("\(Int(shadowRadius))")
                                        .font(.subheadline)
                                        .foregroundColor(shadowColor == .clear ? .gray.opacity(0.7) : .white.opacity(0.7))
                                }
                                
                                Slider(
                                    value: Binding(
                                        get: { shadowRadius },
                                        set: { newValue in
                                            shadowRadius = newValue
                                            textEditor.updateSelectedTextBox()
                                        }
                                    ),
                                    in: 0...20,
                                    step: 1
                                )
                                .accentColor(.white)
                                .disabled(shadowColor == .clear)
                            }
                            
                            // Shadow X Offset Slider
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("X Offset")
                                        .font(.subheadline)
                                        .foregroundColor(shadowColor == .clear ? .gray : .white)
                                    Spacer()
                                    Text("\(Int(shadowX))")
                                        .font(.subheadline)
                                        .foregroundColor(shadowColor == .clear ? .gray.opacity(0.7) : .white.opacity(0.7))
                                }
                                
                                Slider(
                                    value: Binding(
                                        get: { shadowX },
                                        set: { newValue in
                                            shadowX = newValue
                                            textEditor.updateSelectedTextBox()
                                        }
                                    ),
                                    in: -10...10,
                                    step: 1
                                )
                                .accentColor(.white)
                                .disabled(shadowColor == .clear)
                            }
                            
                            // Shadow Y Offset Slider
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Y Offset")
                                        .font(.subheadline)
                                        .foregroundColor(shadowColor == .clear ? .gray : .white)
                                    Spacer()
                                    Text("\(Int(shadowY))")
                                        .font(.subheadline)
                                        .foregroundColor(shadowColor == .clear ? .gray.opacity(0.7) : .white.opacity(0.7))
                                }
                                
                                Slider(
                                    value: Binding(
                                        get: { shadowY },
                                        set: { newValue in
                                            shadowY = newValue
                                            textEditor.updateSelectedTextBox()
                                        }
                                    ),
                                    in: -10...10,
                                    step: 1
                                )
                                .accentColor(.white)
                                .disabled(shadowColor == .clear)
                            }
                            
                            // Shadow Opacity Slider
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Opacity")
                                        .font(.subheadline)
                                        .foregroundColor(shadowColor == .clear ? .gray : .white)
                                    Spacer()
                                    Text("\(Int(shadowOpacity * 100))%")
                                        .font(.subheadline)
                                        .foregroundColor(shadowColor == .clear ? .gray.opacity(0.7) : .white.opacity(0.7))
                                }
                                
                                Slider(
                                    value: Binding(
                                        get: { shadowOpacity },
                                        set: { newValue in
                                            shadowOpacity = newValue
                                            textEditor.updateSelectedTextBox()
                                        }
                                    ),
                                    in: 0...1,
                                    step: 0.1
                                )
                                .accentColor(.white)
                                .disabled(shadowColor == .clear)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40) // Extra padding for blur indicator
                    }
                }
                
                // Blur gradient indicator at bottom
                VStack {
                    Spacer()
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.0),
                            Color.black.opacity(0.3),
                            Color.black.opacity(0.6)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 30)
                    .allowsHitTesting(false)
                }
            }
        }
        .background(Color.black.opacity(0.9))
        .cornerRadius(16)
    }
}

struct StrokeColorPickerView: View {
    @Binding var selectedColor: Color
    @Binding var strokeWidth: CGFloat
    @ObservedObject var textEditor: TextEditorViewModel
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header (fixed at top)
            HStack {
                Text("Text Stroke")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.gray.opacity(0.3), in: Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
            
            // Scrollable content with blur indicator
            ZStack {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 20) {
                        // Color row
                        ColorRowView(
                            colors: ColorPalette.colors,
                            selectedColor: selectedColor,
                            onColorSelected: { color in
                                selectedColor = color
                                // Update the text box in the main model
                                textEditor.updateSelectedTextBox()
                            }
                        )
                        
                        // Stroke width slider
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Stroke Width")
                                    .font(.subheadline)
                                    .foregroundColor(selectedColor == .clear ? .gray : .white)
                                Spacer()
                                Text(String(format: "%.1f", strokeWidth))
                                    .font(.subheadline)
                                    .foregroundColor(selectedColor == .clear ? .gray.opacity(0.7) : .white.opacity(0.7))
                            }
                            
                            Slider(
                                value: Binding(
                                    get: { strokeWidth },
                                    set: { newValue in
                                        strokeWidth = newValue
                                        textEditor.updateSelectedTextBox()
                                    }
                                ),
                                in: 0...10,
                                step: 0.5
                            )
                            .accentColor(.white)
                            .disabled(selectedColor == .clear)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40) // Extra padding for blur indicator
                    }
                }
                
                // Blur gradient indicator at bottom
                VStack {
                    Spacer()
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.0),
                            Color.black.opacity(0.3),
                            Color.black.opacity(0.6)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 30)
                    .allowsHitTesting(false)
                }
            }
        }
        .background(Color.black.opacity(0.9))
        .cornerRadius(16)
    }
}