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
        case .presets: return "Presets"
        }
    }
    
    var image: String{
        switch self {
        case .subslist: return "list.bullet"
        case .presets: return "camera.filters"
        }
    }
    
    var timeState: TimeLineViewState{
        return .empty
        // switch self{
        // //case .audio: return .audio
        // case .text: return .text
        // default: return .empty
        // }
    }
}
    

