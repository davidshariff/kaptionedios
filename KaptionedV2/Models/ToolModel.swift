//
//  ToolModel.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 20.04.2023.
//

import Foundation


enum ToolEnum: Int, CaseIterable{
    case presets, subslist
    
    
    var title: String{
        switch self {
        case .subslist: return "Subslist"
        case .presets: return "Templates"
        }
    }
    
    var image: String{
        switch self {
        case .subslist: return "list.bullet"
        case .presets: return "camera.filters"
        }
    }
    
    // Removed timeState property as TimeLineView is no longer used
}
    

