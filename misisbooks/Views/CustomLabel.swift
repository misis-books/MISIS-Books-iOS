//
//  CustomLabel.swift
//  misisbooks
//
//  Created by Maxim Loskov on 01.12.14.
//  Copyright (c) 2014 Maxim Loskov. All rights reserved.
//

import UIKit

/// Класс для представления поля с внутренними отступами (от границ поля до текста)
class CustomUILabel : UILabel {
    
    /// Отступ сверху
    var topInset : CGFloat = 0.0
    
    /// Отступ слева
    var leftInset : CGFloat = 0.0
    
    /// Отступ снизу
    var bottomInset : CGFloat = 0.0
    
    /// Отступ справа
    var rightInset : CGFloat = 0.0
    
    
    /// Возвращает прямоугольник с заданными отступами
    ///
    /// :param: rect Прямоугольник
    override func drawRect(rect: CGRect) {
        let insets = UIEdgeInsets(
            top: topInset,
            left: leftInset,
            bottom: bottomInset,
            right: rightInset
        )
        
        return super.drawTextInRect(UIEdgeInsetsInsetRect(rect, insets))
    }
}
