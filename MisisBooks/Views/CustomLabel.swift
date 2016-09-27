//
//  CustomLabel.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 01.12.14.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit

class CustomLabel: UILabel {
    var edgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

    override func draw(_ rect: CGRect) {
        super.drawText(in: UIEdgeInsetsInsetRect(rect, edgeInsets))
    }
}
