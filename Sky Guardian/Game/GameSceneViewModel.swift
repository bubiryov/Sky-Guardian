//
//  GameSceneViewModel.swift
//  Sky Guardian
//
//  Created by Egor Bubiryov on 09.04.2024.
//

import GameController
import SpriteKit
import SwiftUI

class GameSceneViewModel: ObservableObject {
    
    @AppStorage("highscore") var highscore: Int = 0
    @Published var score: Int = 0
    @Published var isGameInProgress: Bool = false
    
    var shouldBeRestarted: Bool = false
    var remainingLives: Int = 5

    var playableRect: CGRect!
    var virtualController: GCVirtualController!
    var carPositionX: CGFloat = 0
        
    var background: SKSpriteNode!
    var scoreLabel: SKLabelNode!
    var ground: SKSpriteNode!
    var car: SKSpriteNode!
    var gun: SKSpriteNode!
    
    var lastRotationAngle: CGFloat = 0
    var direction: CGPoint = .zero
    var velocity: CGPoint = .zero
    
    var heartContainerNode: SKSpriteNode!
    var hearts: [SKSpriteNode] = []
    
    var defenseMissile: SKSpriteNode!
    var dangerObject: SKSpriteNode!
    var fightbomber: SKSpriteNode!
    
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    var shouldRotateDangerObject: Bool = true
}

// MARK: Did move functions

extension GameSceneViewModel {
    func didMoveSetup(_ scene: GameScene) {
        setupPlayableRect(scene)
        setupFirstPartNodes(scene)
    }
}

// MARK: Updating

extension GameSceneViewModel {
    func updatingActions(_ scene: GameScene) {
        moveCar()
        rotateGun()
        boundsDefenseMissileCheck(scene)
        
        if let scoreLabel {
            scoreLabel.text = "\(score)"
        }
        
        updateFallingRotation(
            node: dangerObject,
            shouldRotate: shouldRotateDangerObject)
        
        if let defenseMissile {
            move(sprite: defenseMissile, velocity: velocity)
        }
    }
}

// MARK: - Playable rectangle

extension GameSceneViewModel {
    
    private func setupPlayableRect(_ scene: GameScene) {
        let screenSize = UIScreen.main.bounds
        let maxAspectRatio: CGFloat = screenSize.width/screenSize.height
        let maxAspectRatioHeight = scene.size.width / maxAspectRatio
        let playableMargin: CGFloat = (scene.size.height
          - maxAspectRatioHeight)/2
        
        let width = scene.size.width
        let height = scene.size.height - playableMargin * 2
        
        playableRect = CGRect(x: 0, y: playableMargin, width: width, height: height)
        
        scene.physicsBody = SKPhysicsBody(edgeLoopFrom: playableRect)
        scene.physicsBody!.categoryBitMask = PhysicsCategory.Edge
    }
    
    private func debugDrawPlayableArea(_ scene: GameScene) {
        let shape = SKShapeNode(rect: playableRect)
        shape.strokeColor = SKColor.red
        shape.lineWidth = 4.0
        shape.zPosition = 10
        scene.addChild(shape)
    }
}

// MARK: - Virtual controller

extension GameSceneViewModel {
    private func setupVirtualController(_ scene: GameScene) {
        let controllerConfiguration = GCVirtualController.Configuration()
        
        controllerConfiguration.elements = [GCInputLeftThumbstick, GCInputRightThumbstick, GCInputButtonA]
                
        let controller = GCVirtualController(configuration: controllerConfiguration)
        
        controller.connect()
        virtualController = controller
        
        virtualController.controller?.extendedGamepad?.buttonA.valueChangedHandler = { [weak self] _, _, pressed in
            if pressed {
                guard let self else { return }
                self.shotGun(scene)
            }
        }
    }
}


// MARK: - Elements

extension GameSceneViewModel {
    private func setupFirstPartNodes(_ scene: GameScene) {
        createBackground(scene)
        createGround(scene)
    }
    
    func setupSecondPartNodes(_ scene: GameScene) {
        createCar(scene)
        createGun(scene)
        createHearts(scene)
        createScoreLabel(scene)
        spawnRandomEnemyObject(scene)
        setupVirtualController(scene)
    }
    
    // MARK: Background
    
    private func createBackground(_ scene: GameScene) {
        background = SKSpriteNode(imageNamed: "Background")
        background.name = "Background"
        background.anchorPoint = .zero
        background.size = scene.size
        background.zPosition = -1.0
        scene.addChild(background)
    }
    
    //  MARK: Hearts
                
    private func createHearts(_ scene: GameScene) {
        
        heartContainerNode = SKSpriteNode()
        heartContainerNode.name = "HeartContainer"
        
        if scene.childNodesCount(name: "HeartContainer") <= 0 {
            scene.addChild(heartContainerNode)
        }
        
        for i in 0..<remainingLives {
            let heart = SKSpriteNode(imageNamed: "Heart")
            
            heart.size = CGSize(width: 25, height: 20)
            
            heart.position = CGPoint(x: CGFloat(i) * (heart.size.width + 5), y: 0)
            
            heart.color = .gray
            heart.colorBlendFactor = 0.5
            
            heartContainerNode.addChild(heart)
            hearts.append(heart)
        }
        
        let totalWidth = CGFloat(remainingLives) * (hearts[0].size.width) + 30
        
        heartContainerNode.position = CGPoint(
            x: playableRect.maxX - totalWidth,
            y: playableRect.maxY - 30)
        
        heartContainerNode.zPosition = 15
    }
    
    private func loseLife(count: Int = 1) {
        
        remainingLives -= count
        
        for _ in 0..<max(0, count) {
            if remainingLives >= 0 && !hearts.isEmpty {
                let scaleAction = SKAction.scale(to: 0.5, duration: 0.1)
                let removeAction = SKAction.removeFromParent()
                let sequence = SKAction.sequence([scaleAction, removeAction])
                
                hearts[0].run(sequence)
                hearts.removeFirst()
            }
        }
    }
    
    // MARK: Score label
    
    private func createScoreLabel(_ scene: GameScene) {
        scoreLabel = SKLabelNode(fontNamed: "kongtext")
        scoreLabel.text = "\(score)"
        scoreLabel.fontColor = SKColor.black
        scoreLabel.fontSize = 30
        scoreLabel.zPosition = 150
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.position = CGPoint(
            x: playableRect.midX,
            y: playableRect.maxY - 30)
        
        scene.addChild(scoreLabel)
    }
    
    // MARK: Ground
    
    private func createGround(_ scene: GameScene) {
        ground = SKSpriteNode(imageNamed: "Ground")
        ground.name = "Ground"
        ground.anchorPoint = CGPoint(x: 0.5, y: 0)
        ground.size = CGSize(
            width: scene.size.width,
            height: scene.size.height / 5.5
        )
        ground.zPosition = 1
        ground.position = CGPoint(x: playableRect.midX, y: playableRect.minY)
        
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size, center: CGPoint(x: ground.frame.minX, y: ground.frame.midY - 10))
        ground.physicsBody!.categoryBitMask = PhysicsCategory.Ground
        ground.physicsBody!.affectedByGravity = false
        ground.physicsBody!.isDynamic = false
        ground.physicsBody!.restitution = 0.0
        
        scene.addChild(ground)
    }
    
    // MARK: Car
    
    private func createCar(_ scene: GameScene) {
        car = SKSpriteNode(imageNamed: "Car")
        car.name = "Car"
        car.anchorPoint = CGPoint(x: 0.5, y: 0)
        car.setScale(0.25)
        car.zPosition = 10
        car.position = CGPoint(
            x: playableRect.midX,
            y: ground.frame.maxY
        )
        
        car.physicsBody = SKPhysicsBody(rectangleOf: car.size, center: CGPoint(x: 0, y: car.size.height * 0.5))
        car.physicsBody!.categoryBitMask = PhysicsCategory.Player
        car.physicsBody!.collisionBitMask = PhysicsCategory.Edge | PhysicsCategory.Ground
        car.physicsBody!.contactTestBitMask = PhysicsCategory.Enemy
        car.physicsBody!.affectedByGravity = true
        car.physicsBody!.isDynamic = true
        
        scene.addChild(car)
    }
    
    private func moveCar() {
        guard isGameInProgress else { return }
        
        carPositionX = CGFloat ((virtualController?.controller?.extendedGamepad?.rightThumbstick.xAxis.value) ?? 0)
        
        if carPositionX > 0 {
            car.position.x += carPositionX * 5
        } else {
            car.position.x -= abs(carPositionX) * 5
        }
    }
    
    private func shakeCar(enemyShotPositionX: CGFloat) {
        let difference = car.position.x - enemyShotPositionX
        
        var impulseX: CGFloat = 30
        var impulseY: CGFloat = 50
        
        if abs(difference) > 50 {
            impulseX = impulseX - min(abs(difference) / 10, 20)
            impulseY = impulseY - min(abs(difference) / 20, 30)
        }
        
        if difference < 0 {
            impulseX *= -1
        }
        
        let impulse = CGVector(dx: impulseX, dy: impulseY)
        car.physicsBody?.applyImpulse(impulse)
    }
    
    //  MARK: Gun
    
    private func createGun(_ scene: GameScene) {
        gun = SKSpriteNode(imageNamed: "Gun")
        gun.setScale(1.3)
        gun.anchorPoint = CGPoint(x: 0, y: 0.5)
        gun.zPosition = -5
        gun.position = CGPoint(x: 0, y: 0)
        
        gun.physicsBody = SKPhysicsBody(rectangleOf: gun.size, center: CGPoint(x: gun.frame.midX, y: 0))
        gun.physicsBody!.categoryBitMask = PhysicsCategory.Player
        gun.physicsBody!.affectedByGravity = false
        gun.physicsBody!.isDynamic = false
        
        car.addChild(gun)
        
        let constraint = SKConstraint.positionX(SKRange(constantValue: 15), y: SKRange(constantValue: 180))
        
        gun.constraints = [constraint]
        
        direction = CGPoint(x: scene.frame.maxX, y: gun.position.y)
    }
    
    private func rotateGun() {
        guard
            isGameInProgress,
            let leftThumbstick = virtualController?.controller?.extendedGamepad?.leftThumbstick else { return }
        
        let x = CGFloat(leftThumbstick.xAxis.value)
        let y = max(CGFloat(leftThumbstick.yAxis.value), 0)
        
        if x != 0 || y != 0 {
            
            let angle = atan2(y, x)
            
            let rotateAction = SKAction.rotate(
                toAngle: angle,
                duration: 0.1)
            
            gun.run(rotateAction)
            lastRotationAngle = angle
            direction = CGPoint(x: cos(angle), y: sin(angle))
            
        } else {
            let rotateAction = SKAction.rotate(
                toAngle: lastRotationAngle,
                duration: 0.1)
            
            gun.run(rotateAction)
        }
    }
    
    private func shotGun(_ scene: GameScene) {
        guard
            defenseMissile == nil,
            isGameInProgress else { return }
        
        Haptics.shared.play(.soft)
        createDefenseMissile(scene)
        velocity = direction.normalized() * 800
    }
    
    //  MARK: Defense missile
    
    private func createDefenseMissile(_ scene: GameScene) {
        defenseMissile = SKSpriteNode(imageNamed: "Missile3")
        defenseMissile.name = "DefenseMissile"
        defenseMissile.zPosition = 4
        defenseMissile.zRotation = gun.zRotation - π/2
        defenseMissile.anchorPoint = CGPoint(x: 0.5, y: 0)
        defenseMissile.position = gun.convert(CGPoint.zero, to: scene)
        defenseMissile.size = CGSize(width: 7, height: 50)
        
        defenseMissile.physicsBody = SKPhysicsBody(rectangleOf: defenseMissile.size, center: CGPoint(x: 0, y: defenseMissile.size.height / 2))
        defenseMissile.physicsBody?.affectedByGravity = false
        defenseMissile.physicsBody?.isDynamic = true
        defenseMissile.physicsBody?.categoryBitMask = PhysicsCategory.DefenseMissile
        defenseMissile.physicsBody?.contactTestBitMask = PhysicsCategory.Enemy
        defenseMissile.physicsBody?.collisionBitMask = PhysicsCategory.None
        
        scene.addChild(defenseMissile)
    }
    
    private func boundsDefenseMissileCheck(_ scene: GameScene) {
        guard let defenseMissile else { return }
        boundsCheck(node: defenseMissile)
        let count = scene.childNodesCount(name: "DefenseMissile")
        if count <= 0 {
            self.defenseMissile = nil
        }
    }
}

// MARK: - Enemy

extension GameSceneViewModel {
    
    private func spawnRandomEnemyObject(_ scene: GameScene) {
        
        guard remainingLives > 0 else { return }
        
        let direction: EnemyMoveDirection = .allCases.randomElement()!
        let enemyObjectType: EnemyType = .allCases.randomElement()!
        
        let size: CGSize = {
            switch enemyObjectType {
            case .horizontalMissile:
                CGSize(width: 60, height: 15)
            case .ballisticMissile:
                CGSize(width: 10, height: 60)
            case .fightbomber:
                CGSize(width: 90, height: 25)
            case .drone:
                CGSize(width: 50, height: 40)
            }
        }()
        
        switch enemyObjectType {
        case .horizontalMissile, .drone:
            spawnMissileOrDrone(
                scene: scene,
                enemyObjectType: enemyObjectType,
                direction: direction,
                size: size)
        case .ballisticMissile:
            spawnBallisticMissile(scene: scene, size: size)
        case .fightbomber:
            spawnFightbomber(
                scene: scene,
                enemyObjectType: enemyObjectType,
                direction: direction,
                size: size)
        }
    }
    
    //  MARK: Missile or drone
    
    private func spawnMissileOrDrone(scene: GameScene, enemyObjectType: EnemyType, direction: EnemyMoveDirection, size: CGSize) {
        
        dangerObject = createHorizontalFlyingObject(
            objectType: enemyObjectType,
            direction: direction,
            size: size)
        
        dangerObject.xScale = direction == .left ? -1 : 1
        
        if enemyObjectType == .horizontalMissile {
            
            let position = CGPoint(
                x: -dangerObject.size.width / 2,
                y: 0)
            
            let size = CGSize(
                width: dangerObject.frame.height * 1.5,
                height: 20)
            
            if let fire = createFire(
                position: position,
                size: size,
                rotation: π / 2) {
                dangerObject.addChild(fire)
            }
        }
        
        scene.addChild(dangerObject)
        
        let attackAction = SKAction.run { [weak self] in
            self?.dangerObject.physicsBody!.affectedByGravity = true
            self?.dangerObject.physicsBody!.isDynamic = true
        }
        
        horizontalLaunchObject(
            scene: scene,
            node: dangerObject,
            direction: direction,
            attackAction: attackAction)
    }
    
    //  MARK: Fightbomber
    
    private func spawnFightbomber(scene: GameScene, enemyObjectType: EnemyType, direction: EnemyMoveDirection, size: CGSize) {
        
        fightbomber = createHorizontalFlyingObject(
            objectType: enemyObjectType,
            direction: direction,
            size: size)
        
        fightbomber.xScale = direction == .left ? -1 : 1
        
        scene.addChild(fightbomber)
        
        let attackAction = SKAction.run { [weak self] in
            self?.createAirBomb(scene)
        }
        
        horizontalLaunchObject(
            scene: scene,
            node: fightbomber,
            direction: direction,
            attackAction: attackAction)
        
        let removeAction = SKAction.run { [weak self] in
            self?.fightbomber.removeFromParent()
        }
        
        let spawnAction = SKAction.run { [weak self] in
            if scene.childNodesCount(name: "Enemy") == 0 {
                self?.spawnRandomEnemyObject(scene)
            }
        }
        
        let sequence = SKAction.sequence([scene.wait(for: 5), removeAction, spawnAction])
        
        fightbomber.run(sequence)
    }
    
    private func createAirBomb(_ scene: GameScene) {
        dangerObject = SKSpriteNode(imageNamed: "Bomb")
        dangerObject.position = fightbomber.position
        dangerObject.name = "Enemy"
        dangerObject.size = CGSize(width: 60, height: 15)
        dangerObject.xScale = fightbomber.xScale
        dangerObject.zPosition = 0
        
        dangerObject.physicsBody = SKPhysicsBody(
            rectangleOf: dangerObject.size,
            center: CGPoint(x: 0, y: 0)
        )
        dangerObject.physicsBody!.categoryBitMask = PhysicsCategory.Enemy
        dangerObject.physicsBody!.contactTestBitMask = PhysicsCategory.Ground | PhysicsCategory.Player | PhysicsCategory.DefenseMissile
        dangerObject.physicsBody!.collisionBitMask = PhysicsCategory.None
        dangerObject.physicsBody!.affectedByGravity = true
        dangerObject.physicsBody!.isDynamic = true
        
        dangerObject.physicsBody!.linearDamping = 5
        
        scene.addChild(dangerObject)
    }
    
    //  MARK: Ballistic
    
    private func spawnBallisticMissile(scene: GameScene, size: CGSize) {
        shouldRotateDangerObject = false
        dangerObject = SKSpriteNode(imageNamed: "Missile1")
        dangerObject.name = "Enemy"
        dangerObject.position = CGPoint(
            x: CGFloat.random(in: playableRect.minX + 50 ... playableRect.maxX - 50),
            y: playableRect.maxY * 2
        )
        
        dangerObject.size = size
        
        dangerObject.physicsBody = SKPhysicsBody(
            rectangleOf: dangerObject.size,
            center: CGPoint(x: 0, y: 0)
        )
        dangerObject.physicsBody!.categoryBitMask = PhysicsCategory.Enemy
        dangerObject.physicsBody!.collisionBitMask = PhysicsCategory.None
        dangerObject.physicsBody!.contactTestBitMask = PhysicsCategory.Ground | PhysicsCategory.Player  | PhysicsCategory.DefenseMissile
        dangerObject.physicsBody!.affectedByGravity = true
        dangerObject.physicsBody!.isDynamic = true
        
        dangerObject.physicsBody!.linearDamping = 8
        
        scene.addChild(dangerObject)
    }
    
    //  MARK: General horizontal object functions
    
    private func createHorizontalFlyingObject(objectType: EnemyType, direction: EnemyMoveDirection, size: CGSize) -> SKSpriteNode {
        shouldRotateDangerObject = true
        
        let object = SKSpriteNode(imageNamed: objectType.rawValue)
        
        object.position = CGPoint(
            x: direction == .left ? playableRect.maxX + object.size.width / 2 : playableRect.minX - object.size.width / 2,
            y: CGFloat.random(in: playableRect.midY ... playableRect.maxY)
        )
        
        object.zPosition = 10
        object.size = size
        object.name = "Enemy"
        
        object.physicsBody = SKPhysicsBody(
            rectangleOf: object.size,
            center: CGPoint(x: 0, y: 0)
        )
        object.physicsBody!.categoryBitMask = PhysicsCategory.Enemy
        object.physicsBody!.collisionBitMask = PhysicsCategory.None
        object.physicsBody!.contactTestBitMask = PhysicsCategory.Ground | PhysicsCategory.Player | PhysicsCategory.DefenseMissile
        object.physicsBody!.affectedByGravity = false
        object.physicsBody!.isDynamic = true
        
        object.physicsBody!.linearDamping = 5
        
        return object
    }
    
    private func horizontalLaunchObject(scene: GameScene, node: SKSpriteNode, direction: EnemyMoveDirection, attackAction: SKAction? = nil) {
        let flyingAction = SKAction.moveTo(
            x: direction == .right ? playableRect.maxX + 50 : playableRect.minX - 50 ,
            duration: 5)
        
        let randomAtack = Float.random(in: 2...3.5)
                        
        let sequence: SKAction = {
            attackAction == nil ? SKAction.sequence([scene.wait(for: randomAtack)]) : SKAction.sequence([scene.wait(for: randomAtack), attackAction!])
        }()
        
        let launchAction = SKAction.group([flyingAction, sequence])
        
        node.run(launchAction)
    }
}

// MARK: - Explosions

extension GameSceneViewModel {
    
    private func createExplosion(scene: GameScene, name: String, size: CGSize, position: CGPoint, anchorPoint: CGPoint) {
        let explosionNode = SKSpriteNode(imageNamed: name)
        explosionNode.position = position
        explosionNode.anchorPoint = anchorPoint
        explosionNode.size = size
        explosionNode.setScale(0.5)
        explosionNode.zPosition = 0
        
        let appearScaleAction = SKAction.scale(to: 1.0, duration: 0.1)
        let disappearScaleAction = SKAction.scale(to: 0.5, duration: 0.1)
        let removingAction = SKAction.removeFromParent()

        let sequence = SKAction.sequence([
            appearScaleAction,
            scene.wait(for: 1),
            disappearScaleAction,
            removingAction])
        
        scene.addChild(explosionNode)
        
        explosionNode.run(sequence)
    }
}

// MARK: Fire

extension GameSceneViewModel {

    private func createFire(position: CGPoint, size: CGSize, rotation: CGFloat? = nil) -> SKEmitterNode? {
        if let fire = SKEmitterNode(fileNamed: "Fire") {
            
            fire.particleSize = size
            fire.particleSpeed = 120
            
            if let rotation {
                fire.zRotation = rotation
            }
            
            fire.zPosition = -1
            fire.position = position
            
            return fire
        }
        return nil
    }
}

// MARK: Contact handling

extension GameSceneViewModel {
    
    func enemyShotDown(scene: GameScene, enemyNode: SKSpriteNode?) {
        createExplosion(
            scene: scene,
            name: "Air Explosion",
            size: CGSize(width: 55, height: 50),
            position: enemyNode!.position,
            anchorPoint: CGPoint(x: 0.5, y: 0.5))
        
        Haptics.shared.play(.medium)
        enemyNode!.removeFromParent()
        defenseMissile.removeFromParent()
        
        if isGameInProgress {
            score += 1
        }
                
        let spawn = SKAction.run { [weak self] in
            self?.spawnRandomEnemyObject(scene)
        }
        
        let sequence = SKAction.sequence([scene.wait(for: 1), spawn])
        
        if scene.childNodesCount(name: "Enemy") == 0 {
            scene.run(sequence)
        }
    }
    
    func enemyMissed(scene: GameScene, enemyNode: SKSpriteNode?) {
        let explosionPosition = CGPoint(
            x: enemyNode!.position.x,
            y: ground.frame.maxY)

        createExplosion(
            scene: scene,
            name: "Ground Explosion",
            size: CGSize(width: 95, height: 90),
            position: explosionPosition,
            anchorPoint: CGPoint(x: 0.5, y: 0))
        
        Haptics.shared.play(.heavy)
        enemyNode!.removeFromParent()
        loseLife()
        
        if remainingLives <= 0 {
            playerDestroyed()
        } else {
            shakeCar(enemyShotPositionX: explosionPosition.x)
        }
        
        let spawn = SKAction.run { [weak self] in
            self?.spawnRandomEnemyObject(scene)
        }
        
        let sequence = SKAction.sequence([scene.wait(for: 1), spawn])
                        
        let size = CGSize(
            width: 95,
            height: 30)
        
        if let fire = createFire(
            position: explosionPosition,
            size: size) {
            scene.addChild(fire)
        }
        
        if scene.childNodesCount(name: "Enemy") == 0 {
            scene.run(sequence)
        }
    }
    
    func playerDestroyed() {
        isGameInProgress = false
        loseLife(count: remainingLives)
        car.physicsBody?.applyAngularImpulse(0.15)
        virtualController.disconnect()
        scoreLabel.isHidden = true
        
        if score > highscore {
            highscore = score
        }
    }
}

// MARK: - Functions

extension GameSceneViewModel {
    private func move(sprite: SKSpriteNode, velocity: CGPoint) {
      let amountToMove = velocity * CGFloat(dt)
      sprite.position += amountToMove
    }
    
    private func boundsCheck(node: SKNode) {
        if !playableRect.contains(node.position) {
            node.removeFromParent()
        }
    }
    
    private func updateFallingRotation(node: SKSpriteNode?, shouldRotate: Bool) {
        guard let node, shouldRotate else { return }
        
        let angle: CGFloat
        
        if node.xScale < 0 {
            angle = atan2(-node.physicsBody!.velocity.dy, node.physicsBody!.velocity.dx)
        } else {
            angle = atan2(node.physicsBody!.velocity.dy, node.physicsBody!.velocity.dx)
        }
        
        var limitedAngle = angle
        
        if angle > CGFloat.pi / 4 {
            limitedAngle = CGFloat.pi / 4
        } else if angle < -CGFloat.pi / 4 {
            limitedAngle = -CGFloat.pi / 4
        }

        node.physicsBody!.angularVelocity = limitedAngle
    }
    
    func createNewScene() -> GameScene {
        let newScene = GameScene(viewModel: self)
        newScene.size = CGSize(
            width: UIScreen.main.bounds.width,
            height: UIScreen.main.bounds.height
        )
        newScene.scaleMode = .aspectFit

        return newScene
    }
    
    func resetGameProperies() {
        carPositionX = 0
        lastRotationAngle = 0
        direction = .zero
        velocity = .zero
        
        remainingLives = 5
        score = 0
        
        lastUpdateTime = 0
        dt = 0
        shouldRotateDangerObject = true

        virtualController = nil
        hearts = []
    }
}
