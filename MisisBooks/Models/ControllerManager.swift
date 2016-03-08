//
//  ControllerManager.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 03.02.15.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit

/**
    Класс для управления контроллерами
*/
class ControllerManager {

    /// Контроллер загрузок
    let downloadsTableViewController = DownloadsTableViewController(style: .Grouped)

    /// Контроллер избранного
    let favoritesTableViewController = FavoritesTableViewController(style: .Grouped)

    /// Контроллер меню
    let menuTableViewController = MenuTableViewController()

    /// Контроллер поиска
    let searchTableViewController = SearchTableViewController(style: .Grouped)

    /// Корневой контроллер
    var slideMenuController: SlideMenuController!

    /**
        Возвращает экземпляр класса

        - returns: Экземпляр класса
    */
    class var instance: ControllerManager {

        struct Singleton {
            static let instance = ControllerManager()
        }

        return Singleton.instance
    }

    init() {
        let downloadsTableViewNavigationController = UINavigationController(rootViewController:
            downloadsTableViewController)

        menuTableViewController.downloadsTableViewNavigationController = downloadsTableViewNavigationController
        slideMenuController = SlideMenuController(mainViewController: downloadsTableViewNavigationController,
            menuViewController: menuTableViewController)
    }
}
