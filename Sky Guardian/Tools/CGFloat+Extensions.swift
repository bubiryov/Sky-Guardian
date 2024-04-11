//
//  CGFloat+Extensions.swift
//  Sky Guardian
//
//  Created by Egor Bubiryov on 01.04.2024.
//

import CoreGraphics

let π = CGFloat(Double.pi)

public extension CGFloat {
    
    func degreesToRadians() -> CGFloat {
        return π * self / 180.0
    }
    
    func sign() -> CGFloat {
      return self >= 0.0 ? 1.0 : -1.0
    }
}

public func shortestAngleBetween(angle1: CGFloat, angle2: CGFloat) -> CGFloat {
    let twoπ = π * 2.0
    var angle = (angle2 - angle1).truncatingRemainder(dividingBy: twoπ)
    if (angle >= π) {
        angle = angle - twoπ
    }
    if (angle <= -π) {
        angle = angle + twoπ
    }
    return angle
}
