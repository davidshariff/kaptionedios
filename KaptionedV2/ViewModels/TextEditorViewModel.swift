//
//  TextEditorViewModel.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 02.05.2023.
//

import Foundation
import SwiftUI

class TextEditorViewModel: ObservableObject{
    
    @Published var textBoxes: [TextBox] = []
    @Published var showEditor: Bool = false
    @Published var showEditTextContent: Bool = false
    @Published var currentTextBox: TextBox = TextBox()
    @Published var selectedTextBox: TextBox?
    @Published var isEditMode: Bool = false
    
    var onEditTextContentClosed: (() -> Void)?
    
    func cancelTextEditor(){
        showEditor = false
        showEditTextContent = false
        onEditTextContentClosed?()
    }
    
    func closeEditTextContent(){
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
            showEditTextContent = false  // Show full editor for openTextEditor
        }else{
            currentTextBox = TextBox(timeRange: timeRange ?? (1...5))
            isEditMode = false
            showEditTextContent = false
        }
        showEditor = true
    }

    func openEditTextContent(){
        if let selectedTextBox = selectedTextBox {
            currentTextBox = selectedTextBox
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
}

extension TextEditorViewModel {
    func applyKaraokePreset(_ preset: KaraokePreset) {
        guard let selectedTextBox = selectedTextBox,
              let index = textBoxes.firstIndex(where: { $0.id == selectedTextBox.id }) else { return }
        textBoxes[index].karaokeType = preset.karaokeType
        textBoxes[index].highlightColor = preset.highlightColor
        textBoxes[index].wordBGColor = preset.wordBGColor
    }
}
