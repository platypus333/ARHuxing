//
//  RoomView.swift
//  ARHuxing
//
//  Created by EJU on 2018/11/8.
//  Copyright © 2018年 EJU. All rights reserved.
//

import UIKit
import SceneKit

class RoomView: UIView
{
    //room
    let room:Room2D!
    
    required init?(coder aDecoder: NSCoder) {
        room = Room2D()
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect)
    {
        room = Room2D(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        super.init(frame: frame)
        self.addSubview(room)
    }
    
    //更新内容
    func update(points: [SCNVector3])
    {
        //3d坐标转2d坐标
        var point2ds:[GLKVector2] = []
        for point3d in points
        {
            var point2d = GLKVector2()
            point2d.x = point3d.x
            point2d.y = point3d.z
            
            point2ds.append(point2d)
        }
        
        room.update(points: point2ds)
    }

    // 清空
    func clear()
    {
        room.update(points: [])
    }
    
}
