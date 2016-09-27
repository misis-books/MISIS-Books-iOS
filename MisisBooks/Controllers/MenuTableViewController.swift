//
//  MenuViewController.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 26.01.15.
//  Copyright (c) 2016 Maxim Loskov. All rights reserved.
//

import UIKit

class MenuTableViewController: UITableViewController, UIAlertViewDelegate {

    var activityIndicatorView: UIActivityIndicatorView!
    var avatarView: UIImageView!
    var downloadsTableViewNavigationController: UIViewController!
    var favoritesTableViewNavigationController: UIViewController!
    var fullNameLabel: UILabel!
    var logInButton: CustomButton!
    var logOutButton: CustomButton!
    var searchTableViewNavigationController: UIViewController!
    var selectedMenuItem = 1
    var tableHeaderView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.isScrollEnabled = false
        tableView.separatorColor = UIColor(red: 178 / 255.0, green: 178 / 255.0, blue: 178 / 255.0, alpha: 1)
        tableView.tableFooterView = UIView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 100))

        let gradient = CAGradientLayer()
        gradient.frame = tableHeaderView.bounds
        gradient.colors = [
            UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1).cgColor,
            UIColor(red: 72 / 255.0, green: 86 / 255.0, blue: 97 / 255.0, alpha: 1).cgColor
        ]
        tableHeaderView.layer.insertSublayer(gradient, at: 0)

        activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .white)
        activityIndicatorView.center = CGPoint(
            x: SlideMenuOption().menuViewWidth / 2,
            y: tableHeaderView.frame.height / 2
        )
        tableHeaderView.addSubview(activityIndicatorView)

        logInButton = CustomButton(title: "Авторизоваться", color: .white)
        logInButton.addTarget(self, action: #selector(logInButtonPressed), for: .touchUpInside)
        logInButton.center = CGPoint(x: SlideMenuOption().menuViewWidth / 2, y: tableHeaderView.frame.height / 2)
        tableHeaderView.addSubview(logInButton)

        logOutButton = CustomButton(title: "Выйти", color: .white)
        logOutButton.addTarget(self, action: #selector(logOutButtonPressed), for: .touchUpInside)
        logOutButton.center = CGPoint(
            x: SlideMenuOption().menuViewWidth - logOutButton.frame.width / 2 - 10,
            y: logOutButton.frame.height / 2 + 10
        )
        logOutButton.isHidden = true
        tableHeaderView.addSubview(logOutButton)

        let separatorView = UIView(frame: CGRect(
            x: 0,
            y: tableHeaderView.frame.size.height,
            width: tableHeaderView.frame.size.width,
            height: -0.5
        ))
        separatorView.backgroundColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1)
        tableHeaderView.addSubview(separatorView)

        tableView.tableHeaderView = tableHeaderView

        updateTableHeaderView()

        searchTableViewNavigationController = UINavigationController(
            rootViewController: ControllerManager.instance.searchTableViewController)
        favoritesTableViewNavigationController = UINavigationController(
            rootViewController: ControllerManager.instance.favoritesTableViewController)
    }

    func highlightRowAtIndexPath(_ indexPath: IndexPath) {
        let normalColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1)
        let previousCell = tableView.cellForRow(at: IndexPath(row: selectedMenuItem, section: 0))
        previousCell?.imageView?.tintColor = normalColor
        previousCell?.textLabel?.textColor = normalColor

        let highlightColor = UIColor(red: 0, green: 138 / 255.0, blue: 190 / 255.0, alpha: 1)
        let newCell = tableView.cellForRow(at: indexPath)
        newCell?.imageView?.tintColor = highlightColor
        newCell?.textLabel?.textColor = highlightColor

        selectedMenuItem = indexPath.item
    }

    func logInButtonPressed() {
        activityIndicatorView.startAnimating()

        UIView.transition(with: tableHeaderView, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.logInButton.isHidden = true
            }, completion: nil)

        let viewControllerToPresent = UINavigationController(rootViewController: VkAuthorizationViewController())
        viewControllerToPresent.modalTransitionStyle = .coverVertical
        present(viewControllerToPresent, animated: true, completion: nil)
    }

    func logOutButtonPressed() {
        UIAlertView(
            title: "",
            message: "Вы действительно хотите выйти? Все загруженные документы будут удалены. "
                + "Приложение вернется к первоначальному состоянию",
            delegate: self,
            cancelButtonTitle: nil,
            otherButtonTitles: "Выйти", "Отмена"
            ).show()
    }

    func updateTableHeaderView() {
        let fileManager = FileManager.default
        let avatarPath = URL(
            string: "avatar.jpg",
            relativeTo: fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            )!.path

        if fileManager.fileExists(atPath: avatarPath) {
            showAvatarView(withImage: UIImage(contentsOfFile: avatarPath)!)

            if let fullName = UserDefaults.standard.string(forKey: "fullName") {
                showLabel(withFullName: fullName)
            }

            logInButton.isHidden = true
            logOutButton.isHidden = false
        } else if Api.instance.accessToken != nil {
            Api.instance.getAccountInformation() { json in
                if json != nil {
                    if let response = json!["response"] as? [String: AnyObject],
                        let user = response["user"] as? [String: AnyObject],
                        let fullName = user["view_name"] as? String,
                        let photoUrlString = user["photo"] as? String {
                        self.activityIndicatorView.stopAnimating()

                        let standardUserDefaults = UserDefaults.standard
                        standardUserDefaults.set(fullName, forKey: "fullName")
                        standardUserDefaults.synchronize()

                        self.showLabel(withFullName: fullName)

                        DispatchQueue.main.async {
                            if let imageUrl = URL(string: photoUrlString),
                                let imageData = try? Data(contentsOf: imageUrl),
                                let image = UIImage(data: imageData) {
                                try? UIImageJPEGRepresentation(image, 100)!
                                    .write(to: URL(fileURLWithPath: avatarPath), options: [.atomic])

                                self.showAvatarView(withImage: image)
                            }
                        }
                    }

                    self.logOutButton.isHidden = false
                }
            }
        } else {
            logInButton.isHidden = false
        }
    }

    func vkLogInFailed() {
        print("Авторизация через ВКонтакте не удалась")

        logInButton.isHidden = false
        activityIndicatorView.stopAnimating()
    }

    func vkLogInSucceededWithVkAccessToken(_ vkAccessToken: String, vkUserId: String) {
        print("Маркер доступа ВКонтакте: \(vkAccessToken)\nИдентификатор пользователя ВКонтакте: \(vkUserId)")

        Api.instance.vkAccessToken = vkAccessToken

        Api.instance.signIn {
            /* let searchTableViewController = ControllerManager.instance.searchTableViewController
            let favoritesTableViewController = ControllerManager.instance.favoritesTableViewController

            if searchTableViewController.action == .getPopular {
                searchTableViewController.activityIndicator?.startAnimating()
                searchTableViewController.placeholderView?.removeFromSuperview()
                searchTableViewController.placeholderView = nil

                ControllerManager.instance.searchTableViewController.categoryId = 1
                ControllerManager.instance.searchTableViewController.count = 20
                ControllerManager.instance.searchTableViewController.getPopularBooks()
            }

            if favoritesTableViewController.isReady && favoritesTableViewController.action == .getFavorites {
                favoritesTableViewController.activityIndicator?.startAnimating()
                favoritesTableViewController.placeholderView?.removeFromSuperview()
                favoritesTableViewController.placeholderView = nil

                ControllerManager.instance.favoritesTableViewController.count = 20
                ControllerManager.instance.favoritesTableViewController.offset = 0
                ControllerManager.instance.favoritesTableViewController.getFavorites()
            } */
        }
    }

    private func showAvatarView(withImage image: UIImage) {
        avatarView = UIImageView(image: image)
        avatarView.layer.borderColor = UIColor.white.cgColor
        avatarView.layer.borderWidth = 1
        avatarView.frame = CGRect(x: 15, y: 30, width: 55, height: 55)
        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = avatarView.frame.size.width / 2
        avatarView.center = CGPoint(x: SlideMenuOption().menuViewWidth / 2, y: tableHeaderView.frame.height / 2 - 10)

        UIView.transition(with: tableHeaderView, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.tableHeaderView.addSubview(self.avatarView)
            }, completion: nil)
    }

    private func showLabel(withFullName fullName: String) {
        fullNameLabel = UILabel()
        fullNameLabel.font = UIFont(name: "HelveticaNeue", size: 14)
        fullNameLabel.text = fullName
        fullNameLabel.textColor = .white
        fullNameLabel.numberOfLines = 1
        fullNameLabel.sizeToFit()
        fullNameLabel.center = CGPoint(x: SlideMenuOption().menuViewWidth / 2, y: tableHeaderView.frame.height / 2 + 30)

        UIView.transition(with: tableHeaderView, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.tableHeaderView.addSubview(self.fullNameLabel)
            }, completion: nil)
    }

    // MARK: - Методы UITableViewDataSource

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let titles = ["Поиск", "Загрузки", "Избранное"]
        let imageNames = ["Search", "Downloads", "Favorites"]
        let image = UIImage(named: imageNames[indexPath.row])
        let color = indexPath.item != selectedMenuItem
            ? UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1)
            : UIColor(red: 0, green: 138 / 255.0, blue: 190 / 255.0, alpha: 1)

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as UITableViewCell
        cell.imageView!.image = image!.withRenderingMode(.alwaysTemplate)
        cell.imageView!.tintColor = color
        cell.textLabel!.font = UIFont(name: "HelveticaNeue-Light", size: 16)
        cell.textLabel!.text = titles[indexPath.row]
        cell.textLabel!.textColor = color

        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    // MARK: - Методы UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        highlightRowAtIndexPath(indexPath)
        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath.item {
        case 0:
            ControllerManager.instance.slideMenuController.changeMainViewController(
                to: searchTableViewNavigationController,
                close: true
            )
        case 1:
            ControllerManager.instance.slideMenuController.changeMainViewController(
                to: downloadsTableViewNavigationController,
                close: true
            )
        case 2:
            ControllerManager.instance.slideMenuController.changeMainViewController(
                to: favoritesTableViewNavigationController,
                close: true
            )
        default:
            break
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    // MARK: - Методы UIAlertViewDelegate

    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if buttonIndex == 0 { // "Выйти"
            UIView.transition(with: tableHeaderView, duration: 0.3, options: .transitionCrossDissolve, animations: {
                self.logOutButton.isHidden = true
                self.logInButton.isHidden = false
                self.avatarView.removeFromSuperview()
                self.fullNameLabel.removeFromSuperview()
                }, completion: nil)

            let standardUserDefaults = UserDefaults.standard
            standardUserDefaults.removeObject(forKey: "accessToken")
            standardUserDefaults.removeObject(forKey: "fullName")
            standardUserDefaults.synchronize()

            let fileManager = FileManager.default
            let avatarUrl = URL(string: "avatar.jpg",
                                relativeTo: fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0])!
            
            do {
                try fileManager.removeItem(at: avatarUrl)
            } catch {
                print("Не удалось удалить аватар")
            }
            
            for currentDownload in DownloadManager.getCurrentDownloads() {
                currentDownload.task.cancel()
            }
            
            ControllerManager.instance.downloadsTableViewController.deleteAllBooks()
            ControllerManager.instance.favoritesTableViewController.deleteAllBooks()
            
            Api.instance.accessToken = nil
            Api.instance.vkAccessToken = nil

            ControllerManager.instance.searchTableViewController.categoryId = 1
            ControllerManager.instance.searchTableViewController.count = 20
            ControllerManager.instance.searchTableViewController.getPopularBooks()
        }
    }
}
