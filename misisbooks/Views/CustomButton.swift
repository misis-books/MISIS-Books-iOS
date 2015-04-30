//
//  CustomButton.swift
//  misisbooks
//
//  Created by Maxim Loskov on 25.03.15.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit

/// Класс для представления настраиваемой кнопки
class CustomButton: UIButton {
    
    init(title: String, color: UIColor) {
        super.init(frame: CGRectZero)
        
        addTarget(self, action: Selector("makeInactive"), forControlEvents: .TouchUpInside)
        addTarget(self, action: Selector("makeInactive"), forControlEvents: .TouchCancel)
        addTarget(self, action: Selector("makeActive"), forControlEvents: .TouchDown)
        setTitle(title, forState: .Normal)
        setTitleColor(color, forState: .Normal)
        backgroundColor = UIColor.clearColor()
        contentEdgeInsets = UIEdgeInsetsMake(6, 8, 6, 8)
        layer.borderWidth = 1
        layer.borderColor = color.CGColor
        layer.cornerRadius = 2
        titleLabel?.font = UIFont(name: "HelveticaNeue", size: 14)
        sizeToFit()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /// Делает кнопку неактивной
    func makeInactive() {
        UIView.animateWithDuration(0.25) {
            self.layer.opacity = 1
        }
    }
    
    /// Делает кнопку активной
    func makeActive() {
        UIView.animateWithDuration(0.25) {
            self.layer.opacity = 0.5
        }
    }
}
