//
//  GameScene.swift
//  FlappyBird
//
//  Created by 中西八洋 on 2021/08/18.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var bird:SKSpriteNode!
    var itemNode:SKNode!
    
    private let sound = try!  AVAudioPlayer(data: NSDataAsset(name: "sound")!.data)
    
    private func playSound(){
        sound.play()
    }
    
    let birdCategory: UInt32 = 1 << 0       // 0...00001
    let groundCategory: UInt32 = 1 << 1     // 0...00010
    let wallCategory: UInt32 = 1 << 2       // 0...00100
    let scoreCategory: UInt32 = 1 << 3      // 0...01000
    let itemCategory: UInt32 = 1 << 4
    
    var score = 0
    var itemscore = 0
 //   var scoreLabelNode:SKLabelNode!
   // var bestScoreLabelNode:SKLabelNode!
    var scoreLabelNode:SKLabelNode!    // ←追加
    var bestScoreLabelNode:SKLabelNode!
    
    var itemscoreLabelNode:SKLabelNode!
    
    let userDefaults:UserDefaults = UserDefaults.standard
    override func didMove(to view:SKView){
        
        physicsWorld.gravity=CGVector(dx: 0,dy: -4)
        physicsWorld.contactDelegate = self
        
        backgroundColor=UIColor(red:0.15,green:0.75,blue:0.90,alpha: 1)
        scrollNode=SKNode()
        addChild(scrollNode)
        
        wallNode = SKNode()   // 追加
        scrollNode.addChild(wallNode)
//        scrollNode.addChild(itemNode)
        
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupScoreLabel()
        setupitem()
       // setupitemScoreLabe()
    }
        
        func setupGround() {
        // 地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest

        // 必要な枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2

        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)

        // 元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)

        // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))

        // groundのスプライトを配置する
        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture: groundTexture)

            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: groundTexture.size().width / 2  + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2
            )

            // スプライトにアクションを設定する
            sprite.run(repeatScrollGround)

            
            
            
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            
            sprite.physicsBody?.categoryBitMask = groundCategory
            sprite.physicsBody?.isDynamic = false
            // スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }

    func setupCloud() {
        // 雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest

        // 必要な枚数を計算
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2

        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20)

        // 元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)

        // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))

        // スプライトを配置する
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 // 一番後ろになるようにする

            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )

            // スプライトにアニメーションを設定する
            sprite.run(repeatScrollCloud)

            // スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    func setupWall() {
        // 壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        // 移動する距離を計算
        let movingDistance = self.frame.size.width + wallTexture.size().width
        // 画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration:4)
        // 自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        // 2つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        // 鳥の画像サイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        // 鳥が通り抜ける隙間の大きさを鳥のサイズの4倍とする
        let slit_length = birdSize.height * 4
        // 隙間位置の上下の振れ幅を60ptとする
        let random_y_range: CGFloat = 60
        // 空の中央位置(y座標)を取得
        let groundSize = SKTexture(imageNamed: "ground").size()
        let sky_center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2

        // 空の中央位置を基準にして下の壁の中央位置を取得
        let under_wall_center_y = sky_center_y - slit_length / 2 - wallTexture.size().height / 2
        // 壁を生成するアクションを作成
        let createWallAnimation = SKAction.run({
            // 壁関連のノードを乗せるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
            wall.zPosition = -50 // 雲より手前、地面より奥
            // -random_y_range〜random_y_rangeの範囲のランダム値を生成
            let random_y = CGFloat.random(in: -random_y_range...random_y_range)

            // 下の壁の中央位置にランダム値を足して、下の壁の表示位置を決定
            let under_wall_y = under_wall_center_y + random_y
            // 下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0, y: under_wall_y)
            
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            under.physicsBody?.isDynamic = false
            wall.addChild(under)
            // 上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
           
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            upper.physicsBody?.isDynamic = false
            
            wall.addChild(upper)
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            wall.addChild(scoreNode)
            
            
            wall.run(wallAnimation)
            self.wallNode.addChild(wall)
        })
        // 次の壁作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        // 壁を作成->時間待ち->壁を作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        wallNode.run(repeatForeverAnimation)
    }
        
    
    
    
    func setupBird(){
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        
        let texturesAnimation = SKAction.animate(with: [birdTextureA,birdTextureB],timePerFrame: 0.2)
        
        let flap = SKAction.repeatForever(texturesAnimation)
        
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x:self.frame.size.width*0.2,y:self.frame.size.height*0.7)
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height/2)
        
        
        bird.physicsBody?.allowsRotation = false    // ←追加

        // 衝突のカテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory    // ←追加
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory    // ←追加
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory    // ←追加
        
        bird.run(flap)
        
        addChild(bird)
    }
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>,with event: UIEvent?){
        if scrollNode.speed > 0 {
        bird.physicsBody?.velocity = CGVector.zero
        
        bird.physicsBody?.applyImpulse(CGVector(dx: 0,dy: 15))
        } else if bird.speed == 0 { // --- ここから ---
            restart()
        }

    }
        
    
    func didBegin(_ contact: SKPhysicsContact) {
        if scrollNode.speed <= 0 {
            return
        }

        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score>bestScore{
                bestScore=score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore,forKey:"BEST")
                userDefaults.synchronize()
                        }
            
            
        }else if (contact.bodyA.categoryBitMask & itemCategory) == itemCategory || (contact.bodyB.categoryBitMask & itemCategory) == itemCategory{
            playSound()
            itemscore += 1
            itemscoreLabelNode.text = "itemScore:\(itemscore)"
            //scale(by scale: CGFloat, duration sec: TimeInterval)
            
            
            //bird.removeFromParent()
            //wallNode.removeFromParent()
            //if contact.bodyA == itemNode{
            contact.bodyA.node!.removeFromParent()
           // }else if contact.bodyB == itemNode{
            //contact.bodyA.node!.removeFromParent()
            //}
            
            
            
        }else {
            // 壁か地面と衝突した
            print("GameOver")

            // スクロールを停止させる
            scrollNode.speed = 0

            bird.physicsBody?.collisionBitMask = groundCategory

            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration:1)
            bird.run(roll, completion:{
                self.bird.speed = 0
            })
        }
        
    }
    
    
    func restart() {
            score = 0
            itemscore = 0
           // scoreLabelNode.text = "Score:\(score)"
            bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
            bird.physicsBody?.velocity = CGVector.zero
            bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
            bird.zRotation = 0
        
            wallNode.removeAllChildren()
            
            bird.speed = 1
            scrollNode.speed = 1
        }
    

    
    func setupitem() {
      
        
        
        let itemTexture = SKTexture(imageNamed: "item")
        itemTexture.filteringMode = .nearest
        

        
        
        
        
        let needitemNumber = Int(self.frame.size.width / itemTexture.size().width) + 2
        let moveitem = SKAction.moveBy(x: -itemTexture.size().width * 53, y: 0, duration: 20)
        let resetitem = SKAction.moveBy(x: itemTexture.size().width, y: 0, duration: 0)
        let repeatScrollitem = SKAction.repeatForever(SKAction.sequence([moveitem, resetitem]))
        
        for i in 0..<needitemNumber*10 {
             let random:CGFloat = 100
            let sprite = SKSpriteNode(texture: itemTexture)
            sprite.zPosition = -60 // 一番後ろになるようにする

            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: itemTexture.size().width / 2 + itemTexture.size().width * CGFloat(i*10),
                y: 500 - random
)
            
 /*           sprite.physicsBody?.categoryBitMask = self.itemCategory
            sprite.physicsBody?.isDynamic = false
            
            
            sprite.physicsBody?.contactTestBitMask = self.birdCategory
   */
            sprite.physicsBody = SKPhysicsBody(rectangleOf: itemTexture.size())
            sprite.physicsBody?.isDynamic = false
            sprite.physicsBody?.categoryBitMask = self.itemCategory
            sprite.physicsBody?.contactTestBitMask = self.birdCategory
            /*
            if (birdCategory & itemCategory) == itemCategory || (birdCategory & itemCategory) == itemCategory{
                itemNode?.isHidden=true
            }*/
            sprite.run(repeatScrollitem)

        // スプライトを追加する
            scrollNode.addChild(sprite)
        
        /*      itemNode = SKSpriteNode(texture: itemTexture)
        itemNode.position=CGPoint(x: self.frame.size.width * 0.4, y:self.frame.size.height * 0.7)
    */
        }
        
    }
    
    
    
    func setupScoreLabel() {
           score = 0
           scoreLabelNode = SKLabelNode()
           scoreLabelNode.fontColor = UIColor.black
           scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
           scoreLabelNode.zPosition = 100 // 一番手前に表示する
           scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
           scoreLabelNode.text = "Score:\(score)"
           self.addChild(scoreLabelNode)

           bestScoreLabelNode = SKLabelNode()
           bestScoreLabelNode.fontColor = UIColor.black
           bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
           bestScoreLabelNode.zPosition = 100 // 一番手前に表示する
           bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left

           let bestScore = userDefaults.integer(forKey: "BEST")
           bestScoreLabelNode.text = "Best Score:\(bestScore)"
           self.addChild(bestScoreLabelNode)
        
        itemscore = 0
        itemscoreLabelNode = SKLabelNode()
        itemscoreLabelNode.fontColor = UIColor.black
        itemscoreLabelNode.position = CGPoint(x:10,y:self.frame.size.height - 120)
        itemscoreLabelNode.zPosition = 100
        itemscoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemscoreLabelNode.text = "itemScore:\(itemscore)"
        self.addChild(itemscoreLabelNode)
        
        
       }
    

    
    
    
    
    
    
    
}
