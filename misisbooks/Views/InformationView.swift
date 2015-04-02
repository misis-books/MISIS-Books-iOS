//
//  InformationView.swift
//  misisbooks
//
//  Created by Maxim Loskov on 01.12.14.
//  Copyright (c) 2014 Maxim Loskov. All rights reserved.
//

import UIKit

/// Класс для представления информационного вида
class InformationView : UIView {
    
    /// Кнопка
    var button : UIButton!
    
    /// Блок нажатия на кнопку
    var tappedBlock : (() -> Void)!
    
    
    /// Инициализирует класс заданными параметрами
    ///
    /// :param: viewController Контроллер вида
    /// :param: title Заголовок
    /// :param: subtitle Подзаголовок
    /// :param: linkButtonText Текст кнопки
    /// :param: tappedBlock Блок нажатия на кнопку
    init(viewController: UIViewController, title: String, subtitle: String, buttonText: String, tappedBlock: () -> Void) {
        self.tappedBlock = tappedBlock
        
        let navigationBarHeight = viewController.navigationController!.navigationBar.frame.size.height
        let frame = CGRectMake(0.0, -navigationBarHeight, viewController.view.frame.size.width, viewController.view.frame.size.height)
        
        super.init(frame: frame)
        
        let titleLabel = UILabel(frame: CGRectZero)
        titleLabel.backgroundColor = UIColor.clearColor()
        titleLabel.font = UIFont(name: "HelveticaNeue", size: 20.0)
        titleLabel.shadowColor = UIColor.whiteColor()
        titleLabel.shadowOffset = CGSizeMake(0.0, -1.0)
        titleLabel.text = title
        titleLabel.textColor = UIColor(red: 79 / 255.0, green: 97 / 255.0, blue: 115 / 255.0, alpha: 1.0)
        titleLabel.sizeToFit()
        titleLabel.center = CGPointMake(frame.size.width / 2, frame.size.height / 2 - 50.0)
        addSubview(titleLabel)
        
        let subtitleLabel = UILabel(frame: CGRectMake(0.0, 0.0, viewController.view.frame.size.width, 0.0))
        subtitleLabel.backgroundColor = UIColor.clearColor()
        subtitleLabel.font = UIFont(name: "HelveticaNeue", size: 16.0)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.shadowColor = UIColor.whiteColor()
        subtitleLabel.shadowOffset = CGSizeMake(0.0, -1.0)
        subtitleLabel.text = subtitle
        subtitleLabel.textAlignment = .Center
        subtitleLabel.textColor = UIColor(red: 99 / 255.0, green: 117 / 255.0, blue: 135 / 255.0, alpha: 1.0)
        subtitleLabel.lineBreakMode = .ByWordWrapping
        subtitleLabel.sizeToFit()
        subtitleLabel.center = CGPointMake(frame.size.width / 2, frame.size.height / 2)
        addSubview(subtitleLabel)
        
        button = CustomButton(title: buttonText, color: UIColor(red: 255 / 255.0, green: 70 / 255.0, blue: 70 / 255.0, alpha: 1.0))
        button.addTarget(self, action: Selector("linkButtonPressed"), forControlEvents: .TouchUpInside)
        button.center = CGPointMake(frame.size.width / 2, frame.size.height / 2 + 60.0)
        addSubview(button)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /// Обрабатывает событие, когда нажата кнопка-ссылка
    func linkButtonPressed() {
        tappedBlock()
    }
}
