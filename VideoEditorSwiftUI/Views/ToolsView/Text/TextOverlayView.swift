//
//  TextOverlayView.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 01.05.2023.
//

import SwiftUI

struct TextOverlayView: View {
    var currentTime: Double
    @ObservedObject var viewModel: TextEditorViewModel
    var disabledMagnification: Bool = false
    var body: some View {
        ZStack{
            if !disabledMagnification{
                Color.secondary.opacity(0.001)
                    .simultaneousGesture(MagnificationGesture()
                        .onChanged({ value in
                            if let box = viewModel.selectedTextBox{
                                let lastFontSize = viewModel.textBoxes[getIndex(box.id)].lastFontSize
                                viewModel.textBoxes[getIndex(box.id)].fontSize = (value * 10) + lastFontSize
                            }
                        }).onEnded({ value in
                            if let box = viewModel.selectedTextBox{
                                viewModel.textBoxes[getIndex(box.id)].lastFontSize = value * 10
                            }
                        }))
            }
            
            ForEach(viewModel.textBoxes) { textBox in
                let isSelected = viewModel.isSelected(textBox.id)
                
                if textBox.timeRange.contains(currentTime){
                    
                    ZStack(alignment: .topLeading) {
                        // Text positioned with offset
                        ZStack {
                            // Stroke layer (if stroke is enabled)
                            if textBox.strokeColor != .clear && textBox.strokeWidth > 0 {
                                Text(textBox.text)
                                    .font(.system(size: textBox.fontSize, weight: .medium))
                                    .foregroundColor(textBox.strokeColor)
                                    .padding(.horizontal, textBox.backgroundPadding)
                                    .padding(.vertical, textBox.backgroundPadding / 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: textBox.cornerRadius)
                                            .fill(textBox.bgColor)
                                    )
                                    .scaleEffect(1 + (textBox.strokeWidth / 50))
                            }
                            
                            // Main text layer
                            Text(textBox.text)
                                .font(.system(size: textBox.fontSize, weight: .medium))
                                .foregroundColor(textBox.fontColor)
                                .padding(.horizontal, textBox.backgroundPadding)
                                .padding(.vertical, textBox.backgroundPadding / 2)
                                .background(
                                    RoundedRectangle(cornerRadius: textBox.cornerRadius)
                                        .fill(textBox.bgColor)
                                )
                        }
                            .overlay {
                                if isSelected{
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(lineWidth: 1)
                                        .foregroundColor(.cyan)
                                }
                            }
                            .onTapGesture {
                                editOrSelectTextBox(textBox, isSelected)
                            }
                            .offset(textBox.offset)
                        
                        // Buttons positioned absolutely, not affecting text position
                        if isSelected{
                            textBoxButtons(textBox)
                                .offset(x: textBox.offset.width, y: textBox.offset.height - 30)
                        }
                    }
                    .simultaneousGesture(DragGesture(minimumDistance: 1).onChanged({ value in
                        guard isSelected else {return}
                        let current = value.translation
                        let lastOffset = textBox.lastOffset
                        let newTranslation: CGSize = .init(width: current.width + lastOffset.width, height: current.height + lastOffset.height)
                        
                        DispatchQueue.main.async {
                            viewModel.textBoxes[getIndex(textBox.id)].offset = newTranslation
                        }
                        
                    }).onEnded({ value in
                        guard isSelected else {return}
                        DispatchQueue.main.async {
                            // Update lastOffset to be the accumulated offset, not just the last drag translation
                            viewModel.textBoxes[getIndex(textBox.id)].lastOffset = CGSize(
                                width: textBox.offset.width,
                                height: textBox.offset.height
                            )
                        }
                    }))
                }
            }
        }
        .allFrame()
    }
    
    private func createAttr(_ textBox: TextBox) -> AttributedString{
        var result = AttributedString(textBox.text)
        result.font = .systemFont(ofSize: textBox.fontSize, weight: .medium)
        result.foregroundColor = UIColor(textBox.fontColor)
        result.backgroundColor = UIColor(textBox.bgColor)
        
        // Apply stroke if stroke color is not clear and stroke width is greater than 0
        if textBox.strokeColor != .clear && textBox.strokeWidth > 0 {
            result.strokeColor = UIColor(textBox.strokeColor)
            result.strokeWidth = -textBox.strokeWidth
        }
        
        return result
    }
}


    
    private func createNSAttr(_ textBox: TextBox) -> NSAttributedString {
        let attrStr = NSMutableAttributedString(string: textBox.text)
        let range = NSRange(location: 0, length: attrStr.length)
        
        attrStr.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: textBox.fontSize, weight: .medium), range: range)
        attrStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor(textBox.fontColor), range: range)
        attrStr.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor(textBox.bgColor), range: range)
        
        // Apply stroke if stroke color is not clear and stroke width is greater than 0
        if textBox.strokeColor != .clear && textBox.strokeWidth > 0 {
            attrStr.addAttribute(NSAttributedString.Key.strokeColor, value: UIColor(textBox.strokeColor), range: range)
            attrStr.addAttribute(NSAttributedString.Key.strokeWidth, value: -textBox.strokeWidth, range: range)
        }
        
        return attrStr
    }




struct TextOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        MainEditorView(selectedVideoURl: Video.mock.url)
    }
}


extension TextOverlayView{
    
    private func textBoxButtons(_ textBox: TextBox) -> some View{
        HStack(spacing: 10){
            TrashButtonWithConfirmation(onDelete: { viewModel.removeTextBox() })
            Button {
                viewModel.copy(textBox)
            } label: {
                Image(systemName: "doc.on.doc")
                    .imageScale(.small)
                    .padding(5)
                    .background(Color(.systemGray2), in: Circle())
            }
        }
        .foregroundColor(.white)
    }
    
    private func editOrSelectTextBox(_ textBox: TextBox, _ isSelected: Bool){
        if isSelected{
            viewModel.openTextEditor(isEdit: true, textBox)
        }else{
            viewModel.selectTextBox(textBox)
        }
    }
    
    private func getIndex(_ id: UUID) -> Int{
        let index = viewModel.textBoxes.firstIndex(where: {$0.id == id})
        return index ?? 0
    }
}

struct TrashButtonWithConfirmation: View {
    @State private var showAlert = false
    let onDelete: () -> Void
    var body: some View {
        Button {
            showAlert = true
        } label: {
            Image(systemName: "trash")
                .padding(5)
                .background(Color(.systemGray2), in: Circle())
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Are you sure?"),
                message: Text("This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    onDelete()
                },
                secondaryButton: .cancel()
            )
        }
    }
}











