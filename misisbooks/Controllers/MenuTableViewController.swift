//
//  MenuViewController.swift
//  misisbooks
//
//  Created by Maxim Loskov on 26.01.15.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit

class MenuTableViewController : UITableViewController, UIAlertViewDelegate, VkAuthorizationViewControllerDelegate {
    
    /// Контроллер поиска
    var searchTableViewController : UIViewController!
    
    /// Контроллер загрузок
    var downloadsTableViewController : UIViewController!
    
    /// Контроллер избранного
    var favoritesTableViewController : UIViewController!
    
    /// "Шапка" таблицы
    var tableHeaderView : UIView!
    
    /// Кнопка авторизации
    var logInButton : CustomButton!
    
    /// Кнопка выхода
    var logOutButton : CustomButton!
    
    /// Аватар
    var avatarView :  UIImageView!
    
    /// Поле с полным именем
    var fullNameLabel : UILabel!
    
    /// Индикатор активности
    var activityIndicatorView : UIActivityIndicatorView!
    
    /// Выбранный элемент меню
    var selectedMenuItem = 1
    
    
    override init() {
        super.init(style: UITableViewStyle.Plain)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.scrollEnabled = false
        tableView.separatorColor = UIColor(red: 178 / 255.0, green: 178 / 255.0, blue: 178 / 255.0, alpha: 1.0)
        tableView.tableFooterView = UIView(frame: CGRectZero)
        
        configureTableHeaderView()
        updateTableHeaderView()
        
        searchTableViewController = UINavigationController(rootViewController: ControllerManager.sharedInstance.searchTableViewController)
        favoritesTableViewController = UINavigationController(rootViewController: ControllerManager.sharedInstance.favoritesTableViewController)
    }
    
    /// MARK: - Вспомогательные методы
    
    /// Конфигурирует "шапку" таблицы
    func configureTableHeaderView() {
        tableHeaderView = UIView(frame: CGRectMake(0.0, 0.0, tableView.frame.size.width, 2 * 50.0))
        
        /// Добавление градиента
        let gradient = CAGradientLayer()
        gradient.frame = tableHeaderView.bounds
        gradient.colors = [
            UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1.0).CGColor,
            UIColor(red: 72 / 255.0, green: 86 / 255.0, blue: 97 / 255.0, alpha: 1.0).CGColor
        ]
        tableHeaderView.layer.insertSublayer(gradient, atIndex: 0)
        
        tableView.tableHeaderView = tableHeaderView
        
        activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .White)
        activityIndicatorView.center = CGPointMake(SlideMenuOption().leftViewWidth / 2, tableHeaderView.frame.height / 2)
        tableHeaderView.addSubview(activityIndicatorView)
        
        let separatorView = UIView(frame: CGRectMake(0, tableHeaderView.frame.size.height, tableHeaderView.frame.size.width, -0.5))
        separatorView.backgroundColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1.0)
        tableHeaderView.addSubview(separatorView)
    }
    
    /// Обновляет "шапку таблицы"
    func updateTableHeaderView() {
        let avatarPath = NSHomeDirectory().stringByAppendingFormat("/Documents/avatar.jpg")
        
        if NSFileManager.defaultManager().fileExistsAtPath(avatarPath) {
            showAvatar(UIImage(contentsOfFile: avatarPath)!)
            
            if let fullName = NSUserDefaults.standardUserDefaults().stringForKey("fullName") {
                showFullNameLabel(fullName)
                
                println("Полное имя и аватар взяты из кэша")
            }
            
            showLogOutButton()
            
            return
        }
        
        if let accessToken = NSUserDefaults.standardUserDefaults().stringForKey("accessToken") {
            MisisBooksApi.getAccountInformation(accessToken) {
                (json) -> Void in
                if json != nil {
                    if let response = json!["response"] as? NSDictionary {
                        if let user = response["user"] as? NSDictionary {
                            self.activityIndicatorView.stopAnimating()
                            
                            if let fullName = user["view_name"] as? String {
                                let standardUserDefaults = NSUserDefaults.standardUserDefaults()
                                standardUserDefaults.setObject(fullName, forKey: "fullName")
                                standardUserDefaults.synchronize()
                                
                                self.showFullNameLabel(fullName)
                            }
                            
                            if let photo = user["photo"] as? String {
                                dispatch_async(dispatch_get_main_queue()) {
                                    if let imageUrl = NSURL(string: photo) {
                                        if let imageData = NSData(contentsOfURL: imageUrl) {
                                            if let image = UIImage(data: imageData) {
                                                UIImageJPEGRepresentation(image, 100).writeToFile(avatarPath, atomically: true)
                                                
                                                self.showAvatar(image)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            self.showLogOutButton()
                        }
                    }
                }
            }
        } else {
            showLogInButton()
        }
    }
    
    /// Показывает кнопку авторизации
    func showLogInButton() {
        logInButton = CustomButton(title: "Авторизоваться", color: UIColor.whiteColor())
        logInButton.addTarget(self, action: Selector("logInButtonPressed"), forControlEvents: .TouchUpInside)
        logInButton.center = CGPointMake(SlideMenuOption().leftViewWidth / 2, tableHeaderView.frame.height / 2)
        tableHeaderView.addSubview(logInButton)
    }
    
    /// Показывает кнопку выхода
    func showLogOutButton() {
        logOutButton = CustomButton(title: "Выйти", color: UIColor.whiteColor())
        logOutButton.addTarget(self, action: Selector("logOutButtonPressed"), forControlEvents: .TouchUpInside)
        logOutButton.center = CGPointMake(
            SlideMenuOption().leftViewWidth - logOutButton.frame.width / 2 - 10.0, logOutButton.frame.height / 2 + 10.0)
        tableHeaderView.addSubview(logOutButton)
    }
    
    /// Показывает аватар
    ///
    /// :param: avatar Аватар
    func showAvatar(avatar: UIImage) {
        avatarView = UIImageView(image: avatar)
        avatarView.layer.borderColor = UIColor.whiteColor().CGColor
        avatarView.layer.borderWidth = 1.0
        avatarView.frame = CGRectMake(15.0, 30.0, 55.0, 55.0)
        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = avatarView.frame.size.width / 2
        avatarView.center = CGPointMake(SlideMenuOption().leftViewWidth / 2, tableHeaderView.frame.height / 2 - 10.0)
        
        UIView.transitionWithView(tableHeaderView, duration: 0.3, options: .TransitionCrossDissolve, animations: {
            self.tableHeaderView.addSubview(self.avatarView)
        }, completion: nil)
    }
    
    /// Показывает поле с полным именем
    ///
    /// :param: fullName Полное имя
    func showFullNameLabel(fullName: String) {
        fullNameLabel = UILabel(frame: CGRectZero)
        fullNameLabel.font = UIFont(name: "HelveticaNeue", size: 14.0)
        fullNameLabel.text = fullName
        fullNameLabel.textColor = UIColor(red: 79 / 255.0, green: 97 / 255.0, blue: 115 / 255.0, alpha: 1.0)
        fullNameLabel.textColor = UIColor.whiteColor()
        fullNameLabel.numberOfLines = 1
        fullNameLabel.sizeToFit()
        fullNameLabel.center = CGPointMake(SlideMenuOption().leftViewWidth / 2, tableHeaderView.frame.height / 2 + 30.0)
        tableHeaderView.addSubview(fullNameLabel)
        
        UIView.transitionWithView(tableHeaderView, duration: 0.3, options: .TransitionCrossDissolve, animations: {
            self.tableHeaderView.addSubview(self.fullNameLabel)
            }, completion: nil)
    }
    
    /// Обрабатывает событие, когда была нажата кнопка авторизации
    func logInButtonPressed() {
        UIView.transitionWithView(tableHeaderView, duration: 0.3, options: .TransitionCrossDissolve, animations: {
            self.logInButton.hidden = true
        }, completion: nil)
        
        activityIndicatorView.startAnimating()
        
        var vkLogInViewController = VkAuthorizationViewController()
        vkLogInViewController.delegate = self
        
        var viewControllerToPresent = UINavigationController(rootViewController: vkLogInViewController)
        viewControllerToPresent.modalTransitionStyle = .CoverVertical
        presentViewController(viewControllerToPresent, animated: true, completion: nil)
    }
    
    /// Обрабатывает событие, когда была нажата кнопка выхода
    func logOutButtonPressed() {
        let alertView = UIAlertView(title: "", message: "Вы действительно хотите выйти? Все загруженные документы будут удалены. Приложение вернется к первоначальному состоянию", delegate: self, cancelButtonTitle: nil, otherButtonTitles: "Выйти", "Отмена")
        alertView.show()
    }
    
    /// Подсвечивает картинку и текст ячейки, а прошлую делает обычной
    ///
    /// :param: indexPath Индекс ячейки
    func highlightRowAtIndexPath(indexPath: NSIndexPath) {
        let normalColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1.0)
        let highlightColor = UIColor(red: 0 / 255.0, green: 138 / 255.0, blue: 190 / 255.0, alpha: 1.0)
        
        let previousCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: selectedMenuItem, inSection: 0))
        previousCell?.imageView?.tintColor = normalColor
        previousCell?.textLabel?.textColor = normalColor
        
        let newCell = tableView.cellForRowAtIndexPath(indexPath)
        newCell?.imageView?.tintColor = highlightColor
        newCell?.textLabel?.textColor = highlightColor
        
        selectedMenuItem = indexPath.item
    }
    
    /// MARK: - Методы UIAlertViewDelegate
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 0 { // "Выйти"
            UIView.transitionWithView(tableHeaderView, duration: 0.3, options: .TransitionCrossDissolve, animations: {
                self.logInButton?.removeFromSuperview()
                self.showLogInButton()
                self.logOutButton.hidden = true
                self.avatarView.removeFromSuperview()
                self.fullNameLabel.removeFromSuperview()
                }, completion: nil)
            
            let standardUserDefaults = NSUserDefaults.standardUserDefaults()
            standardUserDefaults.removeObjectForKey("accessToken")
            standardUserDefaults.removeObjectForKey("vkAccessToken")
            standardUserDefaults.removeObjectForKey("vkUserId")
            standardUserDefaults.removeObjectForKey("fullName")
            standardUserDefaults.synchronize()
            
            let avatarPath = NSHomeDirectory().stringByAppendingFormat("/Documents/avatar.jpg")
            NSFileManager.defaultManager().removeItemAtPath(avatarPath, error: nil)
            
            let currentDownloads = DownloadManager.getCurrentDownloads()
            
            for currentDownload in currentDownloads {
                currentDownload.task.cancel()
            }
            
            ControllerManager.sharedInstance.downloadsTableViewController.deleteAllBooksFromDownloads()
            ControllerManager.sharedInstance.favoritesTableViewController.deleteAllBooksFromFavorites()
            
            MisisBooksApi.sharedInstance.accessToken = nil
            MisisBooksApi.sharedInstance.getPopular(count: 20, category: 1)
        }
    }
    
    /// MARK: - Методы UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let titles = ["Поиск", "Загрузки", "Избранное"]
        let images = ["Search", "Downloads", "Favorites"]
        let image = UIImage(named: images[indexPath.row])
        let color = indexPath.item != selectedMenuItem ?
            UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1.0) :
            UIColor(red: 0 / 255.0, green: 138 / 255.0, blue: 190 / 255.0, alpha: 1.0)
        
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as UITableViewCell
        cell.imageView?.image = image!.imageWithRenderingMode(.AlwaysTemplate)
        cell.imageView?.tintColor = color
        cell.textLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 16.0)
        cell.textLabel?.text = titles[indexPath.row]
        cell.textLabel?.textColor = color
        
        return cell
    }
    
    /// MARK: - Методы UITableViewDelegate
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44.0
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        highlightRowAtIndexPath(indexPath)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        switch indexPath.item {
        case 0:
            ControllerManager.sharedInstance.slideMenuController.changeMainViewController(searchTableViewController, close: true)
            break
        case 1:
            ControllerManager.sharedInstance.slideMenuController.changeMainViewController(downloadsTableViewController, close: true)
            break
        case 2:
            ControllerManager.sharedInstance.slideMenuController.changeMainViewController(favoritesTableViewController, close: true)
            break
        default:
            break
        }
    }
    
    /// MARK: - Методы VkLogInViewControllerDelegate
    
    func vkAuthorizationViewControllerLogInSucceeded(vkAccessToken: String, vkUserId: String) {
        println("Маркер доступа VK: \(vkAccessToken)\nИдентификатор пользователя VK: \(vkUserId)")
        
        let standardUserDefaults = NSUserDefaults.standardUserDefaults()
        standardUserDefaults.setObject(vkAccessToken, forKey: "vkAccessToken")
        standardUserDefaults.setObject(vkUserId, forKey: "vkUserId")
        standardUserDefaults.synchronize()
        
        MisisBooksApi.sharedInstance.signIn {
            if ControllerManager.sharedInstance.searchTableViewController.action == MisisBooksApiAction.GetPopular {
                MisisBooksApi.sharedInstance.getPopular(count: 20, category: 1)
            }
        }
    }
    
    func vkAuthorizationViewControllerLogInFailed() {
        println("Авторизация через ВКонтакте не удалась")
        
        logInButton.hidden = false
        activityIndicatorView.stopAnimating()
    }
}
