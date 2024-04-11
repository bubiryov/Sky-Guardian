//
//  Haptics.swift
//  Sky Guardian
//
//  Created by Egor Bubiryov on 09.04.2024.
//

import SwiftUI

class Haptics {
    static let shared = Haptics()
    
    private init() { }

    func play(_ feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: feedbackStyle).impactOccurred()
    }
}
