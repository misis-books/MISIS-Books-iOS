//
//  MenuViewController.swift
//  misisbooks
//
//  Created by Maxim Loskov on 26.01.15.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit

class MenuTableViewController : UITableViewController, VkLogInViewControllerDelegate {
    
    /// Названия пунктов меню
    var menuItems = ["Поиск",
        "Загрузки",
        "Избранное"]
    
    /// Контроллер поиска
    var searchTableViewController : UIViewController!
    
    /// Контроллер загрузок
    var downloadsTableViewController : UIViewController!
    
    /// Контроллер избранного
    var favoritesTableViewController : UIViewController!
    
    var misisBooksApi : MisisBooksApi!
    
    var tableHeaderView : UIView!
    
    /// Кнопка "Авторизоваться"
    var logInButton : UIButton!
    
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
        
        self.tableView.scrollEnabled = false
        self.tableView.separatorColor = UIColor(red: 178 / 255.0, green: 178 / 255.0, blue: 178 / 255.0, alpha: 1.0)
        self.tableView.tableFooterView = UIView(frame: CGRectZero)

        updateTableHeaderView()
        
        // downloadsTableViewController = UINavigationController(rootViewController: ControllerManager.instance.downloadsTableViewController)
        searchTableViewController = UINavigationController(rootViewController: ControllerManager.instance.searchTableViewController)
        favoritesTableViewController = UINavigationController(rootViewController: ControllerManager.instance.favoritesTableViewController)
        
        misisBooksApi = MisisBooksApi()
        ControllerManager.instance.searchTableViewController.misisBooksApi = misisBooksApi
    }
    
    /// MARK: - Вспомогательные методы
    
    func updateTableHeaderView() {
        tableHeaderView = UIView(frame: CGRectMake(0.0, 0.0, self.tableView.frame.size.width, 2 * 50.0))
        
        /// Добавление градиента в "шапку" таблицы
        let gradient = CAGradientLayer()
        gradient.frame = tableHeaderView.bounds
        gradient.colors = [
            UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1.0).CGColor,
            UIColor(red: 72 / 255.0, green: 86 / 255.0, blue: 97 / 255.0, alpha: 1.0).CGColor
        ]
        tableHeaderView.layer.insertSublayer(gradient, atIndex: 0)
        
        /* UIGraphicsBeginImageContext(tableHeaderView.frame.size)
        UIImage(named: "menu_background")?.drawInRect(tableHeaderView.bounds)
        let menuBackgroundImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        tableHeaderView.backgroundColor = UIColor(patternImage: menuBackgroundImage) */
        
        self.tableView.tableHeaderView = tableHeaderView
        
        activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        activityIndicatorView.center = CGPointMake(SlideMenuOption().leftViewWidth / 2, self.tableHeaderView.frame.height / 2)
        tableHeaderView.addSubview(activityIndicatorView)
        
        let separatorView = UIView(frame: CGRectMake(0, tableHeaderView.frame.size.height, tableHeaderView.frame.size.width, -0.5))
        separatorView.backgroundColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1.0)
        tableHeaderView.addSubview(separatorView)
        
        if let accessToken = NSUserDefaults.standardUserDefaults().stringForKey("accessToken") {
            let urlString = "http://twosphere.ru/api/account.getInfo?access_token=\(accessToken)"
            let request = NSMutableURLRequest(URL: NSURL(string: urlString)!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 10.0)
            
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {
                connectionResponse, connectionData, connectionError in
                if connectionError == nil {
                    var jsonError : NSError?
                    let jsonDictionary = NSJSONSerialization.JSONObjectWithData(connectionData, options: NSJSONReadingOptions.MutableContainers, error: &jsonError) as NSDictionary
                    
                    if jsonError == nil {
                        if let response = jsonDictionary["response"] as? NSDictionary {
                            if let user = response["user"] as? NSDictionary {
                                self.activityIndicatorView.stopAnimating()
                                
                                /// TODO: Сохранить изображение пользователя в файловое хранилище, а полное имя в standardUserDefaults, чтобы их показывать только оттуда
                                
                                if let fullName = user["view_name"] as? String {
                                    let fullNameLabel = UILabel(frame: CGRectZero)
                                    fullNameLabel.font = UIFont(name: "HelveticaNeue", size: 14.0)
                                    fullNameLabel.text = fullName
                                    fullNameLabel.textColor = UIColor(red: 79 / 255.0, green: 97 / 255.0, blue: 115 / 255.0, alpha: 1.0)
                                    fullNameLabel.textColor = UIColor.whiteColor()
                                    fullNameLabel.numberOfLines = 1
                                    fullNameLabel.sizeToFit()
                                    fullNameLabel.center = CGPointMake(SlideMenuOption().leftViewWidth / 2, self.tableHeaderView.frame.height / 2 + 30.0)
                                    self.tableHeaderView.addSubview(fullNameLabel)
                                }
                                
                                if let photo = user["photo"] as? String {
                                    dispatch_async(dispatch_get_main_queue()) {
                                        if let imageUrl = NSURL(string: photo) {
                                            if let imageData = NSData(contentsOfURL: imageUrl) {
                                                if let image = UIImage(data: imageData) {
                                                    let imageView = UIImageView(image: image)
                                                    imageView.layer.borderColor = UIColor.whiteColor().CGColor
                                                    imageView.layer.borderWidth = 1.0
                                                    imageView.frame = CGRectMake(15.0, 30.0, 55.0, 55.0)
                                                    imageView.clipsToBounds = true
                                                    imageView.layer.cornerRadius = imageView.frame.size.width / 2
                                                    imageView.center = CGPointMake(SlideMenuOption().leftViewWidth / 2, self.tableHeaderView.frame.height / 2 - 10.0)
                                                    self.tableHeaderView.addSubview(imageView)
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                let logOutButton = UIButton(frame: CGRectZero)
                                logOutButton.addTarget(self, action: Selector("logOutButtonPressed"), forControlEvents: UIControlEvents.TouchDown)
                                logOutButton.setTitle("Выйти", forState: UIControlState.Normal)
                                logOutButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
                                logOutButton.backgroundColor = UIColor.clearColor()
                                logOutButton.contentEdgeInsets = UIEdgeInsetsMake(6.0, 8.0, 6.0, 8.0)
                                logOutButton.titleLabel?.font = UIFont(name: "HelveticaNeue", size: 14.0)
                                logOutButton.layer.borderWidth = 1.0
                                logOutButton.layer.borderColor = UIColor.whiteColor().CGColor
                                logOutButton.layer.cornerRadius = 2.0
                                logOutButton.sizeToFit()
                                logOutButton.center = CGPointMake(SlideMenuOption().leftViewWidth - logOutButton.frame.width / 2 - 10.0, logOutButton.frame.height / 2 + 10.0)
                                self.tableHeaderView.addSubview(logOutButton)
                            }
                        }
                    }
                }
            })
        } else {
            logInButton = UIButton(frame: CGRectZero)
            logInButton.addTarget(self, action: Selector("logInButtonPressed"), forControlEvents: UIControlEvents.TouchDown)
            logInButton.setTitle("Авторизоваться", forState: UIControlState.Normal)
            logInButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
            logInButton.backgroundColor = UIColor.clearColor()
            logInButton.contentEdgeInsets = UIEdgeInsetsMake(6.0, 8.0, 6.0, 8.0)
            logInButton.titleLabel?.font = UIFont(name: "HelveticaNeue", size: 14.0)
            logInButton.layer.borderWidth = 1.0
            logInButton.layer.borderColor = UIColor.whiteColor().CGColor
            logInButton.layer.cornerRadius = 2.0
            logInButton.sizeToFit()
            logInButton.center = CGPointMake(SlideMenuOption().leftViewWidth / 2, self.tableHeaderView.frame.height / 2)
            tableHeaderView.addSubview(logInButton)
        }
    }
    
    /// Обрабатывает событие, когда была нажата кнопка авторизации
    func logInButtonPressed() {
        logInButton.hidden = true
        activityIndicatorView.startAnimating()
        
        var vkLogInViewController = VkLogInViewController()
        vkLogInViewController.delegate = self
        
        var presentViewController = UINavigationController(rootViewController: vkLogInViewController)
        presentViewController.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
        self.presentViewController(presentViewController, animated: true, completion: nil)
    }
    
    /// Обрабатывает событие, когда была нажата кнопка выхода
    func logOutButtonPressed() {
        /// TODO: Как мы будем выходить?
    }
    
    /// Подсвечивает картинку и текст ячейки, а ранее подсвеченную ячейку делает обычной
    ///
    /// :param: indexPath Индекс ячейки
    func highlightRowAtIndexPath(indexPath: NSIndexPath) {
        if let oldCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: selectedMenuItem, inSection: 0)) {
            let oldImageView = oldCell.viewWithTag(1) as UIImageView
            oldImageView.tintColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1.0)
            
            let oldItemLabel = oldCell.viewWithTag(2) as UILabel
            oldItemLabel.textColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1.0)
        }
        
        if let newCell = tableView.cellForRowAtIndexPath(indexPath) {
            let newImageView = newCell.viewWithTag(1) as UIImageView
            newImageView.tintColor = UIColor(red: 0 / 255.0, green: 138 / 255.0, blue: 190 / 255.0, alpha: 1.0)
            
            let newItemLabel = newCell.viewWithTag(2) as UILabel
            newItemLabel.textColor = UIColor(red: 0 / 255.0, green: 138 / 255.0, blue: 190 / 255.0, alpha: 1.0)
        }
        
        selectedMenuItem = indexPath.item
    }
    
    /// MARK: - Методы VkLogInViewControllerDelegate
    
    func vkLogInViewControllerAuthorizationSucceeded(vkAccessToken: String, vkUserId: String) {
        println("Маркер доступа VK: \(vkAccessToken)\nИдентификатор пользователя VK: \(vkUserId)")
        
        let standardUserDefaults = NSUserDefaults.standardUserDefaults()
        standardUserDefaults.setObject(vkAccessToken, forKey: "vkAccessToken")
        standardUserDefaults.setObject(vkUserId, forKey: "vkUserId")
        standardUserDefaults.synchronize()
        
        misisBooksApi.signIn {
            // TODO: Проверить, инициализирован ли контроллер поиска, и только потом выполнить запрос на получение популярных книг
            // self.misisBooksApi.getPopular(count: 20, category: 1)
        }
    }
    
    func vkLogInViewControllerAuthorizationFailed() {
        println("Авторизация через ВКонтакте не удалась")
        
        logInButton.hidden = false
        activityIndicatorView.stopAnimating()
    }
    
    /// MARK: - Методы UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("Cell") as? UITableViewCell
        
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "Cell")
            
            let contentColor = indexPath.item != selectedMenuItem ? UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1.0) : UIColor(red: 0 / 255.0, green: 138 / 255.0, blue: 190 / 255.0, alpha: 1.0)
            let menuIcons = ["Search", "Downloads", "Favorites"]
            
            let imageView = UIImageView(frame: CGRectMake(15.0, 13.0, 18.0, 18.0))
            imageView.image = UIImage(named: menuIcons[indexPath.row])!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
            imageView.tintColor = contentColor
            imageView.tag = 1
            cell!.contentView.addSubview(imageView)
            
            let itemLabel = UILabel(frame: CGRectMake(48.0, 12.5, 0.0, 0.0))
            itemLabel.font = UIFont(name: "HelveticaNeue-Light", size: 16.0)
            itemLabel.text = menuItems[indexPath.row]
            itemLabel.textColor = contentColor
            itemLabel.tag = 2
            itemLabel.sizeToFit()
            cell!.contentView.addSubview(itemLabel)
        }
        
        cell!.backgroundColor = UIColor.clearColor()
        
        return cell!
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
            ControllerManager.instance.slideMenuController.changeMainViewController(searchTableViewController, close: true)
            break
        case 1:
            ControllerManager.instance.slideMenuController.changeMainViewController(downloadsTableViewController, close: true)
            break
        case 2:
            ControllerManager.instance.slideMenuController.changeMainViewController(favoritesTableViewController, close: true)
            break
        default:
            break
        }
    }
}
