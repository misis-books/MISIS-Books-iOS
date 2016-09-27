//
//  CustomButton.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 25.03.15.
//  Copyright (c) 2016 Maxim Loskov. All rights reserved.
//

import UIKit

class CustomButton: UIButton {
    init(title: String, color: UIColor) {
        super.init(frame: .zero)

        backgroundColor = .clear
        contentEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
        layer.borderColor = color.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 2
        titleLabel!.font = UIFont(name: "HelveticaNeue", size: 14)
        addTarget(self, action: #selector(makeActive), for: .touchDown)
        addTarget(self, action: #selector(makeNormal), for: .touchCancel)
        addTarget(self, action: #selector(makeNormal), for: .touchUpInside)
        setTitle(title, for: .normal)
        setTitleColor(color, for: .normal)
        sizeToFit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func makeActive() {
        changeOpacity(to: 0.5)
    }

    func makeNormal() {
        changeOpacity(to: 1)
    }

    func changeOpacity(to opacity: Float) {
        UIView.animate(withDuration: 0.25) {
            self.layer.opacity = opacity
        }
    }
}
