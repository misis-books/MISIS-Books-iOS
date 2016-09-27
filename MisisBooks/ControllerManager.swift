//
//  ControllerManager.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 03.02.15.
//  Copyright (c) 2016 Maxim Loskov. All rights reserved.
//

import UIKit

class ControllerManager {
    static let instance = ControllerManager()
    let downloadsTableViewController = DownloadsTableViewController(style: .grouped)
    let favoritesTableViewController = FavoritesTableViewController(style: .grouped)
    let menuTableViewController = MenuTableViewController()
    let searchTableViewController = SearchTableViewController(style: .grouped)
    var slideMenuController: SlideMenuController!

    init() {
        let downloadsTableViewNavigationController = UINavigationController(
            rootViewController: downloadsTableViewController
        )

        menuTableViewController.downloadsTableViewNavigationController = downloadsTableViewNavigationController
        slideMenuController = SlideMenuController(
            mainViewController: downloadsTableViewNavigationController,
            menuViewController: menuTableViewController
        )
    }
}
