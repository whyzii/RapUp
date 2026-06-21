//
//  HapticManager.swift
//  writeV1
//
//  Created by Yousefzadeh Abbas on 09/12/25.
//

import UIKit

class HapticManager {
    static let shared = HapticManager()
    
    // The "Thud" you feel when dropping an item (Heavy)
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // A lighter "Tap" for small interactions
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}
