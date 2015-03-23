//
//  AppDelegate.swift
//  misisbooks
//
//  Created by Maxim Loskov on 01.12.14.
//  Copyright (c) 2014 Maxim Loskov. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    /// Окно
    var window: UIWindow?
    
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let mainColor = UIColor(red: 255 / 255.0, green: 70 / 255.0, blue: 70 / 255.0, alpha: 1.0)
        
        // UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Fade)
        
        // Изменение атрибутов текста заголовка навигационной панели
        UINavigationBar.appearance().titleTextAttributes = [
            // NSFontAttributeName: UIFont(name: "HelveticaNeue", size: 16.0)!,
            NSForegroundColorAttributeName: mainColor
        ]
        
        // Изменение цвета текста кнопок навигационной панели
        UINavigationBar.appearance().tintColor = mainColor
        
        // Скрытие стандартной кнопки "Back" ("Назад")
        UIBarButtonItem.appearance().setBackButtonTitlePositionAdjustment(UIOffsetMake(-1000.0, -1000.0), forBarMetrics: UIBarMetrics.Default)
        
        let menuTableViewController = ControllerManager.instance.menuTableViewController
        let downloadsTableViewController = UINavigationController(rootViewController: ControllerManager.instance.downloadsTableViewController)
        menuTableViewController.downloadsTableViewController = downloadsTableViewController
        
        ControllerManager.instance.slideMenuController = SlideMenuController(mainViewController: downloadsTableViewController, leftMenuViewController: menuTableViewController)
        
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.backgroundColor = UIColor(red: 241 / 255.0, green: 239 / 255.0, blue: 237 / 255.0, alpha: 1.0)
        window?.rootViewController = ControllerManager.instance.slideMenuController
        window?.makeKeyAndVisible()
        
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}