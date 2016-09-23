//
//  AppDelegate.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 01.12.14.
//  Copyright (c) 2016 Maxim Loskov. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let mainColor = UIColor(red: 1, green: 70 / 255.0, blue: 70 / 255.0, alpha: 1)

        UINavigationBar.appearance().tintColor = mainColor
        UINavigationBar.appearance().titleTextAttributes = [
            NSForegroundColorAttributeName: mainColor,
            NSFontAttributeName: UIFont(name: "HelveticaNeue", size: 16)!
        ]
        UIBarButtonItem.appearance().setBackButtonTitlePositionAdjustment(
            UIOffset(horizontal: -1000, vertical: -1000),
            for: .default
        )

        window = UIWindow(frame: UIScreen.main.bounds)
        window!.backgroundColor = UIColor(red: 241 / 255.0, green: 239 / 255.0, blue: 237 / 255.0, alpha: 1)
        window!.rootViewController = ControllerManager.instance.slideMenuController
        window!.makeKeyAndVisible()
        
        return true
    }

}
