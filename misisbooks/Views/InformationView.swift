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
    
    /// Кнопка-ссылка
    var linkButton : UIButton!
    
    /// Блок нажатия на кнопку-ссылку
    var tappedBlock : (() -> Void)!
    
    
    /// Инициализирует класс заданными параметрами
    ///
    /// :param: viewController Контроллер вида
    /// :param: title Заголовок
    /// :param: subtitle Подзаголовок
    /// :param: linkButtonText Текст кнопки-ссылки
    /// :param: tappedBlock Блок нажатия на кнопку-ссылку
    init(viewController: UIViewController, title: String, subtitle: String, linkButtonText: String, tappedBlock: () -> Void) {
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
        self.addSubview(titleLabel)
        
        let subtitleLabel = UILabel(frame: CGRectMake(0.0, 0.0, viewController.view.frame.size.width, 0.0))
        subtitleLabel.backgroundColor = UIColor.clearColor()
        subtitleLabel.font = UIFont(name: "HelveticaNeue", size: 16.0)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.shadowColor = UIColor.whiteColor()
        subtitleLabel.shadowOffset = CGSizeMake(0.0, -1.0)
        subtitleLabel.text = subtitle
        subtitleLabel.textAlignment = NSTextAlignment.Center
        subtitleLabel.textColor = UIColor(red: 99 / 255.0, green: 117 / 255.0, blue: 135 / 255.0, alpha: 1.0)
        subtitleLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        subtitleLabel.sizeToFit()
        subtitleLabel.center = CGPointMake(frame.size.width / 2, frame.size.height / 2)
        self.addSubview(subtitleLabel)
        
        linkButton = UIButton(frame: CGRectZero)
        linkButton.addTarget(self, action: Selector("linkButtonPressed"), forControlEvents: UIControlEvents.TouchUpInside)
        linkButton.addTarget(self, action: Selector("makeLinkButtonInactive"), forControlEvents: UIControlEvents.TouchUpInside)
        linkButton.addTarget(self, action: Selector("makeLinkButtonInactive"), forControlEvents: UIControlEvents.TouchCancel)
        linkButton.addTarget(self, action: Selector("makeLinkButtonActive"), forControlEvents: UIControlEvents.TouchDown)
        linkButton.setTitle(linkButtonText, forState: UIControlState.Normal)
        linkButton.setTitleColor(UIColor(red: 255 / 255.0, green: 70 / 255.0, blue: 70 / 255.0, alpha: 1.0), forState: UIControlState.Normal)
        linkButton.backgroundColor = UIColor.clearColor()
        linkButton.contentEdgeInsets = UIEdgeInsetsMake(6.0, 8.0, 6.0, 8.0)
        linkButton.titleLabel?.font = UIFont(name: "HelveticaNeue", size: 14.0)
        linkButton.layer.borderWidth = 1.0
        linkButton.layer.borderColor = UIColor(red: 255 / 255.0, green: 70 / 255.0, blue: 70 / 255.0, alpha: 1.0).CGColor
        linkButton.layer.cornerRadius = 2.0
        linkButton.sizeToFit()
        linkButton.center = CGPointMake(frame.size.width / 2, frame.size.height / 2 + 60.0)
        self.addSubview(linkButton)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /// Обрабатывает событие, когда нажата кнопка-ссылка
    func linkButtonPressed() {
        tappedBlock()
    }
    
    /// Делает кнопку-ссылку неактивной
    func makeLinkButtonInactive() {
        UIView.animateWithDuration(0.25) {
            self.linkButton.layer.opacity = 1.0
        }
    }
    
    /// Делает кнопку-ссылку активной
    func makeLinkButtonActive() {
        UIView.animateWithDuration(0.25) {
            self.linkButton.layer.opacity = 0.5
        }
    }
}
