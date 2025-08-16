//
//  ProjectEntity+Ext.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 20.04.2023.
//

import Foundation
import CoreData
import SwiftUI


extension ProjectEntity{
    
    
    
    var videoURL: URL?{
        guard let url else {return nil}
        return FileManager().createVideoPath(with: url)
    }

    
    var wrappedTextBoxes: [TextBox]{
        wrappedBoxes.compactMap { entity -> TextBox? in
            if let text = entity.text, let bgColor = entity.bgColor,
               let fontColor = entity.fontColor{
                var textBox = TextBox(text: text, fontSize: entity.fontSize, bgColor: Color(hex: bgColor), fontColor: Color(hex: fontColor), timeRange: (entity.lowerTime...entity.upperTime), offset: .init(width: entity.offsetX, height: entity.offsetY))
                
                // Handle stroke properties if they exist
                if let strokeColor = entity.strokeColor {
                    textBox.strokeColor = Color(hex: strokeColor)
                }
                textBox.strokeWidth = entity.strokeWidth
                // Restore shadow properties
                if let shadowColor = entity.shadowColor {
                    textBox.shadowColor = Color(hex: shadowColor)
                }
                textBox.shadowRadius = entity.shadowRadius
                textBox.shadowX = entity.shadowX
                textBox.shadowY = entity.shadowY
                textBox.shadowOpacity = entity.shadowOpacity
                textBox.backgroundPadding = entity.backgroundPadding
                textBox.cornerRadius = entity.cornerRadius
                textBox.presetName = entity.presetName
                
                // Restore karaoke properties
                textBox.isKaraokePreset = entity.isKaraokePreset
                if let karaokeTypeString = entity.karaokeType {
                    textBox.karaokeType = KaraokeType(rawValue: karaokeTypeString)
                }
                if let highlightColorString = entity.highlightColor {
                    textBox.highlightColor = Color(hex: highlightColorString)
                }
                if let wordBGColorString = entity.wordBGColor {
                    textBox.wordBGColor = Color(hex: wordBGColorString)
                }
                
                // Restore word timings if they exist
                if let wordTimingsData = entity.wordTimingsData {
                    do {
                        let decoder = JSONDecoder()
                        textBox.wordTimings = try decoder.decode([WordWithTiming].self, from: wordTimingsData)
                    } catch {
                        print("DEBUG: Failed to decode word timings: \(error)")
                    }
                } else if textBox.isKaraokePreset && textBox.wordTimings == nil {
                    // Regenerate word timings for karaoke presets if they're missing
                    let words = textBox.text.split(separator: " ").map(String.init)
                    let lineDuration = textBox.timeRange.upperBound - textBox.timeRange.lowerBound
                    let wordDuration = lineDuration / Double(max(words.count, 1))
                    var wordTimings: [WordWithTiming] = []
                    for (j, word) in words.enumerated() {
                        let wordStart = textBox.timeRange.lowerBound + Double(j) * wordDuration
                        let wordEnd = wordStart + wordDuration
                        wordTimings.append(WordWithTiming(text: word, start: wordStart, end: wordEnd))
                    }
                    textBox.wordTimings = wordTimings
                }
                
                return textBox
            }
            return nil
        }
    }


    private var wrappedBoxes: Set<TextBoxEntity> {
        get { (textBoxes as? Set<TextBoxEntity>) ?? [] }
        set { textBoxes = newValue as NSSet }
    }
    
    var wrappedTools: [Int]{
        appliedTools?.components(separatedBy: ",").compactMap({Int($0)}) ?? []
    }
    
    var wrappedColor: Color{
        guard let frameColor else { return .blue }
        return Color(hex: frameColor)
    }
    
    var uiImage: UIImage{
        if let id, let uImage = FileManager().retrieveImage(with: id){
            return uImage
        }else{
            return UIImage(systemName: "exclamationmark.circle")!
        }
    }
    
    
    static func request() -> NSFetchRequest<ProjectEntity> {
        let request = NSFetchRequest<ProjectEntity>(entityName: "ProjectEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "createAt", ascending: true)]
        return request
    }
    
    
  static func createTextBoxes(context: NSManagedObjectContext, boxes: [TextBox]) -> [TextBoxEntity]{
        
        boxes.map { box -> TextBoxEntity in
            let entity = TextBoxEntity(context: context)
            let offset = box.offset
            entity.text = box.text
            entity.bgColor = box.bgColor.toHex()
            entity.fontColor = box.fontColor.toHex()
            entity.fontSize = box.fontSize
            entity.lowerTime = box.timeRange.lowerBound
            entity.upperTime = box.timeRange.upperBound
            entity.offsetX = offset.width
            entity.offsetY = offset.height
            entity.strokeColor = box.strokeColor.toHex()
            entity.strokeWidth = box.strokeWidth
            entity.shadowColor = box.shadowColor.toHex()
            entity.shadowRadius = box.shadowRadius
            entity.shadowX = box.shadowX
            entity.shadowY = box.shadowY
            entity.shadowOpacity = box.shadowOpacity
            entity.backgroundPadding = box.backgroundPadding
            entity.cornerRadius = box.cornerRadius
            entity.presetName = box.presetName
            
            // Save karaoke properties
            entity.isKaraokePreset = box.isKaraokePreset
            entity.karaokeType = box.karaokeType?.rawValue
            entity.highlightColor = box.highlightColor?.toHex()
            entity.wordBGColor = box.wordBGColor?.toHex()
            
            // Save word timings if they exist
            if let wordTimings = box.wordTimings {
                do {
                    let encoder = JSONEncoder()
                    entity.wordTimingsData = try encoder.encode(wordTimings)
                } catch {
                    print("DEBUG: Failed to encode word timings: \(error)")
                }
            }
            
            return entity
        }
        
    }
    
    
    static func create(video: Video, context: NSManagedObjectContext) -> ProjectEntity {
        let project = ProjectEntity(context: context)
        let id = UUID().uuidString
        if let image = video.thumbnailsImages.first?.image{
            FileManager.default.saveImage(with: id, image: image)
        }
        project.id = id
        project.createAt = Date.now
        project.url = video.url.lastPathComponent
        project.rotation = video.rotation
        project.isMirror = video.isMirror
        project.filterName = video.filterName

        project.textBoxes = []
    
        context.saveContext()
        return project
    }
    
    
    static func update(for video: Video, project: ProjectEntity){
        if let context = project.managedObjectContext {
            project.isMirror = video.isMirror

            project.filterName = video.filterName

            project.appliedTools = video.toolsApplied.map({String($0)}).joined(separator: ",")
            project.rotation = video.rotation
            project.frameColor = video.videoFrames?.frameColor.toHex()
            project.frameScale = video.videoFrames?.scaleValue ?? 0
            let boxes = createTextBoxes(context: context, boxes: video.textBoxes)
            project.wrappedBoxes = Set(boxes)
            
            if let audio = video.audio{
                project.audio = AudioEntity.createAudio(context: context,
                                             url: audio.url.absoluteString,
                                             duration: audio.duration)
            }else{
                project.audio = nil
            }
            
            context.saveContext()
        }
    }
    
    static func remove(_ item: ProjectEntity){
        if let context = item.managedObjectContext, let id = item.id, let url = item.url{
            let manager = FileManager.default
            manager.deleteImage(with: id)
            manager.deleteVideo(with: url)
            context.delete(item)
            context.saveContext()
        }
    }
    
}


extension NSManagedObjectContext {
    
    static var onSaving: (() -> Void)?
    
    func saveContext (){
        if self.hasChanges {
            // Trigger saving indicator
            NSManagedObjectContext.onSaving?()
            
            do{
                try self.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
