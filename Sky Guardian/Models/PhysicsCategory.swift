//
//  PhysicsCategory.swift
//  Sky Guardian
//
//  Created by Egor Bubiryov on 31.03.2024.
//

import Foundation

struct PhysicsCategory {
  static let None: UInt32 = 0
  static let Ground: UInt32 = 0b1
  static let Player: UInt32 = 0b10
  static let Edge: UInt32 = 0b100
  static let Enemy: UInt32 = 0b10000
  static let DefenseMissile: UInt32 = 0b100000
}
