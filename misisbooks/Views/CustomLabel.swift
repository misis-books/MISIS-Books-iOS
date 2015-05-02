//
//  CustomLabel.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 01.12.14.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit

/// Класс для представления поля с внутренними отступами
class CustomLabel: UILabel {
    
    /// Внутренний отступ сверху
    var topInset: CGFloat = 0
    
    /// Внутренний отступ слева
    var leftInset: CGFloat = 0
    
    /// Внутренний отступ снизу
    var bottomInset: CGFloat = 0
    
    /// Внутренний отступ справа
    var rightInset: CGFloat = 0
    
    /// Возвращает прямоугольник с заданными внутренними отступами
    ///
    /// :param: rect Прямоугольник
    override func drawRect(rect: CGRect) {
        let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        
        super.drawTextInRect(UIEdgeInsetsInsetRect(rect, insets))
    }
}
