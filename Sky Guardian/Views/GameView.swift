//
//  GameView.swift
//  Sky Guardian
//
//  Created by Egor Bubiryov on 08.04.2024.
//

import SwiftUI
import SpriteKit

struct GameView: View {
            
    @StateObject private var viewModel: GameSceneViewModel = .init()
    @State private var gameHasBeenStarted: Bool = false
    
    private var scene: GameScene {
        let scene = GameScene(viewModel: viewModel)
        scene.size = CGSize(
            width: UIScreen.main.bounds.width,
            height: UIScreen.main.bounds.height
        )
        scene.scaleMode = .aspectFit
        return scene
    }
        
    var body: some View {
        contentView()
    }
}

#Preview {
    GameView()
}

// MARK: Components

extension GameView {
    
    func contentView() -> some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()
            
            resultBoard()
        }
        .animation(.spring(duration: 0.2), value: viewModel.isGameInProgress)
    }
    
    @ViewBuilder
    func resultBoard() -> some View {
        if !viewModel.isGameInProgress {
            ResultsBoard(
                score: viewModel.score,
                highscore: viewModel.highscore,
                restart: gameHasBeenStarted) {
                    playButtonAction()
                }
                .transition(.move(edge: .top))
        }
    }
}

// MARK: Functions

extension GameView {
    func playButtonAction() {
        if !gameHasBeenStarted {
            viewModel.isGameInProgress = true
            gameHasBeenStarted = true
        } else {
            viewModel.shouldBeRestarted = true
            viewModel.isGameInProgress = true
        }
    }
}
