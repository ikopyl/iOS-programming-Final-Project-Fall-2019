//
//  GameScene.swift
//  pacman
//
//  Created by Ilya Kopyl on 12/30/19.
//  Copyright © 2019 Ilya Kopyl. All rights reserved.
//

import GameplayKit
import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    var pacman: SKSpriteNode?
    var cherryTimer: Timer?
    var ghostTimer: Timer?
    var ground: SKSpriteNode?
    var ceiling: SKSpriteNode?
    var scoreLabel: SKLabelNode?

    var yourScoreLabel: SKLabelNode?
    var finalScoreLabel: SKLabelNode?

    var score = 0

    let defaultMovingDuration = 4.0

    var objectMovingDuration: TimeInterval {
        switch score / 10 {
        case 0:
            return defaultMovingDuration
        case 1: // if score is 10..<20
            return defaultMovingDuration - 0.5
        case 2: // if score is 20..<30
            return defaultMovingDuration - 1.0
        case 3: // if score is 30..<40
            return defaultMovingDuration - 1.5
        case 4: // if score is 40..<50
            return defaultMovingDuration - 2.0
        case 5 ..< 10: // if score is 50..<100
            return defaultMovingDuration - 2.5
        default:
            return 1 // if score is >= 100
        }
    }

    // category bit masks
    let pacmanCategory: UInt32 = 0x1 << 1
    let cherryCategory: UInt32 = 0x1 << 2
    let ghostCategory: UInt32 = 0x1 << 3
    let groundAndCeilingCategory: UInt32 = 0x1 << 4

    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        initGameScene()
    }

    private func initGameScene() {
        addPacman()
        addGround()
        addCeiling()
        addScoreLabel()
        startTimers()
    }

    private func addPacman() {
        pacman = childNode(withName: "pacman") as? SKSpriteNode
        pacman?.physicsBody?.categoryBitMask = pacmanCategory
        pacman?.physicsBody?.contactTestBitMask = cherryCategory | ghostCategory
        pacman?.physicsBody?.collisionBitMask = groundAndCeilingCategory
        var pacmanRun: [SKTexture] = []
        for num in 1 ... 2 {
            pacmanRun.append(SKTexture(imageNamed: "frame-\(num)"))
        }

        let pacmanAnimation = SKAction.animate(with: pacmanRun, timePerFrame: 0.33)
        pacman?.run(SKAction.repeatForever(pacmanAnimation), withKey: "animation")
    }

    private func addGround() {
        ground = childNode(withName: "ground") as? SKSpriteNode
        ground?.physicsBody?.categoryBitMask = groundAndCeilingCategory
        ground?.physicsBody?.collisionBitMask = pacmanCategory
    }

    private func addCeiling() {
        ceiling = childNode(withName: "ceiling") as? SKSpriteNode
        ceiling?.physicsBody?.categoryBitMask = groundAndCeilingCategory
        ceiling?.physicsBody?.collisionBitMask = pacmanCategory
    }

    private func addScoreLabel() {
        scoreLabel = childNode(withName: "scoreLabel") as? SKLabelNode
    }

    private func startTimers() {
        cherryTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let isRendered = arc4random_uniform(4) > 0 ? true : false
            if isRendered {
                self.addCherry()
            }
        }

        ghostTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            let isRendered = arc4random_uniform(2) > 0 ? true : false
            if isRendered {
                self.addGhost()
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scene?.isPaused != true {
            pacman?.physicsBody?.applyForce(CGVector(dx: 0, dy: 100000))
        }

        let touch = touches.first
        if let touchLocation = touch?.location(in: self) {
            let selectedNodes = nodes(at: touchLocation)

            for node in selectedNodes {
                if node.name == "playButton" {
                    node.removeFromParent()
                    resetGame()
                }
            }
        }
    }

    private func addCherry() {
        addSpriteNode(name: "cherry", selectedCategoryBitMask: cherryCategory)
    }

    private func addGhost() {
        addSpriteNode(name: "ghost", selectedCategoryBitMask: ghostCategory)
    }

    private func addSpriteNode(name: String, selectedCategoryBitMask: UInt32) {
        let node = SKSpriteNode(imageNamed: name)
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        node.physicsBody?.affectedByGravity = false
        node.physicsBody?.categoryBitMask = selectedCategoryBitMask
        node.physicsBody?.contactTestBitMask = pacmanCategory
        node.physicsBody?.collisionBitMask = 0
        addChild(node)

        let maxY = size.height / 2 - node.size.height / 2
        let minY = -size.height / 2 + node.size.height / 2
        let range = maxY - minY
        let nodeY = maxY - CGFloat(arc4random_uniform(UInt32(range)))

        node.position = CGPoint(x: size.width / 2 + node.size.width / 2, y: nodeY)

        let moveLeft = SKAction.moveBy(x: -size.width - node.size.width, y: 0, duration: objectMovingDuration)
        let sequenceOfActions = SKAction.sequence([moveLeft, SKAction.removeFromParent()])
        node.run(sequenceOfActions)
    }

    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask == ghostCategory {
            contact.bodyA.node?.removeFromParent()
            gameOver()
            return
        }
        if contact.bodyB.categoryBitMask == ghostCategory {
            contact.bodyB.node?.removeFromParent()
            gameOver()
            return
        }

        if contact.bodyA.categoryBitMask == cherryCategory {
            contact.bodyA.node?.removeFromParent()
        }
        if contact.bodyB.categoryBitMask == cherryCategory {
            contact.bodyB.node?.removeFromParent()
        }

        score += 1
        scoreLabel?.text = "Score: \(score)"
    }

    private func gameOver() {
        scoreLabel?.isHidden = true

        scene?.isPaused = true

        cherryTimer?.invalidate()
        ghostTimer?.invalidate()

        yourScoreLabel = SKLabelNode(text: "Your Score:")
        yourScoreLabel?.position = CGPoint(x: 0, y: 200)
        yourScoreLabel?.fontSize = 75
        yourScoreLabel?.zPosition = 1
        addChild(yourScoreLabel!)

        finalScoreLabel = SKLabelNode(text: "\(score)")
        finalScoreLabel?.position = CGPoint(x: 0, y: 0)
        finalScoreLabel?.fontSize = 200
        finalScoreLabel?.zPosition = 1
        addChild(finalScoreLabel!)

        let playButton = SKSpriteNode(imageNamed: "play")
        playButton.position = CGPoint(x: 0, y: -200)
        playButton.name = "playButton"
        playButton.zPosition = 1
        addChild(playButton)
    }

    private func resetGame() {
        score = 0
        scoreLabel?.text = "Score: \(score)"
        scoreLabel?.isHidden = false

        yourScoreLabel?.removeFromParent()
        finalScoreLabel?.removeFromParent()

        scene?.isPaused = false
        startTimers()
    }
}
