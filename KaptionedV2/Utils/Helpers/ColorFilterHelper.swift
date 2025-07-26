import CoreImage
import Foundation
import SwiftUI
// If you get 'Cannot find type' errors, ensure this file is in the same target as FilteredImage.swift in Xcode.
// All types in the same target are visible in Swift. If not, check target membership in Xcode.

struct ColorFilterHelper {
    static func createColorFilter(_ colorCorrection: ColorCorrection?) -> CIFilter? {
        guard let colorCorrection else { return nil }
        let colorCorrectionFilter = CIFilter(name: "CIColorControls")
        colorCorrectionFilter?.setValue(colorCorrection.brightness, forKey: CorrectionType.brightness.key)
        colorCorrectionFilter?.setValue(colorCorrection.contrast + 1, forKey: CorrectionType.contrast.key)
        colorCorrectionFilter?.setValue(colorCorrection.saturation + 1, forKey: CorrectionType.saturation.key)
        return colorCorrectionFilter
    }
} 