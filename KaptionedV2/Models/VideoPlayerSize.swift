//
//  VideoPlayerSize.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 14.04.2023.
//

import Foundation

// Enum for video player sizes
enum VideoPlayerSize: CaseIterable {
    case quarter, half, threeQuarters, full, custom
    
    var displayName: String {
        switch self {
        case .quarter: return "¼"
        case .half: return "½"
        case .threeQuarters: return "¾"
        case .full: return "Full"
        case .custom: return "Custom"
        }
    }
    
    var iconName: String {
        switch self {
        case .quarter: return "rectangle.compress.vertical"
        case .half: return "rectangle"
        case .threeQuarters: return "rectangle.expand.vertical"
        case .full: return "rectangle.fill"
        case .custom: return "rectangle.dashed"
        }
    }
} 