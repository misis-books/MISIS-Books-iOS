//
//  CustomButton.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 25.03.15.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit

/**
    Класс для представления настраиваемой кнопки
*/
class CustomButton: UIButton {

    init(title: String, color: UIColor) {
        super.init(frame: CGRectZero)

        addTarget(self, action: "makeNormal", forControlEvents: .TouchCancel)
        addTarget(self, action: "makeActive", forControlEvents: .TouchDown)
        addTarget(self, action: "makeNormal", forControlEvents: .TouchUpInside)
        setTitle(title, forState: .Normal)
        setTitleColor(color, forState: .Normal)
        backgroundColor = .clearColor()
        contentEdgeInsets = UIEdgeInsetsMake(6, 8, 6, 8)
        layer.borderColor = color.CGColor
        layer.borderWidth = 1
        layer.cornerRadius = 2
        titleLabel!.font = UIFont(name: "HelveticaNeue", size: 14)
        sizeToFit()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    /**
        Делает кнопку активной
    */
    func makeActive() {
        UIView.animateWithDuration(0.25) {
            self.layer.opacity = 0.5
        }
    }

    /**
        Делает кнопку обычной
    */
    func makeNormal() {
        UIView.animateWithDuration(0.25) {
            self.layer.opacity = 1
        }
    }
}
