//
//  PlaceholderView.swift
//  misisbooks
//
//  Created by Maxim Loskov on 01.12.14.
//  Copyright (c) 2014 Maxim Loskov. All rights reserved.
//

import UIKit

/// Класс для представления вида-заполнителя
class PlaceholderView: UIView {
    
    /// Контроллер
    private var viewController: UIViewController!
    
    /// Кнопка
    private var button: UIButton!
    
    /// Поле заголовка
    private var titleLabel: UILabel!
    
    /// Поле подзаголовка
    private var subtitleLabel: UILabel!
    
    /// Обработчик нажатия на кнопку
    private var tapHandler: (() -> Void)!
    
    /// Инициализирует класс заданными параметрами
    ///
    /// :param: viewController Контроллер
    /// :param: title Заголовок
    /// :param: subtitle Подзаголовок
    /// :param: buttonText Текст кнопки
    /// :param: tapHandler Блок нажатия на кнопку
    init(viewController: UIViewController, title: String, subtitle: String, buttonText: String, tapHandler: () -> Void) {
        super.init(frame: CGRectZero)
        
        self.tapHandler = tapHandler
        self.viewController = viewController
        
        titleLabel = UILabel()
        titleLabel.backgroundColor = UIColor.clearColor()
        titleLabel.font = UIFont(name: "HelveticaNeue", size: 20)
        titleLabel.shadowColor = UIColor.whiteColor()
        titleLabel.shadowOffset = CGSizeMake(0, -1)
        titleLabel.text = title
        titleLabel.textColor = UIColor(red: 79 / 255.0, green: 97 / 255.0, blue: 115 / 255.0, alpha: 1)
        titleLabel.sizeToFit()
        addSubview(titleLabel)
        
        subtitleLabel = UILabel()
        subtitleLabel.backgroundColor = UIColor.clearColor()
        subtitleLabel.font = UIFont(name: "HelveticaNeue", size: 16)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.shadowColor = UIColor.whiteColor()
        subtitleLabel.shadowOffset = CGSizeMake(0, -1)
        subtitleLabel.text = subtitle
        subtitleLabel.textAlignment = .Center
        subtitleLabel.textColor = UIColor(red: 99 / 255.0, green: 117 / 255.0, blue: 135 / 255.0, alpha: 1)
        subtitleLabel.lineBreakMode = .ByWordWrapping
        subtitleLabel.sizeToFit()
        addSubview(subtitleLabel)
        
        button = CustomButton(title: buttonText, color: UIColor(red: 255 / 255.0, green: 70 / 255.0, blue: 70 / 255.0, alpha: 1))
        button.addTarget(self, action: Selector("buttonPressed"), forControlEvents: .TouchUpInside)
        addSubview(button)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let navigationBarHeight = viewController.navigationController!.navigationBar.frame.size.height
        frame = CGRectMake(0.0, -navigationBarHeight, viewController.view.bounds.width, viewController.view.bounds.height)
        titleLabel.center = CGPointMake(frame.size.width / 2, frame.size.height / 2 - 50)
        subtitleLabel.center = CGPointMake(frame.size.width / 2, frame.size.height / 2)
        button.center = CGPointMake(frame.size.width / 2, frame.size.height / 2 + 60)
    }
    
    /// Обрабатывает событие, когда нажата кнопка
    func buttonPressed() {
        tapHandler()
    }
}
