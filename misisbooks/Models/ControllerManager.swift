//
//  ControllerManager.swift
//  misisbooks
//
//  Created by Maxim Loskov on 03.02.15.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit

/// Класс для хранения контроллеров
class ControllerManager {
    
    /// Корневой контроллер
    var slideMenuController : SlideMenuController!
    
    /// Контроллер "Меню"
    var menuTableViewController = MenuTableViewController()
    
    /// Контроллер "Поиск"
    var searchTableViewController = SearchTableViewController()
    
    /// Контроллер "Загрузки"
    var downloadsTableViewController = DownloadsTableViewController()
    
    /// Контроллер "Избранное"
    var favoritesTableViewController = FavoritesTableViewController()
    
    
    /// Возвращает экземпляр класса
    ///
    /// :returns: Экземпляр класса
    class var instance : ControllerManager {
        
        struct Singleton {
            static let instance = ControllerManager()
        }
        
        return Singleton.instance
    }
}