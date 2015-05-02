//
//  MenuViewController.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 26.01.15.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit

class MenuTableViewController: UITableViewController, UIAlertViewDelegate {
    
    /// Индикатор активности
    var activityIndicatorView: UIActivityIndicatorView!
    
    /// Аватар
    var avatarView: UIImageView!
    
    /// Навигационный контроллер загрузок
    var downloadsTableViewNavigationController: UIViewController!
    
    /// Навигационный контроллер избранного
    var favoritesTableViewNavigationController: UIViewController!
    
    /// Поле с полным именем
    var fullNameLabel: UILabel!
    
    /// Кнопка авторизации
    var logInButton: CustomButton!
    
    /// Кнопка выхода
    var logOutButton: CustomButton!
    
    /// Навигационный контроллер поиска
    var searchTableViewNavigationController: UIViewController!
    
    /// Выбранный элемент меню
    var selectedMenuItem = 1
    
    /// "Шапка" таблицы
    var tableHeaderView: UIView!
    
    override init(style: UITableViewStyle) {
        super.init(style: style)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.scrollEnabled = false
        tableView.separatorColor = UIColor(red: 178 / 255.0, green: 178 / 255.0, blue: 178 / 255.0, alpha: 1)
        tableView.tableFooterView = UIView(frame: CGRectZero)
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        configureTableHeaderView()
        updateTableHeaderView()
        
        searchTableViewNavigationController = UINavigationController(
            rootViewController: ControllerManager.instance.searchTableViewController)
        favoritesTableViewNavigationController = UINavigationController(
            rootViewController: ControllerManager.instance.favoritesTableViewController)
    }
    
    /// Подсвечивает картинку и текст ячейки, а прошлую делает обычной
    ///
    /// :param: indexPath Индекс ячейки
    func highlightRowAtIndexPath(indexPath: NSIndexPath) {
        let normalColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1)
        let previousCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: selectedMenuItem, inSection: 0))
        previousCell?.imageView?.tintColor = normalColor
        previousCell?.textLabel?.textColor = normalColor
        
        let highlightColor = UIColor(red: 0 / 255.0, green: 138 / 255.0, blue: 190 / 255.0, alpha: 1)
        let newCell = tableView.cellForRowAtIndexPath(indexPath)
        newCell?.imageView?.tintColor = highlightColor
        newCell?.textLabel?.textColor = highlightColor
        
        selectedMenuItem = indexPath.item
    }
    
    /// Обрабатывает событие, когда нажата кнопка авторизации
    func logInButtonPressed() {
        UIView.transitionWithView(tableHeaderView, duration: 0.3, options: .TransitionCrossDissolve, animations: {
            self.logInButton.hidden = true
            }, completion: nil)
        
        activityIndicatorView.startAnimating()
        
        let viewControllerToPresent = UINavigationController(rootViewController: VkAuthorizationViewController())
        viewControllerToPresent.modalTransitionStyle = .CoverVertical
        presentViewController(viewControllerToPresent, animated: true, completion: nil)
    }
    
    /// Обрабатывает событие, когда нажата кнопка выхода
    func logOutButtonPressed() {
        UIAlertView(title: "", message: "Вы действительно хотите выйти? Все загруженные документы будут удалены. " +
            "Приложение вернется к первоначальному состоянию", delegate: self, cancelButtonTitle: nil, otherButtonTitles: "Выйти",
            "Отмена").show()
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
            MisisBooksApi.getAccountInformation(accessToken) { json in
                if json != nil {
                    if let response = json!["response"] as? NSDictionary, user = response["user"] as? NSDictionary {
                        self.activityIndicatorView.stopAnimating()
                        
                        if let fullName = user["view_name"] as? String, photo = user["photo"] as? String {
                            let standardUserDefaults = NSUserDefaults.standardUserDefaults()
                            standardUserDefaults.setObject(fullName, forKey: "fullName")
                            standardUserDefaults.synchronize()
                            
                            self.showFullNameLabel(fullName)
                            
                            dispatch_async(dispatch_get_main_queue()) {
                                if let imageUrl = NSURL(string: photo), imageData = NSData(contentsOfURL: imageUrl),
                                    image = UIImage(data: imageData) {
                                        UIImageJPEGRepresentation(image, 100).writeToFile(avatarPath, atomically: true)
                                        
                                        self.showAvatar(image)
                                }
                            }
                        }
                        
                        self.showLogOutButton()
                    }
                }
            }
        } else {
            showLogInButton()
        }
    }
    
    func vkLogInFailed() {
        println("Авторизация через ВКонтакте не удалась")
        
        logInButton.hidden = false
        activityIndicatorView.stopAnimating()
    }
    
    func vkLogInSucceeded(#vkAccessToken: String, vkUserId: String) {
        println("Маркер доступа VK: \(vkAccessToken)\nИдентификатор пользователя VK: \(vkUserId)")
        
        let standardUserDefaults = NSUserDefaults.standardUserDefaults()
        standardUserDefaults.setObject(vkAccessToken, forKey: "vkAccessToken")
        standardUserDefaults.setObject(vkUserId, forKey: "vkUserId")
        standardUserDefaults.synchronize()
        
        MisisBooksApi.instance.signIn {
            if ControllerManager.instance.searchTableViewController.action == MisisBooksApiAction.GetPopular {
                MisisBooksApi.instance.getPopular(count: 20, categoryId: 1)
            }
            
            if ControllerManager.instance.favoritesTableViewController.isControllerReady {
                if ControllerManager.instance.favoritesTableViewController.action == MisisBooksApiAction.GetFavorites {
                    MisisBooksApi.instance.getFavorites(count: 20, offset: 0)
                }
            }
        }
    }
    
    /// MARK: - Внутренние методы
    
    /// Конфигурирует "шапку" таблицы
    private func configureTableHeaderView() {
        tableHeaderView = UIView(frame: CGRectMake(0, 0, tableView.frame.size.width, 100))
        
        let gradient = CAGradientLayer()
        gradient.frame = tableHeaderView.bounds
        gradient.colors = [UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1).CGColor,
            UIColor(red: 72 / 255.0, green: 86 / 255.0, blue: 97 / 255.0, alpha: 1).CGColor]
        tableHeaderView.layer.insertSublayer(gradient, atIndex: 0)
        
        activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .White)
        activityIndicatorView.center = CGPointMake(SlideMenuOption().leftViewWidth / 2, tableHeaderView.frame.height / 2)
        tableHeaderView.addSubview(activityIndicatorView)
        
        let separatorView = UIView(frame: CGRectMake(0, tableHeaderView.frame.size.height,
            tableHeaderView.frame.size.width, -0.5))
        separatorView.backgroundColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1)
        tableHeaderView.addSubview(separatorView)
        
        tableView.tableHeaderView = tableHeaderView
    }
    
    /// Показывает аватар
    ///
    /// :param: avatar Аватар
    private func showAvatar(avatar: UIImage) {
        avatarView = UIImageView(image: avatar)
        avatarView.layer.borderColor = UIColor.whiteColor().CGColor
        avatarView.layer.borderWidth = 1
        avatarView.frame = CGRectMake(15, 30, 55, 55)
        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = avatarView.frame.size.width / 2
        avatarView.center = CGPointMake(SlideMenuOption().leftViewWidth / 2, tableHeaderView.frame.height / 2 - 10)
        
        UIView.transitionWithView(tableHeaderView, duration: 0.3, options: .TransitionCrossDissolve, animations: {
            self.tableHeaderView.addSubview(self.avatarView)
            }, completion: nil)
    }
    
    /// Показывает поле с полным именем
    ///
    /// :param: fullName Полное имя
    private func showFullNameLabel(fullName: String) {
        fullNameLabel = UILabel(frame: CGRectZero)
        fullNameLabel.font = UIFont(name: "HelveticaNeue", size: 14)
        fullNameLabel.text = fullName
        fullNameLabel.textColor = UIColor(red: 79 / 255.0, green: 97 / 255.0, blue: 115 / 255.0, alpha: 1)
        fullNameLabel.textColor = .whiteColor()
        fullNameLabel.numberOfLines = 1
        fullNameLabel.sizeToFit()
        fullNameLabel.center = CGPointMake(SlideMenuOption().leftViewWidth / 2, tableHeaderView.frame.height / 2 + 30)
        tableHeaderView.addSubview(fullNameLabel)
        
        UIView.transitionWithView(tableHeaderView, duration: 0.3, options: .TransitionCrossDissolve, animations: {
            self.tableHeaderView.addSubview(self.fullNameLabel)
            }, completion: nil)
    }
    
    /// Показывает кнопку авторизации
    private func showLogInButton() {
        logInButton = CustomButton(title: "Авторизоваться", color: .whiteColor())
        logInButton.addTarget(self, action: Selector("logInButtonPressed"), forControlEvents: .TouchUpInside)
        logInButton.center = CGPointMake(SlideMenuOption().leftViewWidth / 2, tableHeaderView.frame.height / 2)
        tableHeaderView.addSubview(logInButton)
    }
    
    /// Показывает кнопку выхода
    private func showLogOutButton() {
        logOutButton = CustomButton(title: "Выйти", color: .whiteColor())
        logOutButton.addTarget(self, action: Selector("logOutButtonPressed"), forControlEvents: .TouchUpInside)
        logOutButton.center = CGPointMake(SlideMenuOption().leftViewWidth - logOutButton.frame.width / 2 - 10,
            logOutButton.frame.height / 2 + 10)
        tableHeaderView.addSubview(logOutButton)
    }
    
    /// MARK: - Методы UITableViewDataSource
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let titles = ["Поиск", "Загрузки", "Избранное"]
        let images = ["Search", "Downloads", "Favorites"]
        let image = UIImage(named: images[indexPath.row])
        let color = indexPath.item != selectedMenuItem ?
            UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1) :
            UIColor(red: 0 / 255.0, green: 138 / 255.0, blue: 190 / 255.0, alpha: 1)
        
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! UITableViewCell
        cell.imageView?.image = image!.imageWithRenderingMode(.AlwaysTemplate)
        cell.imageView?.tintColor = color
        cell.textLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 16)
        cell.textLabel?.text = titles[indexPath.row]
        cell.textLabel?.textColor = color
        
        return cell
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    /// MARK: - Методы UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        highlightRowAtIndexPath(indexPath)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        switch indexPath.item {
        case 0:
            ControllerManager.instance.slideMenuController.changeMainViewController(searchTableViewNavigationController,
                close: true)
            break
        case 1:
            ControllerManager.instance.slideMenuController.changeMainViewController(downloadsTableViewNavigationController,
                close: true)
            break
        case 2:
            ControllerManager.instance.slideMenuController.changeMainViewController(favoritesTableViewNavigationController,
                close: true)
            break
        default:
            break
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44
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
            
            for currentDownload in DownloadManager.getCurrentDownloads() {
                currentDownload.task.cancel()
            }
            
            ControllerManager.instance.downloadsTableViewController.deleteAllBooks()
            ControllerManager.instance.favoritesTableViewController.deleteAllBooks()
            
            MisisBooksApi.instance.accessToken = nil
            MisisBooksApi.instance.getPopular(count: 20, categoryId: 1)
        }
    }
}
