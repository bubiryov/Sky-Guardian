//
//  Extensions.swift
//  Sky Guardian
//
//  Created by Egor Bubiryov on 05.04.2024.
//

import SpriteKit

extension GameScene {
    func childNodesCount(name: String) -> Int {
        var count = 0
        enumerateChildNodes(withName: name) { _, _ in
            count += 1
        }
        return count
    }
    
    func wait(for duration: Float) -> SKAction {
        SKAction.wait(forDuration: TimeInterval(duration))
    }
}
