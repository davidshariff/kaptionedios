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
    @Published var currentTextBox: TextBox = TextBox()
    @Published var selectedTextBox: TextBox?
    private var isEditMode: Bool = false
    
    func cancelTextEditor(){
        showEditor = false
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
            print("DEBUG: Editing existing TextBox - karaokeType: \(textBox.karaokeType), highlightColor: \(textBox.highlightColor), wordBGColor: \(textBox.wordBGColor)")
        }else{
            currentTextBox = TextBox(timeRange: timeRange ?? (1...5))
            print("DEBUG: Creating new TextBox - karaokeType: \(currentTextBox.karaokeType), highlightColor: \(currentTextBox.highlightColor), wordBGColor: \(currentTextBox.wordBGColor)")
            isEditMode = false
        }
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
