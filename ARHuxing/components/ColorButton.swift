//
//  ColorButton.swift
//  ARhuxing
//
//  Created by EJU on 2018/8/14.
//  Copyright © 2018年 EJU. All rights reserved.
//

import UIKit

public class ColorButton: UIButton
{
    convenience init(_ frame:CGRect)
    {
        self.init(type: UIButton.ButtonType.system)
        
        self.frame = frame
        self.backgroundColor = UIColor.white
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
    }
    
    
    
    public func setLabel(_ label:String)
    {
        self.setTitle(label, for: .normal)
        self.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        self.setTitleColor(UIColor.black, for: .normal)
    }
}
