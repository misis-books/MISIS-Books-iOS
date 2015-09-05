//
//  CustomLabel.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 01.12.14.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit

/**
    Класс для представления поля с внутренними отступами
*/
class CustomLabel: UILabel {

    /// Верхний, левый, нижний и правый внутренние отступы
    var edgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)

    override func drawRect(rect: CGRect) {
        super.drawTextInRect(UIEdgeInsetsInsetRect(rect, edgeInsets))
    }
}
