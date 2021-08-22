//
//  DinoScene.swift
//  Dino
//
//  Created by Yuhui Li on 2016-11-22.
//  Copyright © 2016 Yuhui Li. All rights reserved.
//

import Cocoa
import SpriteKit

struct PhysicsCategory {
    static let None: UInt32 = 0
    static let All: UInt32 = UInt32.max
    static let Edge: UInt32 = 0b1
    static let Character: UInt32 = 0b10
    static let Collider: UInt32 = 0b100
    static let Obstacle: UInt32 = 0b1000
}

class ObSpriteNode: SKSpriteNode {
    var role: Int?
}

class DinoScene: SKScene, SKPhysicsContactDelegate {
    
    var sceneCreated = false
    var gameStarted = false
    var canJump = false
    var shouldSpawnObstacle = false
    var shouldUpdateScore = false
    
    let dinoDarkColor = SKColor.blue
    
    let titleNode = SKLabelNode(fontNamed: "Courier")
    let subtitleNode = SKLabelNode(fontNamed: "Courier")
    let scoreNode = SKLabelNode(fontNamed: "Courier")
    let dinoSpriteNode = SKSpriteNode(imageNamed: "logo")
    let healthNode = SKSpriteNode(imageNamed: "5life")
    let bottomCollider: SKPhysicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: 0, y:0), to: CGPoint(x:1005, y:0))
    
    var currentScore = 0
    
    var enemyList: [String] = ["wechat", "qq", "netmusic"]
    var friendlyList: [String] = ["lark", "tiktok", "dongchedi", "melon"]
    var life = 5
    
    override func didMove(to view: SKView) {
        if !sceneCreated {
            sceneCreated = true
            createSceneContents()
        }
    }
    
    func startGame() {
        srand48(Int(arc4random()))
        
        for node in self.children {
            if (node.physicsBody?.categoryBitMask == PhysicsCategory.Obstacle) {
                self.removeChildren(in: [node])
            }
        }
        
        gameStarted = true
        canJump = true
        currentScore = 0
        shouldUpdateScore = true
        updateScore()
        titleNode.isHidden = true
        subtitleNode.isHidden = true
        self.shouldSpawnObstacle = true
        self.spawnObstacle()
        self.updateHealth(health: 5, heal: false)
        self.life = 5
    }
    
    func createSceneContents() {
        self.addChild(titleLabel())
        self.addChild(subtitleLabel())
        self.addChild(dinoSprite())
        self.addChild(scoreLabel())
        self.addChild(health())
        self.physicsWorld.contactDelegate = self
        self.backgroundColor = SKColor(red: 147/255.0, green: 227/255.0, blue: 220/255.0, alpha: 0.5)
        //self.scaleMode = .aspectFit
        
        self.physicsBody = bottomCollider
        bottomCollider.categoryBitMask = PhysicsCategory.Edge | PhysicsCategory.Collider
        bottomCollider.contactTestBitMask = PhysicsCategory.Character
        bottomCollider.friction = 0
        bottomCollider.restitution = 0
        bottomCollider.linearDamping = 0
        bottomCollider.angularDamping = 1
        bottomCollider.isDynamic = false
        bottomCollider.affectedByGravity = false
        bottomCollider.allowsRotation = false
        
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: -9.8)
        
        //self.logger()
        self.spawnObstacle()
    }
    
    func titleLabel() -> SKLabelNode {
        titleNode.text = "TouchBarTikTok"
        titleNode.fontSize = 10
        titleNode.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        titleNode.fontColor = dinoDarkColor
        titleNode.zPosition = 50
        
        return titleNode
    }
    
    func subtitleLabel() -> SKLabelNode {
        subtitleNode.text = "Touch anywhere to begin..."
        subtitleNode.fontSize = 7
        subtitleNode.position = CGPoint(x: self.frame.midX, y: self.frame.midY-10)
        subtitleNode.fontColor = dinoDarkColor
        subtitleNode.zPosition = 50
        
        return subtitleNode
    }
    
    func scoreLabel() -> SKLabelNode {
        scoreNode.text = generateScore()
        scoreNode.fontSize = 13
        scoreNode.horizontalAlignmentMode = .right
        scoreNode.position = CGPoint(x: self.frame.maxX - 4, y:self.frame.midY + 2)
        scoreNode.fontColor = dinoDarkColor
        scoreNode.zPosition = 80
        
        return scoreNode
    }
    
    func generateScore() -> String {
        return String(format: "%07d", currentScore)
    }
    
    func health() -> SKSpriteNode{
        healthNode.setScale(CGFloat(0.5))
        healthNode.position = CGPoint(x: 50, y: 15)
        updateHealth(health: 5, heal: false)
        return healthNode
    }
    
    func dinoSprite() -> SKSpriteNode {
        dinoSpriteNode.setScale(0.25)
        dinoSpriteNode.position = CGPoint(x: 100, y: 40)
        dinoSpriteNode.physicsBody = SKPhysicsBody(rectangleOf: dinoSpriteNode.size)
        if let pb = dinoSpriteNode.physicsBody {
            pb.isDynamic = true
            pb.affectedByGravity = true
            pb.allowsRotation = false
            pb.categoryBitMask = PhysicsCategory.Character
            pb.collisionBitMask = PhysicsCategory.Edge
            pb.contactTestBitMask = PhysicsCategory.Collider
            pb.restitution = 0
            pb.friction = 1
            pb.linearDamping = 1
            pb.angularDamping = 1
        }
        return dinoSpriteNode
    }
    
    func endGame() {
        
        titleNode.isHidden = false
        subtitleNode.isHidden = false
        
        canJump = false
        shouldSpawnObstacle = false
        gameStarted = false
        shouldUpdateScore = false
        for node in self.children {
            if (node.physicsBody?.categoryBitMask == PhysicsCategory.Obstacle) {
                node.physicsBody?.velocity = CGVector(dx:0, dy:0)
            }
        }
    }
    
    func jump() {
        
        if !gameStarted {
            startGame()
        }
        
        if !canJump {
            return
        }
        
        if let pb = dinoSpriteNode.physicsBody {
            pb.applyImpulse(CGVector(dx:0, dy:8.8), at: dinoSpriteNode.position)
        }
    }
    
    func Gatcha(_ contact: SKPhysicsContact) {
        
        if !gameStarted {
            startGame()
        }
        

    }
    
    func spawnObstacle() {
        if self.shouldSpawnObstacle == false {
            return
        }
        
        let x = arc4random() % 3;
        if x != 2 {
            let randomName: String
            let role: Int
            if arc4random()%3 != 0{
                randomName = enemyList.randomElement()!
                role = 0
            } else{
                randomName = friendlyList.randomElement()!
                role = 1
            }
            let ob = ObSpriteNode(imageNamed: randomName)
            ob.role = role
            ob.name = randomName
            ob.setScale(CGFloat(0.5))
//            ob.setScale(CGFloat(drand48() * 0.2 + 0.3))
            ob.position = CGPoint(x: 1020, y: ob.size.height/2)
            ob.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: randomName), size: CGSize(width: ob.size.width/2, height: ob.size.height))
            if let pb = ob.physicsBody {
                pb.isDynamic = true
                pb.affectedByGravity = false
                pb.allowsRotation = false
                pb.categoryBitMask = PhysicsCategory.Obstacle
                pb.contactTestBitMask = PhysicsCategory.Character
                pb.collisionBitMask = 0
                pb.restitution = 0
                pb.friction = 0
                pb.linearDamping = 0
                pb.angularDamping = 0
                pb.velocity = CGVector(dx: -160, dy: 0)
            }
            self.addChild(ob)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 14.0, execute: {
                if self.shouldSpawnObstacle {
                    self.removeChildren(in: [ob])
                }
            })
        }
        
        
        let randDelay = drand48() * 0.3 - Double(min(currentScore, 300)) / 1000.0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 + randDelay, execute: {
            if self.shouldSpawnObstacle == true {
                self.spawnObstacle()
            }
        })
    }
    
    func updateScore() {
        currentScore += 1
        scoreNode.text = generateScore()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            if (self.shouldUpdateScore) {
                self.updateScore()
            }
        })
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if (contact.bodyA == dinoSpriteNode.physicsBody && contact.bodyB == bottomCollider) ||
            (contact.bodyB == dinoSpriteNode.physicsBody && contact.bodyA == bottomCollider) {
            canJump = true
        } else {
            // determine enemy or friendly
            var ob: ObSpriteNode
            if let nodeA = contact.bodyA.node as? ObSpriteNode{
                ob = nodeA
            } else if let nodeB = contact.bodyB.node as? ObSpriteNode{
                ob = nodeB
            } else{
                return
            }
            if ob.role == 0{
                life -= 1
                updateHealth(health: life, heal: false)
                explode(firework: ob)
            } else if life < 5{
                life += 1
                updateHealth(health: life, heal: true)
                ob.removeFromParent()
            }
            if life == 0{
                endGame()
            }
        }
    }
    
    func explode(firework: SKNode) {
        if let emitter = SKEmitterNode(fileNamed: "explode") {
            emitter.position = firework.position
            addChild(emitter)
        }
        
        firework.removeFromParent()
    }
    
    func updateHealth(health: Int, heal: Bool){
        var myFunc = {}
        if health >= 5 {
            if heal{
                self.healthNode.texture = SKTexture(imageNamed: "5heal")
            }
            myFunc = {self.healthNode.texture = SKTexture(imageNamed: "5life")}
        } else if health == 4{
            if heal{
                self.healthNode.texture = SKTexture(imageNamed: "4heal")
            } else{
                self.healthNode.texture = SKTexture(imageNamed: "4hurt")
            }
            myFunc = {self.healthNode.texture = SKTexture(imageNamed: "4life")}
        } else if health == 3{
            if heal{
                self.healthNode.texture = SKTexture(imageNamed: "3heal")
            } else{
                self.healthNode.texture = SKTexture(imageNamed: "3hurt")
            }
            myFunc = {self.healthNode.texture = SKTexture(imageNamed: "3life")}
        } else if health == 2{
            if heal{
                self.healthNode.texture = SKTexture(imageNamed: "2heal")
            } else{
                self.healthNode.texture = SKTexture(imageNamed: "2hurt")
            }
            myFunc = {self.healthNode.texture = SKTexture(imageNamed: "2life")}
        } else if health == 1{
            if heal{
                
            } else{
                self.healthNode.texture = SKTexture(imageNamed: "1hurt")
            }
            myFunc = {self.healthNode.texture = SKTexture(imageNamed: "1life")}
        } else{
            if heal{
               
            } else{
                self.healthNode.texture = SKTexture(imageNamed: "0hurt")
            }
            myFunc = {self.healthNode.texture = SKTexture(imageNamed: "0life")}
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: myFunc)

    }
    
    func didEnd(_ contact: SKPhysicsContact) {
        if (contact.bodyA == dinoSpriteNode.physicsBody && contact.bodyB == bottomCollider) ||
            (contact.bodyB == dinoSpriteNode.physicsBody && contact.bodyA == bottomCollider) {
            canJump = false
        }
    }
    
    func logger() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            NSLog("Sprite at: %f, %f", self.dinoSpriteNode.position.x, self.dinoSpriteNode.position.y)
            self.logger()
        })
    }
    
    
}
