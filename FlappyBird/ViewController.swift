//
//  ViewController.swift
//  FlappyBird
//
//  Created by 中西八洋 on 2021/08/18.
//

import UIKit
import SpriteKit
class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let skView=self.view as! SKView
        
        skView.showsFPS=true
        
        skView.showsNodeCount=true
        
        let scene=GameScene(size:skView.frame.size)
        
        skView.presentScene(scene)
        // Do any additional setup after loading the view.
    }
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }

}

