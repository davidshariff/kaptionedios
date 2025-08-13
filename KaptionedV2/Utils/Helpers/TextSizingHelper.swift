/*
 TextSizingHelper.swift
 ----------------------
 Purpose:
   - Breaks a list of words with timings into single-line subtitle segments that fit within a given display width.
   - Ensures consistent font size across all segments for visual consistency.
   - Optionally enforces a minimum display duration for short cues.

 How it works:
   1. Receives:
      - An array of WordWithTiming (text, start, end times).
      - The available width for text (after scaling the video).
      - A base font size to test against.
      - Flags to control whether short cues should be expanded in duration.

   2. Builds segments:
      - Joins words into one-line blocks until adding another word would exceed the width limit.
      - Measures the text using the base font size to ensure it fits.
      - Keeps start/end times based on first and last word in the block.

   3. Duration adjustment (optional):
      - If `expandShortCues` is true, short cues are extended to `minDur` seconds.
      - If false, original timings are kept.

   4. Logging:
      - Prints detailed logs when a segment is adjusted.
      - Prints minimal logs when no changes are needed.
      - Ends with the suggested font size that fits all segments.

 Use case:
   - Perfect for subtitle rendering on scaled videos where you want:
       * Consistent font size.
       * One line of text per segment.
       * Optional minimum display time to improve readability.
*/

import UIKit

struct TimedSegment {
    let text: String
    let start: Double
    let end: Double
}

// MARK: - Debug stats (for minimal, change-focused logs)

private struct DebugStats {
    var splits: Int = 0
    var lineBreaks: Int = 0
    var durationAdjusted: Int = 0
}

// MARK: - Measurement

private func measureWidth(_ text: String, font: UIFont) -> CGFloat {
    let attr: [NSAttributedString.Key: Any] = [.font: font]
    let bounds = (text as NSString).boundingRect(
        with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: attr,
        context: nil
    )
    return ceil(bounds.width)
}

// Visible characters (exclude whitespace) for CPS calculations
private func visibleCharCount(_ s: String) -> Int {
    s.unicodeScalars.filter { !CharacterSet.whitespacesAndNewlines.contains($0) }.count
}

// MARK: - Token normalization

// Trim each token; drop empty tokens produced by pure whitespace
private func normalizeTokens(_ words: [WordWithTiming]) -> [WordWithTiming] {
    words.compactMap { w in
        let t = w.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return nil }
        return WordWithTiming(text: t, start: w.start, end: w.end)
    }
}

// MARK: - Long-word handling

// Split a single overly-long word into smaller chunks that each fit maxWidth
private func explodeLongWord(
    _ word: WordWithTiming,
    font: UIFont,
    maxWidth: CGFloat,
    stats: inout DebugStats
) -> [WordWithTiming] {
    if measureWidth(word.text, font: font) <= maxWidth { return [word] }

    print("✂️ Splitting long word: '\(word.text)'")
    stats.splits += 1

    let chars = Array(word.text)
    guard !chars.isEmpty else { return [word] }
    
    var parts: [String] = []
    var current = ""
    for ch in chars {
        let candidate = current + String(ch)
        if measureWidth(candidate, font: font) <= maxWidth || current.isEmpty {
            current = candidate
        } else {
            parts.append(current)
            current = String(ch)
        }
    }
    if !current.isEmpty { parts.append(current) }
    
    let totalCount = max(1, chars.count)
    var accStart = word.start
    var result: [WordWithTiming] = []
    
    for (i, p) in parts.enumerated() {
        let fraction = Double(p.count) / Double(totalCount)
        let dur = (word.end - word.start) * fraction
        let seg = WordWithTiming(text: p, start: accStart, end: accStart + dur)
        print("   → Part: '\(p)' \(String(format: "%.2f", seg.start)) → \(String(format: "%.2f", seg.end))")
        result.append(seg)
        accStart += dur
        if i == parts.count - 1 {
            result[result.count - 1] = WordWithTiming(text: p, start: result.last!.start, end: word.end)
        }
    }
    return result
}

// Ensure every token fits alone within maxWidth (after trimming)
private func preprocessWords(
    _ words: [WordWithTiming],
    font: UIFont,
    maxWidth: CGFloat,
    stats: inout DebugStats
) -> [WordWithTiming] {
    let normalized = normalizeTokens(words)
    var out: [WordWithTiming] = []
    for w in normalized {
        out.append(contentsOf: explodeLongWord(w, font: font, maxWidth: maxWidth, stats: &stats))
    }
    return out
}

// MARK: - Pack into single-line ranges

private func packSegments(
    words: [WordWithTiming],
    font: UIFont,
    maxWidth: CGFloat,
    joiner: String,
    stats: inout DebugStats
) -> [(Int, Int)] {
    guard !words.isEmpty else { return [] }
    var segments: [(Int, Int)] = []
    var startIdx = 0
    var lineText = words[0].text
    
    for i in 1..<words.count {
        let candidate = lineText + joiner + words[i].text
        if measureWidth(candidate, font: font) <= maxWidth {
            lineText = candidate
        } else {
            print("📏 Line break at: '\(lineText)'")
            stats.lineBreaks += 1
            segments.append((startIdx, i - 1))
            startIdx = i
            lineText = words[i].text
        }
    }
    segments.append((startIdx, words.count - 1))
    return segments
}

// MARK: - Map index ranges to timed segments

private func segmentsWithTime(
    segments: [(Int, Int)],
    words: [WordWithTiming],
    joiner: String
) -> [TimedSegment] {
    segments.map { (startIdx, endIdx) -> TimedSegment in
        let slice = words[startIdx...endIdx]
        let text = slice.map(\.text).joined(separator: joiner)
        return TimedSegment(text: text, start: slice.first!.start, end: slice.last!.end)
    }
}

// MARK: - Timing normalization
/// - Parameters:
///   - expandShortCues: if false, will NOT lengthen short raw durations to minDur; keeps raw unless slack exists.
///   - sentenceWindow: optional hard window (start,end) to keep segments within the sentence bounds.
private func normalizeTiming(
    segments: [TimedSegment],
    targetCPS: Double,
    minDur: Double,
    maxDur: Double,
    gap: Double,
    expandShortCues: Bool,
    sentenceWindow: (start: Double, end: Double)?,
    stats: inout DebugStats
) -> [TimedSegment] {
    guard !segments.isEmpty else { return [] }
    var out = segments

    let hardStart = sentenceWindow?.start ?? segments.first!.start
    let hardEnd   = sentenceWindow?.end   ?? segments.last!.end
    
    // Desired end for each segment based on CPS & min/max
    var desiredEnds = [Double](repeating: 0, count: segments.count)

    for i in 0..<segments.count {
        let s = segments[i]
        let rawDur = s.end - s.start

        // CPS based on visible chars (no spaces)
        let chars = max(1, visibleCharCount(s.text))
        let ideal = Double(chars) / targetCPS

        var dur = min(maxDur, max(minDur, ideal))
        if !expandShortCues && dur > rawDur {
            dur = rawDur // keep original short duration if expansion is disallowed
        }
        desiredEnds[i] = s.start + dur
    }

    // Enforce ordering, gap, and sentence window (no overlaps)
    for i in 0..<out.count {
        let nextStart = (i + 1 < out.count) ? out[i + 1].start : min(desiredEnds[i], hardEnd)
        let maxEndByNext = nextStart - gap
        let maxEndByWindow = hardEnd - (i + 1 < out.count ? 0 : 0) // keep last inside window
        let targetEnd = min(desiredEnds[i], maxEndByNext, maxEndByWindow)

        let originalDur = out[i].end - out[i].start
        let newEnd = max(out[i].start, targetEnd)
        let newDur = newEnd - out[i].start

        if abs(newDur - originalDur) > 0.05 {
            print("⏱ Adjust '\(out[i].text)' \(String(format: "%.2f", originalDur))s → \(String(format: "%.2f", newDur))s")
            stats.durationAdjusted += 1
        }
        out[i] = TimedSegment(text: out[i].text, start: out[i].start, end: newEnd)
    }

    return out
}

// MARK: - Public pipeline

/// Fixed-font, single-line packing of one sentence's word-timings.
/// - Parameters:
///   - words: word-level timings for a single sentence
///   - font: the constant font used for layout
///   - maxWidth: usable width inside displayed video rect
///   - joiner: " " for Latin, "" for CJK
///   - targetCPS: typical 14–16 on mobile
///   - minDur / maxDur: reading bounds; minDur is only enforced if `expandShortCues == true`
///   - gap: minimal gap between segments
///   - expandShortCues: set to true only if you deliberately want to lengthen very short cues
///   - sentenceWindow: pass your TextBox.timeRange to strictly bound within the sentence times
func buildSingleLineTimedSegments(
    words: [WordWithTiming],
    font: UIFont,
    maxWidth: CGFloat,
    joiner: String = " ",
    targetCPS: Double = 15,
    minDur: Double = 1.0,
    maxDur: Double = 4.5,
    gap: Double = 0.08,
    expandShortCues: Bool = false,
    sentenceWindow: (start: Double, end: Double)? = nil
) -> [TimedSegment] {
    var stats = DebugStats()

    // 1) preprocess (trim + split long tokens)
    let pre = preprocessWords(words, font: font, maxWidth: maxWidth, stats: &stats)

    // 2) pack by width
    let ranges = packSegments(words: pre, font: font, maxWidth: maxWidth, joiner: joiner, stats: &stats)

    // 3) map to timed segments
    let timed = segmentsWithTime(segments: ranges, words: pre, joiner: joiner)

    // 4) normalize timing (do not lengthen short cues by default)
    let normalized = normalizeTiming(
        segments: timed,
        targetCPS: targetCPS,
        minDur: minDur,
        maxDur: maxDur,
        gap: gap,
        expandShortCues: expandShortCues,
        sentenceWindow: sentenceWindow,
        stats: &stats
    )

    // One-line summary + font used
    print("🔎 Summary: splits=\(stats.splits), breaks=\(stats.lineBreaks), adjusted=\(stats.durationAdjusted) | font=\(String(format: "%.2f", font.pointSize))pt")
    return normalized
}

/// Creates TextBox objects directly from word timings, preserving original styling
/// - Parameters:
///   - originalTextBox: The source TextBox to copy styling from
///   - font: The font to use for layout calculations
///   - maxWidth: Maximum width for text fitting
///   - joiner: Text joiner (" " for Latin, "" for CJK)
///   - targetCPS: Characters per second target
///   - minDur/maxDur: Duration bounds
///   - gap: Gap between segments
///   - expandShortCues: Whether to expand short cues
/// - Returns: Array of TextBox objects with proper styling and timing
func buildTextBoxesFromWordTimings(
    originalTextBox: TextBox,
    font: UIFont,
    maxWidth: CGFloat,
    joiner: String = " ",
    targetCPS: Double = 15,
    minDur: Double = 0.1,
    maxDur: Double = 4.5,
    gap: Double = 0.08,
    expandShortCues: Bool = false
) -> [TextBox] {
    guard let words = originalTextBox.wordTimings, !words.isEmpty else {
        // No word timings, return original with updated font size
        var updatedTextBox = originalTextBox
        updatedTextBox.fontSize = font.pointSize
        return [updatedTextBox]
    }
    
    // Get the timed segments
    let segments = buildSingleLineTimedSegments(
        words: words,
        font: font,
        maxWidth: maxWidth,
        joiner: joiner,
        targetCPS: targetCPS,
        minDur: minDur,
        maxDur: maxDur,
        gap: gap,
        expandShortCues: expandShortCues,
        sentenceWindow: (originalTextBox.timeRange.lowerBound, originalTextBox.timeRange.upperBound)
    )

    print("--------------------------------")
    print("!!!!!!!! Font point size: \(font.pointSize)")
    print("--------------------------------")
    
    // Convert segments to TextBox objects, preserving all original styling
    return segments.map { segment in
        TextBox(
            text: segment.text,
            fontSize: font.pointSize,
            lastFontSize: originalTextBox.lastFontSize,
            bgColor: originalTextBox.bgColor,
            fontColor: originalTextBox.fontColor,
            strokeColor: originalTextBox.strokeColor,
            strokeWidth: originalTextBox.strokeWidth,
            timeRange: segment.start...segment.end,
            offset: originalTextBox.offset,
            lastOffset: originalTextBox.lastOffset,
            backgroundPadding: originalTextBox.backgroundPadding,
            cornerRadius: originalTextBox.cornerRadius,
            shadowColor: originalTextBox.shadowColor,
            shadowRadius: originalTextBox.shadowRadius,
            shadowX: originalTextBox.shadowX,
            shadowY: originalTextBox.shadowY,
            shadowOpacity: originalTextBox.shadowOpacity,
            wordTimings: words, // Keep all original words
            isKaraokePreset: originalTextBox.isKaraokePreset,
            karaokeType: originalTextBox.karaokeType,
            highlightColor: originalTextBox.highlightColor,
            wordBGColor: originalTextBox.wordBGColor,
            activeWordScale: originalTextBox.activeWordScale,
            presetName: originalTextBox.presetName
        )
    }
}

/// Processes all TextBoxes from an EditorViewModel, calculating optimal layout automatically
/// - Parameters:
///   - editorVM: The EditorViewModel containing the video and text boxes
///   - joiner: Text joiner (" " for Latin, "" for CJK)
///   - targetCPS: Characters per second target
///   - minDur/maxDur: Duration bounds
///   - gap: Gap between segments
///   - expandShortCues: Whether to expand short cues
/// - Returns: Array of optimized TextBox objects
func processTextBoxesForLayout(
    subs: [TextBox],
    editorVM: EditorViewModel,
    joiner: String = " ",
    targetCPS: Double = 15,
    minDur: Double = 0.5,
    maxDur: Double = 4.5,
    gap: Double = 0.08,
    expandShortCues: Bool = false
) -> [TextBox] {
    
    // Get video rect and calculate font size and max width automatically
    let videoRect = editorVM.videoRect
    let fontSize = videoRect.height * 0.055
    let font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
    let maxWidth = videoRect.width * 0.92
    let textBoxes = subs
    
    print("--------------------------------")
    print("🎬 Video Player Size: \(editorVM.videoPlayerSize)")
    print("📝 Video Rect: \(videoRect)")
    print("📝 Font Size: \(fontSize)")
    print("📝 Max Width: \(maxWidth)")
    print("--------------------------------")
    
    var processedTextBoxes: [TextBox] = []
    
    for textBox in textBoxes {
        let wordCount = textBox.wordTimings?.count ?? 0
        print("🔍 Processing textBox: '\(textBox.text)' with \(wordCount) words")
        
        let newBoxes = buildTextBoxesFromWordTimings(
            originalTextBox: textBox,
            font: font,
            maxWidth: maxWidth,
            joiner: joiner,
            targetCPS: targetCPS,
            minDur: minDur,
            maxDur: maxDur,
            gap: gap,
            expandShortCues: expandShortCues
        )
        
        print("📊 Result: \(newBoxes.count) text boxes from \(wordCount) words")
        processedTextBoxes.append(contentsOf: newBoxes)
    }
    
    return processedTextBoxes
}
