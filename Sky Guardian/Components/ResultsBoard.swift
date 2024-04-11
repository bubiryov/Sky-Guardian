//
//  ResultsBoard.swift
//  Sky Guardian
//
//  Created by Egor Bubiryov on 08.04.2024.
//

import SwiftUI

struct ResultsBoard: View {
    
    let score: Int
    let highscore: Int
    let restart: Bool
    let playAction: (() -> ())
    
    private let boardWidth: CGFloat = UIScreen.main.bounds.width / 2.4

    init(score: Int, highscore: Int, restart: Bool, playAction: @escaping () -> ()) {
        self.score = score
        self.highscore = highscore
        self.restart = restart
        self.playAction = playAction
    }
        
    var body: some View {
        ZStack {
            Image(.board)
                .resizable()
                .aspectRatio(contentMode: .fit)
            
            VStack {
                
                VStack(spacing: 30) {
                    scoreRow(title: "Highscore", score: highscore)
                    
                    if restart {
                        scoreRow(title: "Score", score: score)
                    }
                }
                                
                Spacer()
                
                Button {
                    playAction()
                } label: {
                    Image(restart ? .restart : .play)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: boardWidth / 5.5)
                }
            }
            .font(.custom("kongtext", size: boardWidth / 16))
            .foregroundColor(.white)
            .padding(30)
            .padding(.trailing, 5)
        }
        .frame(width: boardWidth, height: boardWidth / 1.337)
    }
}

#Preview {
    ResultsBoard(score: 25, highscore: 60, restart: true) { }
}

extension ResultsBoard {
    func scoreRow(title: String, score: Int) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(score)")
        }
    }
}
