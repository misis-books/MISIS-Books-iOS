//
//  AppDelegate.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 01.12.14.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    /// Окно
    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let mainColor = UIColor(red: 1, green: 70 / 255.0, blue: 70 / 255.0, alpha: 1)
        
        UINavigationBar.appearance().tintColor = mainColor
        UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName: UIFont(name: "HelveticaNeue", size: 16)!,
            NSForegroundColorAttributeName: mainColor]
        UIBarButtonItem.appearance().setBackButtonTitlePositionAdjustment(UIOffsetMake(-1000, -1000), forBarMetrics: .Default)
        
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window!.backgroundColor = UIColor(red: 241 / 255.0, green: 239 / 255.0, blue: 237 / 255.0, alpha: 1)
        window!.rootViewController = ControllerManager.instance.slideMenuController
        window!.makeKeyAndVisible()
        
        return true
    }
}
