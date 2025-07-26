import CoreImage
import Foundation
import SwiftUI

struct FilterHelper {
    static func createFilters(mainFilter: CIFilter?, _ colorCorrection: ColorCorrection?) -> [CIFilter] {
        var filters = [CIFilter]()
        if let mainFilter {
            filters.append(mainFilter)
        }
        if let colorFilter = ColorFilterHelper.createColorFilter(colorCorrection) {
            filters.append(colorFilter)
        }
        return filters
    }
} 