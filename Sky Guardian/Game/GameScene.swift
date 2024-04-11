//
//  GameScene.swift
//  Sky Guardian
//
//  Created by Egor Bubiryov on 31.03.2024.
//

import SpriteKit
import Combine

class GameScene: SKScene, ObservableObject {
    
    var viewModel: GameSceneViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: GameSceneViewModel) {
        self.viewModel = viewModel
        super.init(size: CGSize(width: 0, height: 0))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        viewModel.didMoveSetup(self)
        subscribeToGameProgress()
    }
}

// MARK: - Game loop

extension GameScene {
    
    override func update(_ currentTime: TimeInterval) {
        
        viewModel.updatingActions(self)
        
        if viewModel.lastUpdateTime > 0 {
            viewModel.dt = currentTime - viewModel.lastUpdateTime
        } else {
            viewModel.dt = 0
        }
        viewModel.lastUpdateTime = currentTime
    }
}

// MARK: - Contact detection

extension GameScene: SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        let enemyNode = contact.bodyA.categoryBitMask == PhysicsCategory.Enemy ? contact.bodyA.node : contact.bodyB.node
        
        switch collision {
        case PhysicsCategory.Enemy | PhysicsCategory.DefenseMissile:
            viewModel.enemyShotDown(
                scene: self,
                enemyNode: enemyNode as? SKSpriteNode)
        case PhysicsCategory.Enemy | PhysicsCategory.Ground:
            viewModel.enemyMissed(
                scene: self,
                enemyNode: enemyNode as? SKSpriteNode)
        case PhysicsCategory.Enemy | PhysicsCategory.Player:
            viewModel.playerDestroyed()
        default:
            return
        }
    }    
}

// MARK: - Game restart

extension GameScene {
    private func subscribeToGameProgress() {
        viewModel.$isGameInProgress
            .sink { [weak self] in
                guard let self else { return }
                
                if $0 {
                    if viewModel.shouldBeRestarted {
                        restartGame()
                    } else {
                        self.viewModel.setupSecondPartNodes(self)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func restartGame() {
        cancelPreviousSubscriptions()
        viewModel.resetGameProperies()
        
        let newScene = viewModel.createNewScene()
        scene?.view?.presentScene(newScene)
        
        self.viewModel.setupSecondPartNodes(newScene)
    }
    
    private func cancelPreviousSubscriptions() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
