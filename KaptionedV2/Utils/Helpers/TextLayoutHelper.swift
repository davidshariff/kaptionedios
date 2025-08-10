import SwiftUI
import Foundation

struct TextLayoutHelper {
    
    /// Calculates the optimal number of words per line based on video width and font size
    /// WITHOUT needing the actual text content
    /// - Parameters:
    ///   - videoWidth: The width of the video in points
    ///   - fontSize: The font size in points
    ///   - padding: Additional padding to account for (defaults to 40 points total)
    /// - Returns: The recommended number of words per line
    static func calculateOptimalWordsPerLine(
        videoWidth: CGFloat,
        fontSize: CGFloat,
        padding: CGFloat = 40
    ) -> Int {
        
        // Calculate available width for text
        let availableWidth = videoWidth - padding
        
        // Use average English word length (5.1 characters) and character width
        let averageWordLength: CGFloat = 5.1
        let averageCharacterWidth = fontSize * 0.6 // Approximate character width based on font size
        
        // Calculate average word width (including space)
        let averageWordWidth = (averageWordLength * averageCharacterWidth) + (averageCharacterWidth * 0.3) // Add space
        
        // Calculate optimal words per line
        let optimalWordsPerLine = max(1, Int(availableWidth / averageWordWidth))
        
        return optimalWordsPerLine
    }
    
    /// Calculates the average width of words using SwiftUI Text measurement
    private static func calculateAverageWordWidth(words: [String], fontSize: CGFloat) -> CGFloat {
        guard !words.isEmpty else { return 0 }
        
        let totalWidth = words.reduce(0) { total, word in
            // Use a reasonable approximation for text width
            return total + (CGFloat(word.count) * fontSize * 0.6)
        }
        
        return totalWidth / CGFloat(words.count)
    }
    
    /// Splits subtitle segments into smaller chunks based on optimal word count
    /// - Parameters:
    ///   - textBoxes: Array of subtitle objects from transcribeVideo
    ///   - videoWidth: The width of the video
    ///   - padding: Additional padding (defaults to 0)
    /// - Returns: Array of split TextBox objects
    static func splitSubtitleSegments(
        textBoxes: [Any],
        videoWidth: CGFloat,
        padding: CGFloat = 0
    ) -> [TextBox] {
        
        print("🔍 [TextLayoutHelper] Starting subtitle splitting for \(textBoxes.count) text boxes")
        print("  Video width: \(videoWidth)")
        print("  Padding: \(padding)")
        
        var splitSegments: [TextBox] = []
        
        for (index, textBox) in textBoxes.enumerated() {
            // Use reflection to dynamically extract all properties
            let mirror = Mirror(reflecting: textBox)
            
            // Create a dictionary to store all properties dynamically
            var properties: [String: Any] = [:]
            
            // Extract all properties dynamically - no need to update when adding new properties!
            for child in mirror.children {
                if let label = child.label {
                    properties[label] = child.value
                }
            }
            
            // Extract only the properties we need for processing
            let text = properties["text"] as? String ?? ""
            let fontSize = properties["fontSize"] as? CGFloat ?? 20
            let timeRange = properties["timeRange"] as? ClosedRange<Double> ?? 0...3
            let wordTimings = properties["wordTimings"] as? [WordWithTiming]

            let hasWordTimings = wordTimings != nil && !(wordTimings?.isEmpty ?? true)
            print("🔡 [TextLayoutHelper] wordTimings exists and not empty: \(hasWordTimings ? "✅" : "❌")")
            if let wordTimings = wordTimings {
                print("  Word timings count: \(wordTimings.count)")
                print("  First word: '\(wordTimings.first?.text ?? "N/A")' (\(wordTimings.first?.start ?? 0)s)")
                print("  Last word: '\(wordTimings.last?.text ?? "N/A")' (\(wordTimings.last?.end ?? 0)s)")
                
                // Check if word timings match the text words
                let textWords = text.split(separator: " ").map(String.init)
                let timingWords = wordTimings.map { $0.text }
                
                if textWords.count != timingWords.count {
                    print("  ⚠️  WARNING: Text word count (\(textWords.count)) doesn't match timing word count (\(timingWords.count))")
                    print("  Text words: \(textWords)")
                    print("  Timing words: \(timingWords)")
                } else {
                    print("  ✅ Text and timing word counts match")
                }
            }
            
            print("📝 [TextLayoutHelper] Processing text box \(index + 1): '\(text)' (font size: \(fontSize))")
            print("  Original timing: \(timeRange.lowerBound)s - \(timeRange.upperBound)s")
            
            // Check if current text fits
            if !doesTextFitInVideo(
                text: text,
                videoWidth: videoWidth,
                fontSize: fontSize,
                padding: padding
            ) {
                print("🎯 [TextLayoutHelper] Text doesn't fit, splitting into segments...")
                
                // Calculate optimal words per line
                let maxWordsPerLine = calculateOptimalWordsPerLine(
                    videoWidth: videoWidth,
                    fontSize: fontSize,
                    padding: padding
                )
                
                print("  Max words per line: \(maxWordsPerLine)")
                
                // Split text into words (including line breaks as separators)
                let words = text.split { $0.isWhitespace }.map(String.init)
                
                if words.count <= maxWordsPerLine {
                    print("  No splitting needed (word count <= \(maxWordsPerLine))")
                    // Create TextBox using dynamic properties - automatically handles all properties!
                    let originalTextBox = createTextBoxFromProperties(
                        properties: properties,
                        text: text,
                        fontSize: fontSize,
                        timeRange: timeRange,
                        wordTimings: wordTimings
                    )
                    
                    splitSegments.append(originalTextBox)
                    continue
                }
                
                print("  Splitting into chunks of \(maxWordsPerLine) words...")
                
                // Split the segment into chunks using word timings for accuracy
                let totalChunks = (words.count + maxWordsPerLine - 1) / maxWordsPerLine // Ceiling division
                var chunkIndex = 0
                
                for i in stride(from: 0, to: words.count, by: maxWordsPerLine) {
                    let endIndex = min(i + maxWordsPerLine, words.count)
                    let chunkWords = Array(words[i..<endIndex])
                    chunkIndex += 1
                    
                    // Create chunk text
                    let chunkText = chunkWords.joined(separator: " ")
                    
                    // Calculate timing using word timings for accuracy
                    let chunkStart: Double
                    let chunkEnd: Double
                    let chunkWordTimings: [WordWithTiming]?
                    
                    if let wordTimings = wordTimings, wordTimings.count >= endIndex {
                        // Use actual word timings for precise timing
                        let firstWordIndex = i
                        let lastWordIndex = endIndex - 1
                        chunkStart = wordTimings[firstWordIndex].start
                        chunkEnd = wordTimings[lastWordIndex].end
                        
                        // Extract word timings for this chunk
                        chunkWordTimings = Array(wordTimings[i..<endIndex])
                        
                        print("      Using word timings: \(chunkStart)s - \(chunkEnd)s")
                        print("      Word timings count for chunk: \(chunkWordTimings?.count ?? 0)")
                        print("      Chunk words: \(chunkWords)")
                        print("      Chunk word timings: \(chunkWordTimings?.map { "'\($0.text)'" } ?? [])")
                    } else {
                        // Fallback to calculated timing if word timings not available
                        let totalDuration = timeRange.upperBound - timeRange.lowerBound
                        let chunkDuration = totalDuration / Double(totalChunks)
                        chunkStart = timeRange.lowerBound + (Double(chunkIndex - 1) * chunkDuration)
                        chunkEnd = chunkIndex == totalChunks ? timeRange.upperBound : chunkStart + chunkDuration
                        chunkWordTimings = nil
                        
                        print("      Using calculated timing: \(chunkStart)s - \(chunkEnd)s")
                        print("      No word timings available for this chunk")
                        print("      Available word timings count: \(wordTimings?.count ?? 0)")
                        print("      Required word timings count: \(endIndex)")
                    }
                    
                    print("    Chunk \(chunkIndex):")
                    print("      Text: '\(chunkText)'")
                    print("      Word count: \(chunkWords.count)")
                    print("      Timing: \(chunkStart)s - \(chunkEnd)s")
                    print("      Has word timings: \(chunkWordTimings != nil ? "✅" : "❌")")
                    
                    // Create new TextBox using dynamic properties - automatically handles all properties!
                    let newTextBox = createTextBoxFromProperties(
                        properties: properties,
                        text: chunkText,
                        fontSize: fontSize,
                        timeRange: chunkStart...chunkEnd,
                        wordTimings: chunkWordTimings
                    )
                    
                    splitSegments.append(newTextBox)
                    print("      ✅ Created new TextBox for chunk \(chunkIndex)")
                }
                
            } else {
                print("✅ [TextLayoutHelper] Text fits perfectly: '\(text)'")
                // Create TextBox using dynamic properties - automatically handles all properties!
                let originalTextBox = createTextBoxFromProperties(
                    properties: properties,
                    text: text,
                    fontSize: fontSize,
                    timeRange: timeRange,
                    wordTimings: wordTimings
                )
                
                splitSegments.append(originalTextBox)
            }
        }
        
        print("🏁 [TextLayoutHelper] Subtitle splitting completed")
        print("  Original segments: \(textBoxes.count)")
        print("  Final segments: \(splitSegments.count)")
        
        return splitSegments
    }
    
    /// Helper function to create TextBox from dynamic properties
    /// - Parameters:
    ///   - properties: Dictionary of all TextBox properties
    ///   - text: Text content
    ///   - fontSize: Font size
    ///   - timeRange: Time range
    ///   - wordTimings: Optional word timings for the chunk
    /// - Returns: TextBox object with all properties preserved
    private static func createTextBoxFromProperties(
        properties: [String: Any],
        text: String,
        fontSize: CGFloat,
        timeRange: ClosedRange<Double>,
        wordTimings: [WordWithTiming]? = nil
    ) -> TextBox {
        return TextBox(
            text: text,
            fontSize: fontSize,
            bgColor: properties["bgColor"] as? Color ?? .white,
            fontColor: properties["fontColor"] as? Color ?? .black,
            strokeColor: properties["strokeColor"] as? Color ?? .clear,
            strokeWidth: properties["strokeWidth"] as? CGFloat ?? 0,
            timeRange: timeRange,
            backgroundPadding: properties["backgroundPadding"] as? CGFloat ?? 8,
            cornerRadius: properties["cornerRadius"] as? CGFloat ?? 0,
            shadowColor: properties["shadowColor"] as? Color ?? .black,
            shadowRadius: properties["shadowRadius"] as? CGFloat ?? 0,
            shadowX: properties["shadowX"] as? CGFloat ?? 0,
            shadowY: properties["shadowY"] as? CGFloat ?? 0,
            shadowOpacity: properties["shadowOpacity"] as? Double ?? 0.5,
            wordTimings: wordTimings,
            presetName: properties["presetName"] as? String
        )
    }
    
    /// Validates if text fits within video bounds with improved accuracy
    /// - Parameters:
    ///   - text: The text to validate
    ///   - videoWidth: The width of the video
    ///   - fontSize: The font size
    ///   - padding: Additional padding
    /// - Returns: True if text fits, false otherwise
    static func doesTextFitInVideo(
        text: String,
        videoWidth: CGFloat,
        fontSize: CGFloat,
        padding: CGFloat = 0
    ) -> Bool {
        let availableWidth = videoWidth - padding
        
        // Use improved character width estimation for system font with medium weight
        // Based on the app's consistent use of .systemFont(ofSize: fontSize, weight: .medium)
        let baseCharacterWidth = fontSize * 0.65 // Medium weight is slightly wider than regular
        let spaceWidth = fontSize * 0.25 // Spaces are narrower in medium weight
        
        // Calculate total width considering character types
        var totalWidth: CGFloat = 0
        for char in text {
            if char == " " {
                totalWidth += spaceWidth
            } else if char.isUppercase {
                totalWidth += baseCharacterWidth * 1.0 // Uppercase letters in medium weight
            } else if char.isLowercase {
                totalWidth += baseCharacterWidth * 0.75 // Lowercase letters are narrower
            } else if char.isNumber {
                totalWidth += baseCharacterWidth * 0.85 // Numbers are medium width
            } else {
                totalWidth += baseCharacterWidth * 0.5 // Punctuation and symbols are narrow
            }
        }
        
        // Check if the calculated width fits within available width
        let fits = totalWidth <= availableWidth
        
        if !fits {
            print("❌ [TextLayoutHelper] doesTextFitInVideo debug:")
            print("  text: '\(text)'")
            print("  videoWidth: \(videoWidth)")
            print("  fontSize: \(fontSize)")
            print("  padding: \(padding)")
            print("  availableWidth: \(availableWidth)")
            print("  calculatedWidth: \(totalWidth)")
            print("  fontFamily: System Font (Medium)")
        }
        
        return fits
    }
    

    
    /// Calculates the maximum font size that will fit the text in the video width
    /// - Parameters:
    ///   - text: The text to measure
    ///   - videoWidth: The width of the video
    ///   - maxFontSize: The maximum font size to try (defaults to 100)
    ///   - minFontSize: The minimum font size to try (defaults to 8)
    ///   - padding: Additional padding
    /// - Returns: The optimal font size
    static func calculateOptimalFontSize(
        text: String,
        videoWidth: CGFloat,
        maxFontSize: CGFloat = 100,
        minFontSize: CGFloat = 8,
        padding: CGFloat = 40
    ) -> CGFloat {
        
        let availableWidth = videoWidth - padding
        
        // Binary search for optimal font size
        var low = minFontSize
        var high = maxFontSize
        var optimalSize = minFontSize
        
        while low <= high {
            let mid = (low + high) / 2
            let estimatedTextWidth = CGFloat(text.count) * mid * 0.6
            
            if estimatedTextWidth <= availableWidth {
                optimalSize = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        
        return optimalSize
    }
} 