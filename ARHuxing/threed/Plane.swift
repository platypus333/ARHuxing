//
//  Plane.swift
//  ARHuxing
//
//  Created by EJU on 2018/11/7.
//  Copyright © 2018年 EJU. All rights reserved.
//

import ARKit

class Plane: SCNNode {
    
    var plane: SCNNode!
    var id: UUID!
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(_ anchor: ARPlaneAnchor) {
        super.init()
        self.id = anchor.identifier
        let planeGeom = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        
        let material = SCNMaterial()
        //渲染表面颜色(默认是白色) 也可为图片
        material.diffuse.contents = UIColor(red: 0.4, green: 0.6, blue: 1, alpha: 0.4)
        material.lightingModel = .lambert
        planeGeom.materials = [material]
        
        plane = SCNNode(geometry: planeGeom)
        //表示在其父节点内的坐标系
        plane.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        //变换在其父节点内的本身节点 (angle x y z)
        plane.transform = SCNMatrix4MakeRotation(Float(-Double.pi/2), 1, 0, 0)
        
        self.setTextureScale()
        addChildNode(plane)
    }
    
    func update(anchor : ARPlaneAnchor)
    {
        let planeGeom = plane.geometry as! SCNPlane
        
        planeGeom.width = CGFloat(anchor.extent.x)
        planeGeom.height = CGFloat(anchor.extent.z)
        plane.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        
        self.setTextureScale()
    }
    
    func setTextureScale() {
        let planeGeom = plane.geometry as! SCNPlane
        
        let width = planeGeom.width
        let height = planeGeom.height
        
        // 平面的宽度/高度 width/height 更新时，我希望 tron grid material 覆盖整个平面，不断重复纹理。
        // 但如果网格小于 1 个单位，我不希望纹理挤在一起，所以这种情况下通过缩放更新纹理坐标并裁剪纹理
        let material = planeGeom.materials.first
        material?.diffuse.contentsTransform = SCNMatrix4MakeScale(Float(width), Float(height), 1)
        material?.diffuse.wrapS = .repeat
        material?.diffuse.wrapT = .repeat
    }
    
}
