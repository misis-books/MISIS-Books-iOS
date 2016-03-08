//
//  MenuViewController.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 26.01.15.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit

/**
    Класс для представления контроллера меню
*/
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

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.scrollEnabled = false
        tableView.separatorColor = UIColor(red: 178 / 255.0, green: 178 / 255.0, blue: 178 / 255.0, alpha: 1)
        tableView.tableFooterView = UIView()
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")

        tableHeaderView = UIView(frame: CGRectMake(0, 0, tableView.frame.size.width, 100))

        let gradient = CAGradientLayer()
        gradient.frame = tableHeaderView.bounds
        gradient.colors = [UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1).CGColor,
            UIColor(red: 72 / 255.0, green: 86 / 255.0, blue: 97 / 255.0, alpha: 1).CGColor]
        tableHeaderView.layer.insertSublayer(gradient, atIndex: 0)

        activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .White)
        activityIndicatorView.center = CGPointMake(SlideMenuOption().menuViewWidth / 2,
            tableHeaderView.frame.height / 2)
        tableHeaderView.addSubview(activityIndicatorView)

        logInButton = CustomButton(title: "Авторизоваться", color: .whiteColor())
        logInButton.addTarget(self, action: "logInButtonPressed", forControlEvents: .TouchUpInside)
        logInButton.center = CGPointMake(SlideMenuOption().menuViewWidth / 2, tableHeaderView.frame.height / 2)
        tableHeaderView.addSubview(logInButton)

        logOutButton = CustomButton(title: "Выйти", color: .whiteColor())
        logOutButton.addTarget(self, action: "logOutButtonPressed", forControlEvents: .TouchUpInside)
        logOutButton.center = CGPointMake(SlideMenuOption().menuViewWidth - logOutButton.frame.width / 2 - 10,
            logOutButton.frame.height / 2 + 10)
        logOutButton.hidden = true
        tableHeaderView.addSubview(logOutButton)

        let separatorView = UIView(frame: CGRectMake(0, tableHeaderView.frame.size.height,
            tableHeaderView.frame.size.width, -0.5))
        separatorView.backgroundColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1)
        tableHeaderView.addSubview(separatorView)

        tableView.tableHeaderView = tableHeaderView

        updateTableHeaderView()

        searchTableViewNavigationController = UINavigationController(
            rootViewController: ControllerManager.instance.searchTableViewController)
        favoritesTableViewNavigationController = UINavigationController(
            rootViewController: ControllerManager.instance.favoritesTableViewController)
    }

    /**
        Подсвечивает картинку и текст ячейки, а прошлую делает обычной

        - parameter indexPath: Индекс ячейки
    */
    func highlightRowAtIndexPath(indexPath: NSIndexPath) {
        let normalColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1)
        let previousCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: selectedMenuItem, inSection: 0))
        previousCell?.imageView?.tintColor = normalColor
        previousCell?.textLabel?.textColor = normalColor

        let highlightColor = UIColor(red: 0, green: 138 / 255.0, blue: 190 / 255.0, alpha: 1)
        let newCell = tableView.cellForRowAtIndexPath(indexPath)
        newCell?.imageView?.tintColor = highlightColor
        newCell?.textLabel?.textColor = highlightColor

        selectedMenuItem = indexPath.item
    }

    /**
        Обрабатывает событие, когда нажата кнопка авторизации
    */
    func logInButtonPressed() {
        activityIndicatorView.startAnimating()

        UIView.transitionWithView(tableHeaderView, duration: 0.3, options: .TransitionCrossDissolve, animations: {
            self.logInButton.hidden = true
            }, completion: nil)

        let viewControllerToPresent = UINavigationController(rootViewController: VkAuthorizationViewController())
        viewControllerToPresent.modalTransitionStyle = .CoverVertical
        presentViewController(viewControllerToPresent, animated: true, completion: nil)
    }

    /**
        Обрабатывает событие, когда нажата кнопка выхода
    */
    func logOutButtonPressed() {
        UIAlertView(title: "", message: "Вы действительно хотите выйти? Все загруженные документы будут удалены. " +
            "Приложение вернется к первоначальному состоянию", delegate: self, cancelButtonTitle: nil,
            otherButtonTitles: "Выйти", "Отмена").show()
    }

    /**
        Обновляет "шапку" таблицы
    */
    func updateTableHeaderView() {
        let fileManager = NSFileManager.defaultManager()
        let avatarPath = NSURL(string: "avatar.jpg", relativeToURL: fileManager.URLsForDirectory(.DocumentDirectory,
            inDomains: .UserDomainMask)[0])!.path!

        if fileManager.fileExistsAtPath(avatarPath) {
            showAvatarViewWithImage(UIImage(contentsOfFile: avatarPath)!)

            if let fullName = NSUserDefaults.standardUserDefaults().stringForKey("fullName") {
                showLabelWithFullName(fullName)
            }

            logInButton.hidden = true
            logOutButton.hidden = false
        } else if MisisBooksApi.instance.accessToken != nil {
            MisisBooksApi.instance.getAccountInformation() { json in
                if json != nil {
                    if let response = json!["response"] as? [String: AnyObject],
                        user = response["user"] as? [String: AnyObject],
                        fullName = user["view_name"] as? String,
                        photoUrlString = user["photo"] as? String {
                            self.activityIndicatorView.stopAnimating()

                            let standardUserDefaults = NSUserDefaults.standardUserDefaults()
                            standardUserDefaults.setObject(fullName, forKey: "fullName")
                            standardUserDefaults.synchronize()

                            self.showLabelWithFullName(fullName)

                            dispatch_async(dispatch_get_main_queue()) {
                                if let imageUrl = NSURL(string: photoUrlString),
                                    imageData = NSData(contentsOfURL: imageUrl),
                                    image = UIImage(data: imageData) {
                                        UIImageJPEGRepresentation(image, 100)!.writeToFile(avatarPath, atomically: true)

                                        self.showAvatarViewWithImage(image)
                                }
                            }
                    }

                    self.logOutButton.hidden = false
                }
            }
        } else {
            logInButton.hidden = false
        }
    }

    /**
        Обрабатывает событие, когда авторизация через ВКонтакте не удалась
    */
    func vkLogInFailed() {
        print("Авторизация через ВКонтакте не удалась")

        logInButton.hidden = false
        activityIndicatorView.stopAnimating()
    }

    /**
        Обрабатывает событие, когда был успешно получен маркер доступа и идентификатор пользователя ВКонтакте

        - parameter vkAccessToken: Маркер доступа ВКонтакте
        - parameter vkUserId: Идентификатор пользователя ВКонтакте
    */
    func vkLogInSucceededWithVkAccessToken(vkAccessToken: String, vkUserId: String) {
        print("Маркер доступа ВКонтакте: \(vkAccessToken)\nИдентификатор пользователя ВКонтакте: \(vkUserId)")

        MisisBooksApi.instance.vkAccessToken = vkAccessToken

        MisisBooksApi.instance.signIn {
            let searchTableViewController = ControllerManager.instance.searchTableViewController
            let favoritesTableViewController = ControllerManager.instance.favoritesTableViewController

            if searchTableViewController.action == MisisBooksApiAction.GetPopular {
                searchTableViewController.activityIndicator?.startAnimating()
                searchTableViewController.placeholderView?.removeFromSuperview()
                searchTableViewController.placeholderView = nil
                MisisBooksApi.instance.getPopularBooksByCount(20, categoryId: 1)
            }

            if favoritesTableViewController.isReady &&
                favoritesTableViewController.action == MisisBooksApiAction.GetFavorites {
                    favoritesTableViewController.activityIndicator?.startAnimating()
                    favoritesTableViewController.placeholderView?.removeFromSuperview()
                    favoritesTableViewController.placeholderView = nil
                    MisisBooksApi.instance.getFavoritesByCount(20, offset: 0)
            }
        }
    }

    // MARK: - Внутренние методы

    /**
        Показывает аватар

        - parameter image: Картинка аватара
    */
    private func showAvatarViewWithImage(image: UIImage) {
        avatarView = UIImageView(image: image)
        avatarView.layer.borderColor = UIColor.whiteColor().CGColor
        avatarView.layer.borderWidth = 1
        avatarView.frame = CGRectMake(15, 30, 55, 55)
        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = avatarView.frame.size.width / 2
        avatarView.center = CGPointMake(SlideMenuOption().menuViewWidth / 2, tableHeaderView.frame.height / 2 - 10)

        UIView.transitionWithView(tableHeaderView, duration: 0.3, options: .TransitionCrossDissolve, animations: {
            self.tableHeaderView.addSubview(self.avatarView)
            }, completion: nil)
    }

    /**
        Показывает поле с полным именем

        - parameter fullName: Полное имя
    */
    private func showLabelWithFullName(fullName: String) {
        fullNameLabel = UILabel()
        fullNameLabel.font = UIFont(name: "HelveticaNeue", size: 14)
        fullNameLabel.text = fullName
        fullNameLabel.textColor = .whiteColor()
        fullNameLabel.numberOfLines = 1
        fullNameLabel.sizeToFit()
        fullNameLabel.center = CGPointMake(SlideMenuOption().menuViewWidth / 2, tableHeaderView.frame.height / 2 + 30)

        UIView.transitionWithView(tableHeaderView, duration: 0.3, options: .TransitionCrossDissolve, animations: {
            self.tableHeaderView.addSubview(self.fullNameLabel)
            }, completion: nil)
    }

    // MARK: - Методы UITableViewDataSource

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let titles = ["Поиск", "Загрузки", "Избранное"]
        let imageNames = ["Search", "Downloads", "Favorites"]
        let image = UIImage(named: imageNames[indexPath.row])
        let color = indexPath.item != selectedMenuItem ? UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0,
            alpha: 1) : UIColor(red: 0, green: 138 / 255.0, blue: 190 / 255.0, alpha: 1)

        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as UITableViewCell
        cell.imageView!.image = image!.imageWithRenderingMode(.AlwaysTemplate)
        cell.imageView!.tintColor = color
        cell.textLabel!.font = UIFont(name: "HelveticaNeue-Light", size: 16)
        cell.textLabel!.text = titles[indexPath.row]
        cell.textLabel!.textColor = color

        return cell
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    // MARK: - Методы UITableViewDelegate

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        highlightRowAtIndexPath(indexPath)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        switch indexPath.item {
        case 0:
            ControllerManager.instance.slideMenuController.changeMainViewController(searchTableViewNavigationController,
                close: true)
        case 1:
            ControllerManager.instance.slideMenuController.changeMainViewController(
                downloadsTableViewNavigationController, close: true)
        case 2:
            ControllerManager.instance.slideMenuController.changeMainViewController(
                favoritesTableViewNavigationController, close: true)
        default:
            break
        }
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44
    }

    // MARK: - Методы UIAlertViewDelegate

    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 0 { // "Выйти"
            UIView.transitionWithView(tableHeaderView, duration: 0.3, options: .TransitionCrossDissolve, animations: {
                self.logOutButton.hidden = true
                self.logInButton.hidden = false
                self.avatarView.removeFromSuperview()
                self.fullNameLabel.removeFromSuperview()
                }, completion: nil)

            let standardUserDefaults = NSUserDefaults.standardUserDefaults()
            standardUserDefaults.removeObjectForKey("accessToken")
            standardUserDefaults.removeObjectForKey("fullName")
            standardUserDefaults.synchronize()

            let fileManager = NSFileManager.defaultManager()
            let avatarUrl = NSURL(string: "avatar.jpg", relativeToURL: fileManager.URLsForDirectory(.DocumentDirectory,
                inDomains: .UserDomainMask)[0])!

            do {
                try fileManager.removeItemAtURL(avatarUrl)
            } catch {
                print("Не удалось удалить аватар")
            }

            for currentDownload in DownloadManager.getCurrentDownloads() {
                currentDownload.task.cancel()
            }

            ControllerManager.instance.downloadsTableViewController.deleteAllBooks()
            ControllerManager.instance.favoritesTableViewController.deleteAllBooks()
            
            MisisBooksApi.instance.accessToken = nil
            MisisBooksApi.instance.vkAccessToken = nil
            MisisBooksApi.instance.getPopularBooksByCount(20, categoryId: 1)
        }
    }
}
