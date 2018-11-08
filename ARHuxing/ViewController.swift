//
//  ViewController.swift
//  ARHuxing
//
//  Created by EJU on 2018/11/7.
//  Copyright © 2018年 EJU. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    
    var scene     = SCNScene()
    
    // 房间展示
    var roomView  = RoomView()
    
    //屏幕尺寸
    var ScreenW   = UIScreen.main.bounds.size.width
    var ScreenH   = UIScreen.main.bounds.size.height
    //planes
    var planes:[UUID:Plane] = [:]
    //balls
    var balls:[SCNNode] = []
    //lines
    var lines:[SCNNode] = []
    //lineTexts
    var lineTexts:[SCNNode] = []
    //scanLine
    var scanLine: SCNNode?
    //scanLineText
    var scanLineText: SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.scene = scene
        sceneView.showsStatistics = true
        
        // 添加多边形展示平面图
        let roomViewWidth = ScreenW/2.7
        let roomViewHeight = roomViewWidth
        
        roomView = RoomView(frame: CGRect(x: 10, y: ScreenH - roomViewHeight - 20, width: roomViewWidth, height: roomViewHeight))
        sceneView.addSubview(roomView)
        
        // 按钮宽高
        let buttonWidth = ScreenW/6
        let buttonHeight = ScreenH/16
        
        // 添加中心按钮
        let pointBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 15, height: 15))
        pointBtn.center = sceneView.center
        pointBtn.setImage(UIImage(named: "point_icon"), for: .normal)
        sceneView.addSubview(pointBtn)
        
        // 添加连线按钮
        let lineBtn = createButton("点击", CGRect(x: (ScreenW - buttonWidth)/2, y: ScreenH - buttonHeight - 20, width: buttonWidth, height: buttonHeight))
        lineBtn.addTarget(self, action: #selector(addLine), for: .touchUpInside)
        sceneView.addSubview(lineBtn)
        
        // 添加撤销按钮
        let undoBtn = createButton("撤销", CGRect(x: lineBtn.frame.origin.x + buttonWidth + 5 , y: ScreenH - buttonHeight - 20, width: buttonWidth, height: buttonHeight))
        undoBtn.addTarget(self, action: #selector(undo), for: .touchDown)
        sceneView.addSubview(undoBtn)
        
        // 添加清空按钮
        let clearBtn = createButton("清空", CGRect(x: undoBtn.frame.origin.x + buttonWidth + 5, y: ScreenH - buttonHeight - 20, width: buttonWidth, height: buttonHeight))
        clearBtn.addTarget(self, action: #selector(clear), for: .touchDown)
        sceneView.addSubview(clearBtn)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    //MARK: 按钮点击事件
    @objc func addLine()
    {
        if planes.count > 0 {
            let ball = createBall()
            scene.rootNode.addChildNode(ball)
            balls.append(ball)
            
            // copy连线
            if self.scanLine != nil {
                let text = self.scanLineText?.childNodes.last
                let lineText = self.scanLineText!.copy() as! SCNNode
                let line = self.scanLine!.copy() as! SCNNode
                lineText.addChildNode(text!)
                line.addChildNode(lineText)
                lines.append(line)
                scene.rootNode.addChildNode(lines.last!)
            }
            self.updateRoom()
        }else {
            let alert = UIAlertController(title: "提示", message: "请先扫描区域", preferredStyle: .alert)
            let action = UIAlertAction(title: "确定", style: .default)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // 生成中心点的ball
    func createBall() -> SCNNode
    {
        
        // 以中心点为坐标
        let centerPoint = sceneView.center
        let results = sceneView.hitTest(centerPoint, types: [.existingPlane])
        
        // 在结果中找到最下面的点 (y轴最小)
        var minY:Float = 99999999
        var targetResult:ARHitTestResult? = nil
        for result in results
        {
            let y = result.worldTransform.columns.3.y
            if y <= minY
            {
                targetResult = result
                minY = y
            }
        }
        
        if targetResult != nil
        {
            let point = targetResult!.worldTransform.columns.3
            let pos = SCNVector3Make(point.x, point.y, point.z)
            
            let ballGeom = SCNSphere(radius: 0.02)
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.init(red: 253/255, green: 135/255, blue: 50/255, alpha: 1)
            material.ambient.contents = UIColor.init(white: 0.1, alpha: 1)
            material.locksAmbientWithDiffuse = false
            material.lightingModel = .lambert
            ballGeom.materials = [material]
            let ball = SCNNode(geometry: ballGeom)
            ball.position = pos
            return ball
        }
        return SCNNode()
    }
    
    //保持连线
    func createScanLine()
    {
        
        let ball1:SCNNode = balls.last!
        let ball2 = createBall()
        
        let p1 = SCNVector3ToGLKVector3(ball1.position)
        let p2 = SCNVector3ToGLKVector3(ball2.position)
        // 计算中心点
        var center = GLKVector3Add(p1, p2)
        center = GLKVector3DivideScalar(center, 2.0)
        // 计算距离
        let d = GLKVector3Distance(p1, p2)
        // 计算角度
        let angleVector3 = GLKVector3Normalize(GLKVector3Subtract(p1, p2))
        let yAxis = GLKVector3Make(0, 1, 0)
        // 旋转轴
        let rotateAxis = GLKVector3DivideScalar(GLKVector3Add(angleVector3, yAxis), 2.0)
        
        let lineGeom = SCNCylinder(radius: 0.002, height: CGFloat(d))
        let line = SCNNode(geometry: lineGeom)
        // 旋转
        line.transform = SCNMatrix4MakeRotation(Float(Double.pi), rotateAxis.x, rotateAxis.y, rotateAxis.z)
        // 坐标
        line.position = SCNVector3FromGLKVector3(center)
        
        //重新添加sscanLine
        self.scanLine?.removeFromParentNode()
        self.scanLine = line
        self.createScanLineText(distance: String(Int(d*100)) + "厘米")
        scene.rootNode.addChildNode(self.scanLine!)
    }
    
    //连线距离
    func createScanLineText(distance: String)
    {
        let text = SCNText(string: distance, extrusionDepth: 0)
        text.font = .systemFont(ofSize: 10)
        text.firstMaterial?.diffuse.contents = UIColor.red
        text.firstMaterial?.lightingModel = .constant
        text.firstMaterial?.isDoubleSided = true
        text.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        text.truncationMode = CATextLayerTruncationMode.middle.rawValue

        self.scanLineText?.removeFromParentNode()
        let textWrapperNode = SCNNode(geometry: text)
        textWrapperNode.eulerAngles = SCNVector3Make(0, .pi, 0) // 数字对着自己
        textWrapperNode.scale = SCNVector3(1/500.0,1/500.0,1/500.0) // 坑来了
        
        self.scanLineText = SCNNode()
        self.scanLineText?.addChildNode(textWrapperNode)//添加到包装节点上
        let constraint = SCNLookAtConstraint(target: sceneView.pointOfView)//来一个约数
        constraint.isGimbalLockEnabled = true
        self.scanLineText?.constraints = [constraint]
        
        
        self.scanLine?.addChildNode(scanLineText!)
    }
    
    // 撤销
    @objc func undo()
    {
        if let lastLine = lines.popLast()
        {
            lastLine.removeFromParentNode()
        }
        if let lastBall = balls.popLast()
        {
            lastBall.removeFromParentNode()
            if balls.count == 0
            {
                self.scanLine?.removeFromParentNode()
                self.scanLine = nil
            }
        }
        self.updateRoom()
    }
    
    // 清空
    @objc func clear()
    {
        for line in lines
        {
            line.removeFromParentNode()
        }
        lines.removeAll()
        
        for ball in balls
        {
            ball.removeFromParentNode()
        }
        balls.removeAll()
        self.scanLine?.removeFromParentNode()
        self.scanLine = nil
        // 清空矢量图面板
        roomView.clear()
    }
    
    // 更新矢量图
    func updateRoom() {
        // 更新矢量图
        var points:[SCNVector3] = []
        for ball in balls
        {
            points.append(ball.position)
        }
        roomView.update(points: points)
    }
    
    //创建按钮
    func createButton(_ label:String, _ frame:CGRect) -> ColorButton
    {
        let btn = ColorButton(frame)
        btn.setLabel(label)
        
        return btn
    }
}

extension ViewController:ARSCNViewDelegate{
    //MARK: ARSCNViewDelegate
    //    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
    //
    //    }
    
    // 新增平面
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor)
    {
        if let planeAnchor = anchor as? ARPlaneAnchor
        {
            let plane = Plane(planeAnchor)
            planes[planeAnchor.identifier] = plane
            
            node.addChildNode(plane)
            
            // 只保留最下面的一个平面
            if planes.count > 1
            {
                var minY:Float = 99999999
                var floor:Plane!
                for (_, value) in planes
                {
                    if let y = value.parent?.position.y
                    {
                        if y <= minY
                        {
                            floor = value
                            minY = y
                        }
                    }
                }
                for (_, value) in planes
                {
                    if value != floor
                    {
                        value.removeFromParentNode()
                        planes.removeValue(forKey: value.id)
                    }
                }
            }
        }
        
    }
    
    // 更新平面
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor)
    {
        let plane = planes[anchor.identifier]
        if plane != nil
        {
            plane?.update(anchor: anchor as! ARPlaneAnchor)
        }
    }
    
    //移除平面
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor)
    {
        planes.removeValue(forKey: anchor.identifier)
    }
    
    //按时间更新平面
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval)
    {
        
        DispatchQueue.main.async {
            if self.balls.count > 0 {
                self.createScanLine()
            }
        }
        
    }
    
    func session(_ session: ARSession, didFailWithError error: Error)
    {
        
    }
    
    func sessionWasInterrupted(_ session: ARSession)
    {
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession)
    {
        
    }
}
