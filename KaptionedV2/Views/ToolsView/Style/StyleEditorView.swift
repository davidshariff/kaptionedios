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

// MARK: - Confirmation Dialog for Apply to All
struct ApplyToAllConfirmationDialog: View {
    @Binding var isPresented: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void
    let styleName: String
    
    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        onCancel()
                        isPresented = false
                    }
                
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Text("Apply to All Text?")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        Text("This will apply the current \(styleName.lowercased()) settings to all text in your video.")
                            .font(.subheadline)
                            .foregroundColor(.black.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    
                    HStack(spacing: 12) {
                        Button {
                            onCancel()
                            isPresented = false
                        } label: {
                            Text("Cancel")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.black)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button {
                            onConfirm()
                            isPresented = false
                        } label: {
                            Text("Apply to All")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(28)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                )
                .padding(.horizontal, 32)
            }
        }
    }
}

// MARK: - Reusable Apply to All Toggle
struct ApplyToAllToggle: View {
    @Binding var isOn: Bool
    let onToggleChanged: ((Bool) -> Void)?
    
    init(isOn: Binding<Bool>, onToggleChanged: ((Bool) -> Void)? = nil) {
        self._isOn = isOn
        self.onToggleChanged = onToggleChanged
    }
    
    var body: some View {
        HStack {
            Toggle("Apply to All", isOn: Binding(
                get: { isOn },
                set: { newValue in
                    isOn = newValue
                    onToggleChanged?(newValue)
                }
            ))
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .foregroundColor(.white)
                .font(.subheadline)
                .padding(.horizontal, 0)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

// MARK: - Reusable Blur Gradient
struct BlurGradient: View {
    var body: some View {
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

// MARK: - Base Style Picker View
struct BaseStylePickerView<Content: View>: View {
    let title: String
    let onDismiss: () -> Void
    let applyToAllBinding: Binding<Bool>
    let onToggleChanged: ((Bool) -> Void)?
    let content: Content
    
    init(title: String, onDismiss: @escaping () -> Void, applyToAllBinding: Binding<Bool>, onToggleChanged: ((Bool) -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.onDismiss = onDismiss
        self.applyToAllBinding = applyToAllBinding
        self.onToggleChanged = onToggleChanged
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(title)
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
            
            // Apply to All toggle
            ApplyToAllToggle(isOn: applyToAllBinding, onToggleChanged: onToggleChanged)
            
            // Content
            content
        }
        .background(Color.black.opacity(0.8))
        .clipShape(
            .rect(
                topLeadingRadius: 16,
                topTrailingRadius: 16
            )
        )
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
    }
}

struct StyleEditorView: View {
    @ObservedObject var textEditor: TextEditorViewModel
    @Binding var selectedStyleOptionToEdit: String?
    @State private var showColorPicker = false
    
    var body: some View {
        if let selectedStyleOptionToEdit = selectedStyleOptionToEdit {
            VStack(spacing: 0) {
                Spacer()
                
                switch selectedStyleOptionToEdit {
                case "Background":
                    BackgroundColorPickerView(
                        selectedColor: $textEditor.currentTextBox.bgColor,
                        textEditor: textEditor,
                        onDismiss: {
                            self.selectedStyleOptionToEdit = nil
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
                            self.selectedStyleOptionToEdit = nil
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
                            self.selectedStyleOptionToEdit = nil
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
                            self.selectedStyleOptionToEdit = nil
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
                            self.selectedStyleOptionToEdit = nil
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
    @State private var showConfirmationDialog = false
    
    var body: some View {
        ZStack {
            BaseStylePickerView(
                title: "Text Background Color",
                onDismiss: onDismiss,
                applyToAllBinding: $textEditor.applyBackgroundToAll,
                onToggleChanged: { isOn in
                    if isOn {
                        showConfirmationDialog = true
                    }
                }
            ) {
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
                                textEditor.autoApplyBackground(
                                    bgColor: color,
                                    padding: textEditor.currentTextBox.backgroundPadding,
                                    cornerRadius: textEditor.currentTextBox.cornerRadius
                                )
                            }
                        )
                        
                        // Background padding and corner radius sliders
                        VStack(spacing: 16) {
                            // Background Padding Slider
                            StyleSlider(
                                title: "Background Padding",
                                value: Binding(
                                    get: { textEditor.currentTextBox.backgroundPadding },
                                    set: { newValue in
                                        textEditor.currentTextBox.backgroundPadding = newValue
                                        textEditor.updateSelectedTextBox()
                                        textEditor.autoApplyBackground(
                                            bgColor: selectedColor,
                                            padding: newValue,
                                            cornerRadius: textEditor.currentTextBox.cornerRadius
                                        )
                                    }
                                ),
                                range: 0...40,
                                step: 1,
                                format: "\(Int(textEditor.currentTextBox.backgroundPadding))",
                                isDisabled: selectedColor == .clear
                            )
                            
                            // Corner Radius Slider
                            StyleSlider(
                                title: "Corner Radius",
                                value: Binding(
                                    get: { textEditor.currentTextBox.cornerRadius },
                                    set: { newValue in
                                        textEditor.currentTextBox.cornerRadius = newValue
                                        textEditor.updateSelectedTextBox()
                                        textEditor.autoApplyBackground(
                                            bgColor: selectedColor,
                                            padding: textEditor.currentTextBox.backgroundPadding,
                                            cornerRadius: newValue
                                        )
                                    }
                                ),
                                range: 0...20,
                                step: 1,
                                format: "\(Int(textEditor.currentTextBox.cornerRadius))",
                                isDisabled: selectedColor == .clear
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
                
                BlurGradient()
            }
            }
            
            ApplyToAllConfirmationDialog(
                isPresented: $showConfirmationDialog,
                onConfirm: {
                    textEditor.immediatelyApplyCurrentBackground()
                },
                onCancel: {
                    textEditor.applyBackgroundToAll = false
                },
                styleName: "Background"
            )
        }
    }
}

struct FontSizePickerView: View {
    @Binding var fontSize: CGFloat
    @ObservedObject var textEditor: TextEditorViewModel
    let onDismiss: () -> Void
    @State private var showConfirmationDialog = false
    
    var body: some View {
        ZStack {
            BaseStylePickerView(
                title: "Font Size",
                onDismiss: onDismiss,
                applyToAllBinding: $textEditor.applyFontSizeToAll,
                onToggleChanged: { isOn in
                    if isOn {
                        showConfirmationDialog = true
                    }
                }
            ) {
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
                            textEditor.autoApplyFontSize(newValue)
                        }
                    ),
                    in: 12...80,
                    step: 1
                )
                .accentColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            }
            
            ApplyToAllConfirmationDialog(
                isPresented: $showConfirmationDialog,
                onConfirm: {
                    textEditor.immediatelyApplyCurrentFontSize()
                },
                onCancel: {
                    textEditor.applyFontSizeToAll = false
                },
                styleName: "Font Size"
            )
        }
    }
}

struct TextColorPickerView: View {
    @Binding var selectedColor: Color
    @ObservedObject var textEditor: TextEditorViewModel
    let onDismiss: () -> Void
    @State private var showConfirmationDialog = false
    
    var body: some View {
        ZStack {
            BaseStylePickerView(
                title: "Text Color",
                onDismiss: onDismiss,
                applyToAllBinding: $textEditor.applyTextColorToAll,
                onToggleChanged: { isOn in
                    if isOn {
                        showConfirmationDialog = true
                    }
                }
            ) {
            ZStack {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 20) {
                        ColorRowView(
                            colors: ColorPalette.colors,
                            selectedColor: selectedColor,
                            onColorSelected: { color in
                                selectedColor = color
                                textEditor.updateSelectedTextBox()
                                textEditor.autoApplyTextColor(color)
                            }
                        )
                        .padding(.bottom, 40)
                    }
                }
                
                BlurGradient()
            }
            }
            
            ApplyToAllConfirmationDialog(
                isPresented: $showConfirmationDialog,
                onConfirm: {
                    textEditor.immediatelyApplyCurrentTextColor()
                },
                onCancel: {
                    textEditor.applyTextColorToAll = false
                },
                styleName: "Text Color"
            )
        }
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
    @State private var showConfirmationDialog = false
    
    var body: some View {
        ZStack {
            BaseStylePickerView(
                title: "Text Shadow",
                onDismiss: onDismiss,
                applyToAllBinding: $textEditor.applyShadowToAll,
                onToggleChanged: { isOn in
                    if isOn {
                        showConfirmationDialog = true
                    }
                }
            ) {
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
                                textEditor.autoApplyShadow(
                                    shadowColor: color,
                                    shadowRadius: shadowRadius,
                                    shadowX: shadowX,
                                    shadowY: shadowY,
                                    shadowOpacity: shadowOpacity
                                )
                            }
                        )
                        
                        // Shadow controls
                        VStack(spacing: 16) {
                            StyleSlider(
                                title: "Blur",
                                value: Binding(
                                    get: { shadowRadius },
                                    set: { newValue in
                                        shadowRadius = newValue
                                        textEditor.updateSelectedTextBox()
                                        textEditor.autoApplyShadow(
                                            shadowColor: shadowColor,
                                            shadowRadius: newValue,
                                            shadowX: shadowX,
                                            shadowY: shadowY,
                                            shadowOpacity: shadowOpacity
                                        )
                                    }
                                ),
                                range: 0...20,
                                step: 1,
                                format: "\(Int(shadowRadius))",
                                isDisabled: shadowColor == .clear
                            )
                            
                            StyleSlider(
                                title: "X Offset",
                                value: Binding(
                                    get: { shadowX },
                                    set: { newValue in
                                        shadowX = newValue
                                        textEditor.updateSelectedTextBox()
                                        textEditor.autoApplyShadow(
                                            shadowColor: shadowColor,
                                            shadowRadius: shadowRadius,
                                            shadowX: newValue,
                                            shadowY: shadowY,
                                            shadowOpacity: shadowOpacity
                                        )
                                    }
                                ),
                                range: -10...10,
                                step: 1,
                                format: "\(Int(shadowX))",
                                isDisabled: shadowColor == .clear
                            )
                            
                            StyleSlider(
                                title: "Y Offset",
                                value: Binding(
                                    get: { shadowY },
                                    set: { newValue in
                                        shadowY = newValue
                                        textEditor.updateSelectedTextBox()
                                        textEditor.autoApplyShadow(
                                            shadowColor: shadowColor,
                                            shadowRadius: shadowRadius,
                                            shadowX: shadowX,
                                            shadowY: newValue,
                                            shadowOpacity: shadowOpacity
                                        )
                                    }
                                ),
                                range: -10...10,
                                step: 1,
                                format: "\(Int(shadowY))",
                                isDisabled: shadowColor == .clear
                            )
                            
                            StyleSlider(
                                title: "Opacity",
                                value: Binding(
                                    get: { shadowOpacity },
                                    set: { newValue in
                                        shadowOpacity = newValue
                                        textEditor.updateSelectedTextBox()
                                        textEditor.autoApplyShadow(
                                            shadowColor: shadowColor,
                                            shadowRadius: shadowRadius,
                                            shadowX: shadowX,
                                            shadowY: shadowY,
                                            shadowOpacity: newValue
                                        )
                                    }
                                ),
                                range: 0...1,
                                step: 0.1,
                                format: "\(Int(shadowOpacity * 100))%",
                                isDisabled: shadowColor == .clear
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
                
                BlurGradient()
            }
            }
            
            ApplyToAllConfirmationDialog(
                isPresented: $showConfirmationDialog,
                onConfirm: {
                    textEditor.immediatelyApplyCurrentShadow()
                },
                onCancel: {
                    textEditor.applyShadowToAll = false
                },
                styleName: "Shadow"
            )
        }
    }
}

struct StrokeColorPickerView: View {
    @Binding var selectedColor: Color
    @Binding var strokeWidth: CGFloat
    @ObservedObject var textEditor: TextEditorViewModel
    let onDismiss: () -> Void
    @State private var showConfirmationDialog = false
    
    var body: some View {
        ZStack {
            BaseStylePickerView(
                title: "Text Stroke",
                onDismiss: onDismiss,
                applyToAllBinding: $textEditor.applyStrokeToAll,
                onToggleChanged: { isOn in
                    if isOn {
                        showConfirmationDialog = true
                    }
                }
            ) {
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
                                textEditor.autoApplyStroke(strokeColor: color, strokeWidth: strokeWidth)
                            }
                        )
                        
                        // Stroke width slider
                        StyleSlider(
                            title: "Stroke Width",
                            value: Binding(
                                get: { strokeWidth },
                                set: { newValue in
                                    strokeWidth = newValue
                                    textEditor.updateSelectedTextBox()
                                    textEditor.autoApplyStroke(strokeColor: selectedColor, strokeWidth: newValue)
                                }
                            ),
                            range: 0...10,
                            step: 0.5,
                            format: String(format: "%.1f", strokeWidth),
                            isDisabled: selectedColor == .clear
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
                
                BlurGradient()
            }
            }
            
            ApplyToAllConfirmationDialog(
                isPresented: $showConfirmationDialog,
                onConfirm: {
                    textEditor.immediatelyApplyCurrentStroke()
                },
                onCancel: {
                    textEditor.applyStrokeToAll = false
                },
                styleName: "Stroke"
            )
        }
    }
}

// MARK: - Reusable Style Slider
struct StyleSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: String
    let isDisabled: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(isDisabled ? .gray : .white)
                Spacer()
                Text(format)
                    .font(.subheadline)
                    .foregroundColor(isDisabled ? .gray.opacity(0.7) : .white.opacity(0.7))
            }
            
            Slider(
                value: $value,
                in: range,
                step: step
            )
            .accentColor(.white)
            .disabled(isDisabled)
        }
    }
}