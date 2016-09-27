//
//  PlaceholderView.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 01.12.14.
//  Copyright (c) 2016 Maxim Loskov. All rights reserved.
//

import UIKit

class PlaceholderView: UIView {
    private var viewController: UIViewController!
    private var button: UIButton!
    private var titleLabel: UILabel!
    private var subtitleLabel: UILabel!
    private var tapHandler: (() -> ())!

    init(viewController: UIViewController, title: String, subtitle: String, buttonText: String, tapHandler: @escaping () -> ()) {
        super.init(frame: .zero)

        self.tapHandler = tapHandler
        self.viewController = viewController

        titleLabel = UILabel()
        titleLabel.backgroundColor = .clear
        titleLabel.font = UIFont(name: "HelveticaNeue", size: 20)
        titleLabel.shadowColor = .white
        titleLabel.shadowOffset = CGSize(width: 0, height: -1)
        titleLabel.text = title
        titleLabel.textColor = UIColor(red: 79 / 255.0, green: 97 / 255.0, blue: 115 / 255.0, alpha: 1)
        titleLabel.sizeToFit()
        addSubview(titleLabel)

        subtitleLabel = UILabel()
        subtitleLabel.backgroundColor = .clear
        subtitleLabel.font = UIFont(name: "HelveticaNeue", size: 16)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.shadowColor = .white
        subtitleLabel.shadowOffset = CGSize(width: 0, height: -1)
        subtitleLabel.text = subtitle
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = UIColor(red: 99 / 255.0, green: 117 / 255.0, blue: 135 / 255.0, alpha: 1)
        subtitleLabel.lineBreakMode = .byWordWrapping
        subtitleLabel.sizeToFit()
        addSubview(subtitleLabel)

        button = CustomButton(title: buttonText, color: UIColor(red: 1, green: 70 / 255.0, blue: 70 / 255.0, alpha: 1))
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        addSubview(button)

        layoutIfNeeded()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let navigationBarHeight = viewController.navigationController!.navigationBar.frame.size.height
        frame = CGRect(
            x: 0,
            y: -navigationBarHeight,
            width: viewController.view.bounds.width,
            height: viewController.view.bounds.height
        )
        titleLabel.center = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2 - 50)
        subtitleLabel.center = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
        button.center = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2 + 60)
    }

    func buttonPressed() {
        tapHandler()
    }
}
