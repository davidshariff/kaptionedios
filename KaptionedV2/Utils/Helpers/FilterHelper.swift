import CoreImage
import Foundation
import SwiftUI

struct FilterHelper {
    static func createFilters(mainFilter: CIFilter?, _: Any?) -> [CIFilter] {
        var filters = [CIFilter]()
        if let mainFilter {
            filters.append(mainFilter)
        }
        return filters
    }
}
