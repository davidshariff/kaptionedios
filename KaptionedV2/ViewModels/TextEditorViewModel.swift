import Foundation
import SwiftUI

class TextEditorViewModel: ObservableObject{
    
    @Published var textBoxes: [TextBox] = []
    @Published var showEditor: Bool = false
    @Published var showEditTextContent: Bool = false
    @Published var currentTextBox: TextBox = TextBox()
    @Published var selectedTextBox: TextBox?
    @Published var isEditMode: Bool = false
    @Published var selectedStyleOptionToEdit: String? = nil
    
    // Track which styles should be applied to all
    @Published var applyTextColorToAll: Bool = false
    @Published var applyBackgroundToAll: Bool = false
    @Published var applyStrokeToAll: Bool = false
    @Published var applyFontSizeToAll: Bool = false
    @Published var applyShadowToAll: Bool = false
    
    var onEditTextContentClosed: (() -> Void)?
    var onSave: (([TextBox]) -> Void)?
    
    func cancelTextEditor(){
        showEditor = false
        showEditTextContent = false
        onEditTextContentClosed?()
    }
    
    func closeEditTextContent(){
        // Save the changes back to the original text box
        if let selectedTextBox = selectedTextBox,
           let index = textBoxes.firstIndex(where: {$0.id == selectedTextBox.id}){
            textBoxes[index] = currentTextBox
            // Update the selectedTextBox reference to point to the updated text box
            self.selectedTextBox = textBoxes[index]
        }
        
        // Call onSave to update the main video model
        onSave?(textBoxes)
        
        showEditTextContent = false
        showEditor = false
        onEditTextContentClosed?()
    }
    
    func selectTextBox(_ texBox: TextBox){
        selectedTextBox = texBox
    }
    
    func deselectTextBox(){
        selectedTextBox = nil
    }
    
    func isSelected(_ id: UUID) -> Bool{
        selectedTextBox?.id == id
    }
    
    func setTime(_ time: ClosedRange<Double>){
        guard let selectedTextBox else {return}
        if let index = textBoxes.firstIndex(where: {$0.id == selectedTextBox.id}){
            textBoxes[index].timeRange = time
        }
    }
    
    func removeTextBox(){
        guard let selectedTextBox else {return}
        textBoxes.removeAll(where: {$0.id == selectedTextBox.id})
        self.selectedTextBox = nil
        // Call onSave to update the main video model
        onSave?(textBoxes)
    }
    
    func copy(_ textBox: TextBox){
        var new = textBox
        new.id = UUID()
        new.offset = .init(width: new.offset.width + 10, height: new.offset.height + 10)
        textBoxes.append(new)
    }
    
    func openTextEditor(isEdit: Bool, _ textBox: TextBox? = nil, timeRange: ClosedRange<Double>? = nil){
        if let textBox, isEdit{
            isEditMode = true
            currentTextBox = textBox
            // Show full editor for openTextEditor, not the small one
            showEditTextContent = false
        }else{
            currentTextBox = TextBox(timeRange: timeRange ?? (1...5))
            isEditMode = false
            showEditTextContent = false
        }
        showEditor = true
    }

    func openEditTextContent(){
        if let selectedTextBox = selectedTextBox {
            // Create a copy to avoid reference issues
            currentTextBox = selectedTextBox
            // Ensure we have a unique ID for editing
            currentTextBox.id = selectedTextBox.id
        }
        showEditTextContent = true
        showEditor = true
    }
    
    func saveTapped(){
        if isEditMode{
            if let index = textBoxes.firstIndex(where: {$0.id == currentTextBox.id}){
                textBoxes[index] = currentTextBox
            }
        }else{
            textBoxes.append(currentTextBox)
        }
        selectedTextBox = currentTextBox
        cancelTextEditor()
    }
    
    func deleteCurrentTextBox(){
        if isEditMode{
            // Remove the current text box from the array
            textBoxes.removeAll(where: {$0.id == currentTextBox.id})
            // Deselect the text box
            selectedTextBox = nil
        }
        cancelTextEditor()
    }
    
    func updateSelectedTextBox() {
        print("DEBUG: updateSelectedTextBox called")
        // Update the selected text box with current changes
        if let selectedTextBox = selectedTextBox,
           let index = textBoxes.firstIndex(where: {$0.id == selectedTextBox.id}) {
            
            // Print the differences
            print("🔄 TextBox Update - ID: \(selectedTextBox.id)")
            if selectedTextBox.bgColor != currentTextBox.bgColor {
                print("   bgColor: \(selectedTextBox.bgColor) → \(currentTextBox.bgColor)")
            }
            if selectedTextBox.backgroundPadding != currentTextBox.backgroundPadding {
                print("   backgroundPadding: \(selectedTextBox.backgroundPadding) → \(currentTextBox.backgroundPadding)")
            }
            if selectedTextBox.cornerRadius != currentTextBox.cornerRadius {
                print("   cornerRadius: \(selectedTextBox.cornerRadius) → \(currentTextBox.cornerRadius)")
            }
            if selectedTextBox.fontColor != currentTextBox.fontColor {
                print("   fontColor: \(selectedTextBox.fontColor) → \(currentTextBox.fontColor)")
            }
            if selectedTextBox.strokeColor != currentTextBox.strokeColor {
                print("   strokeColor: \(selectedTextBox.strokeColor) → \(currentTextBox.strokeColor)")
            }
            if selectedTextBox.strokeWidth != currentTextBox.strokeWidth {
                print("   strokeWidth: \(selectedTextBox.strokeWidth) → \(currentTextBox.strokeWidth)")
            }
            if selectedTextBox.fontSize != currentTextBox.fontSize {
                print("   fontSize: \(selectedTextBox.fontSize) → \(currentTextBox.fontSize)")
            }
            if selectedTextBox.text != currentTextBox.text {
                print("   text: '\(selectedTextBox.text)' → '\(currentTextBox.text)'")
            }
            
            textBoxes[index] = currentTextBox
            // Update the selectedTextBox reference to point to the updated text box
            self.selectedTextBox = textBoxes[index]
            // Clean up any duplicate IDs before saving
            cleanupDuplicateIDs()
            // Call onSave to update the main video model
            print("DEBUG: Calling onSave from updateSelectedTextBox")
            onSave?(textBoxes)
        }
    }
    
    func cleanupDuplicateIDs() {
        // Remove any duplicate IDs by keeping only the first occurrence
        var seenIDs: Set<UUID> = []
        textBoxes = textBoxes.filter { textBox in
            if seenIDs.contains(textBox.id) {
                return false
            } else {
                seenIDs.insert(textBox.id)
                return true
            }
        }
    }
}

extension TextEditorViewModel {
    func applyKaraokePreset(_ preset: KaraokePreset) {
        guard let selectedTextBox = selectedTextBox,
              let index = textBoxes.firstIndex(where: { $0.id == selectedTextBox.id }) else { return }
        textBoxes[index].karaokeType = preset.karaokeType
        textBoxes[index].highlightColor = preset.highlightColor
        textBoxes[index].wordBGColor = preset.wordBGColor
        // Call onSave to update the main video model and trigger saving indicator
        onSave?(textBoxes)
    }
    
    // MARK: - Apply to All Functions
    private func applyToAllTextBoxes(_ update: (inout TextBox) -> Void) {
        guard let selectedTextBox = selectedTextBox else { return }
        
        for i in 0..<textBoxes.count {
            if textBoxes[i].id != selectedTextBox.id {
                update(&textBoxes[i])
            }
        }
        onSave?(textBoxes)
    }
    
    func applyTextColorToAll(_ color: Color) {
        applyToAllTextBoxes { textBox in
            textBox.fontColor = color
        }
    }
    
    func applyBackgroundToAll(bgColor: Color, padding: CGFloat, cornerRadius: CGFloat) {
        applyToAllTextBoxes { textBox in
            textBox.bgColor = bgColor
            textBox.backgroundPadding = padding
            textBox.cornerRadius = cornerRadius
        }
    }
    
    func applyStrokeToAll(strokeColor: Color, strokeWidth: CGFloat) {
        applyToAllTextBoxes { textBox in
            textBox.strokeColor = strokeColor
            textBox.strokeWidth = strokeWidth
        }
    }
    
    func applyFontSizeToAll(_ fontSize: CGFloat) {
        applyToAllTextBoxes { textBox in
            textBox.fontSize = fontSize
        }
    }
    
    func applyShadowToAll(shadowColor: Color, shadowRadius: CGFloat, shadowX: CGFloat, shadowY: CGFloat, shadowOpacity: Double) {
        applyToAllTextBoxes { textBox in
            textBox.shadowColor = shadowColor
            textBox.shadowRadius = shadowRadius
            textBox.shadowX = shadowX
            textBox.shadowY = shadowY
            textBox.shadowOpacity = shadowOpacity
        }
    }
    
    // MARK: - Auto-apply functions (called when toggles are on)
    func autoApplyTextColor(_ color: Color) {
        if applyTextColorToAll {
            applyTextColorToAll(color)
        }
    }
    
    func autoApplyBackground(bgColor: Color, padding: CGFloat, cornerRadius: CGFloat) {
        if applyBackgroundToAll {
            applyBackgroundToAll(bgColor: bgColor, padding: padding, cornerRadius: cornerRadius)
        }
    }
    
    func autoApplyStroke(strokeColor: Color, strokeWidth: CGFloat) {
        if applyStrokeToAll {
            applyStrokeToAll(strokeColor: strokeColor, strokeWidth: strokeWidth)
        }
    }
    
    func autoApplyFontSize(_ fontSize: CGFloat) {
        if applyFontSizeToAll {
            applyFontSizeToAll(fontSize)
        }
    }
    
    func autoApplyShadow(shadowColor: Color, shadowRadius: CGFloat, shadowX: CGFloat, shadowY: CGFloat, shadowOpacity: Double) {
        if applyShadowToAll {
            applyShadowToAll(shadowColor: shadowColor, shadowRadius: shadowRadius, shadowX: shadowX, shadowY: shadowY, shadowOpacity: shadowOpacity)
        }
    }
    
    // MARK: - Immediate Apply Functions (for when toggle is turned on)
    func immediatelyApplyCurrentTextColor() {
        guard let selectedTextBox = selectedTextBox else { return }
        applyTextColorToAll(selectedTextBox.fontColor)
    }
    
    func immediatelyApplyCurrentBackground() {
        guard let selectedTextBox = selectedTextBox else { return }
        applyBackgroundToAll(
            bgColor: selectedTextBox.bgColor,
            padding: selectedTextBox.backgroundPadding,
            cornerRadius: selectedTextBox.cornerRadius
        )
    }
    
    func immediatelyApplyCurrentStroke() {
        guard let selectedTextBox = selectedTextBox else { return }
        applyStrokeToAll(
            strokeColor: selectedTextBox.strokeColor,
            strokeWidth: selectedTextBox.strokeWidth
        )
    }
    
    func immediatelyApplyCurrentFontSize() {
        guard let selectedTextBox = selectedTextBox else { return }
        applyFontSizeToAll(selectedTextBox.fontSize)
    }
    
    func immediatelyApplyCurrentShadow() {
        guard let selectedTextBox = selectedTextBox else { return }
        applyShadowToAll(
            shadowColor: selectedTextBox.shadowColor,
            shadowRadius: selectedTextBox.shadowRadius,
            shadowX: selectedTextBox.shadowX,
            shadowY: selectedTextBox.shadowY,
            shadowOpacity: selectedTextBox.shadowOpacity
        )
    }
}
