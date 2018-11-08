//
//  Object2D.swift
//  ARHuxing
//
//  Created by EJU on 2018/11/8.
//  Copyright © 2018年 EJU. All rights reserved.
//

import UIKit
import SceneKit

class Object2D: UIView
{
    var points: [GLKVector2] = []
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
}
