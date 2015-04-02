//
//  BookTableViewController.swift
//  misisbooks
//
//  Created by Maxim Loskov on 02.04.15.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit

class BookTableViewController : UITableViewController, UIActionSheetDelegate, UIDocumentInteractionControllerDelegate {
    
    /// Книги
    var books = [Book]()
    
    /// Загружаемые книги
    var downloadableBooks = [Book]()
    
    /// Выбранная книга
    var selectedBook : Book!
    
    /// Поле заголовка первой секции
    var sectionTitleLabel1 : UILabel!
    
    /// Поле заголовка первой секции
    var sectionTitleLabel2 : UILabel!
    
    
    override init() {
        super.init(style: .Grouped)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerClass(CustomTableViewCell.self, forCellReuseIdentifier: CustomTableViewCell.reuseIdentifier)
        
        let menuBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "Menu"),
            style: .Plain,
            target: ControllerManager.sharedInstance.slideMenuController,
            action: Selector("openLeft")
        )
        navigationItem.setLeftBarButtonItem(menuBarButtonItem, animated: false)
        
        tableView.backgroundColor = UIColor(red: 241 / 255.0, green: 239 / 255.0, blue: 237 / 255.0, alpha: 1.0)
        tableView.separatorColor = UIColor(red: 178 / 255.0, green: 178 / 255.0, blue: 178 / 255.0, alpha: 1.0)
        tableView.tableFooterView = UIView(frame: CGRectZero)
        
        sectionTitleLabel1 = UILabel(frame: CGRectMake(15.0, 6.0, tableView.frame.size.width - 30.0, 20.0))
        sectionTitleLabel1.backgroundColor = UIColor.clearColor()
        sectionTitleLabel1.font = UIFont(name: "HelveticaNeue", size: 13.0)
        sectionTitleLabel1.shadowColor = UIColor.whiteColor()
        sectionTitleLabel1.shadowOffset = CGSizeMake(0.0, -1.0)
        sectionTitleLabel1.textColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1.0)
        
        sectionTitleLabel2 = UILabel(frame: CGRectMake(15.0, 6.0, tableView.frame.size.width - 30.0, 20.0))
        sectionTitleLabel2.backgroundColor = UIColor.clearColor()
        sectionTitleLabel2.font = UIFont(name: "HelveticaNeue", size: 13.0)
        sectionTitleLabel2.shadowColor = UIColor.whiteColor()
        sectionTitleLabel2.shadowOffset = CGSizeMake(0.0, -1.0)
        sectionTitleLabel2.textColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1.0)
    }
    
    /// MARK: - Методы UITableViewDataSource
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if numberOfSectionsInTableView(tableView) == 2 {
            if section == 0 && downloadableBooks.count == 0 || section == 1 && books.count == 0 {
                return CGFloat.min
            }
        }
        
        return 26.0
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if numberOfSectionsInTableView(tableView) == 2 {
            if section == 0 && downloadableBooks.count == 0 || section == 1 && books.count == 0 {
                return CGFloat.min
            }
        }
        
        return 8.0
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if numberOfSectionsInTableView(tableView) == 2 {
            if section == 0 && downloadableBooks.count == 0 || section == 1 && books.count == 0 {
                return nil
            }
        }
        
        let sectionHeaderView = UIView(frame: CGRectMake(0.0, 0.0, tableView.frame.size.width, 26.0))
        sectionHeaderView.addSubview(section == 0 ? sectionTitleLabel1 : sectionTitleLabel2)
        
        return sectionHeaderView
    }
    
    /// MARK: - Методы UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView.editing {
            return
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        selectedBook = indexPath.section == 0 && numberOfSectionsInTableView(tableView) == 2 ?
            downloadableBooks[indexPath.row] :
            books[indexPath.row]
        
        let titleForFavorites = selectedBook.isAddedToFavorites() ? "Удалить из избранного" : "Добавить в избранное"
        var actionSheet : UIActionSheet!
        
        if selectedBook.isAddedToDownloads() { // Документ загружен
            actionSheet = UIActionSheet(
                title: selectedBook.name,
                delegate: self,
                cancelButtonTitle: "Отмена",
                destructiveButtonTitle: nil,
                otherButtonTitles: "Просмотреть", titleForFavorites, "Удалить файл"
            )
            actionSheet.destructiveButtonIndex = 3
            actionSheet.tag = 1
        } else if selectedBook.isExistsInCurrentDownloads() { // Документ загружается
            var titleForManageDownload = ""
            
            if let isBookDownloading = selectedBook.isDownloading() {
                titleForManageDownload = isBookDownloading ? "Приостановить загрузку" : "Возобновить загрузку"
            }
            
            actionSheet = UIActionSheet(
                title: selectedBook.name,
                delegate: self,
                cancelButtonTitle: "Отмена",
                destructiveButtonTitle: nil,
                otherButtonTitles: titleForManageDownload, "Отменить загрузку", titleForFavorites
            )
            actionSheet.tag = 2
        } else { // Документ не загружен
            actionSheet = UIActionSheet(
                title: selectedBook.name,
                delegate: self,
                cancelButtonTitle: "Отмена",
                destructiveButtonTitle: nil,
                otherButtonTitles: "Загрузить (\(selectedBook.fileSize!))", titleForFavorites
            )
            actionSheet.tag = 3
        }
        
        actionSheet.actionSheetStyle = .Default
        actionSheet.showInView(UIApplication.sharedApplication().delegate?.window!)
    }
    
    /// MARK: - Методы UIActionSheetDelegate
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        println("actionSheet.tag = \(actionSheet.tag), buttonIndex = \(buttonIndex)")
        
        switch actionSheet.tag {
        case 1: // Документ загружен
            switch buttonIndex {
            case 1: // "Просмотреть"
                let localBookUrl = ControllerManager.sharedInstance.downloadsTableViewController.getLocalBookUrl(selectedBook.bookId)
                let documentationInteractionController = UIDocumentInteractionController(URL: localBookUrl)
                documentationInteractionController.delegate = self
                documentationInteractionController.name = selectedBook.name
                documentationInteractionController.presentPreviewAnimated(true)
                break
            case 2: // "Добавить/удалить из избранного"
                if selectedBook.isAddedToFavorites() {
                    MisisBooksApi.sharedInstance.deleteBooksFromFavorites([selectedBook])
                } else {
                    MisisBooksApi.sharedInstance.addBookToFavorites(selectedBook)
                }
                break
            case 3: // "Удалить файл"
                ControllerManager.sharedInstance.downloadsTableViewController.deleteBooksFromDownloads([selectedBook])
                break
            default:
                break
            }
            break
        case 2: // Документ загружается
            switch buttonIndex {
            case 1: // "Приостановить/возобновить загрузку"
                if let isBookDownloading = selectedBook.isDownloading() {
                    if isBookDownloading {
                        ControllerManager.sharedInstance.downloadsTableViewController.pauseDownloadBook(selectedBook)
                    } else {
                        ControllerManager.sharedInstance.downloadsTableViewController.resumeDownloadBook(selectedBook)
                    }
                }
                break
            case 2: // "Отменить загрузку"
                ControllerManager.sharedInstance.downloadsTableViewController.cancelDownloadBook(selectedBook)
                break
            case 3: // "Добавить/удалить из избранного"
                if selectedBook.isAddedToFavorites() {
                    MisisBooksApi.sharedInstance.deleteBooksFromFavorites([selectedBook])
                } else {
                    MisisBooksApi.sharedInstance.addBookToFavorites(selectedBook)
                }
                break
            default:
                break
            }
            break
        case 3: // Документ не загружен
            switch buttonIndex {
            case 1: // "Загрузить"
                ControllerManager.sharedInstance.downloadsTableViewController.downloadBook(selectedBook)
                break
            case 2: // "Добавить/удалить из избранного"
                if selectedBook.isAddedToFavorites() {
                    MisisBooksApi.sharedInstance.deleteBooksFromFavorites([selectedBook])
                } else {
                    MisisBooksApi.sharedInstance.addBookToFavorites(selectedBook)
                }
                break
            default:
                break
            }
            break
        default:
            break
        }
    }
    
    /// MARK: - Методы DocumentInteractionViewController
    
    func documentInteractionControllerViewControllerForPreview(controller: UIDocumentInteractionController) -> UIViewController {
        return navigationController!
    }
}
