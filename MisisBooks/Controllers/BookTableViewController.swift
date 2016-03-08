//
//  BookTableViewController.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 02.04.15.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit

/**
    Класс для представления контроллера книг
*/
class BookTableViewController: UITableViewController, UIActionSheetDelegate, UIDocumentInteractionControllerDelegate {

    /// Книги
    var books = [Book]()

    /// Загружаемые книги
    var downloadableBooks = [Book]()

    /// Поле заголовка первой секции
    var sectionTitleLabel1: UILabel!

    /// Поле заголовка второй секции
    var sectionTitleLabel2: UILabel!

    /// Выбранная книга
    var selectedBook: Book!

    /// Контроллер взаимодействия с документом
    private var documentInteractionController: UIDocumentInteractionController!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Menu"), style: .Plain,
            target: ControllerManager.instance.slideMenuController, action: "openLeft")

        tableView.backgroundColor = UIColor(red: 242 / 255.0, green: 238 / 255.0, blue: 235 / 255.0, alpha: 1)
        tableView.separatorColor = UIColor(red: 178 / 255.0, green: 178 / 255.0, blue: 178 / 255.0, alpha: 1)
        tableView.tableFooterView = UIView()
        tableView.registerClass(CustomTableViewCell.self, forCellReuseIdentifier: CustomTableViewCell.reuseId)

        sectionTitleLabel1 = UILabel(frame: CGRectMake(15, 6, tableView.frame.size.width - 30, 20))
        sectionTitleLabel1.backgroundColor = .clearColor()
        sectionTitleLabel1.font = UIFont(name: "HelveticaNeue", size: 13)
        sectionTitleLabel1.shadowColor = .whiteColor()
        sectionTitleLabel1.shadowOffset = CGSizeMake(0, -1)
        sectionTitleLabel1.textColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1)

        sectionTitleLabel2 = UILabel(frame: CGRectMake(15, 6, tableView.frame.size.width - 30, 20))
        sectionTitleLabel2.backgroundColor = .clearColor()
        sectionTitleLabel2.font = UIFont(name: "HelveticaNeue", size: 13)
        sectionTitleLabel2.shadowColor = .whiteColor()
        sectionTitleLabel2.shadowOffset = CGSizeMake(0, -1)
        sectionTitleLabel2.textColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1)
    }

    // MARK: - Методы UITableViewDataSource

    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return numberOfSectionsInTableView(tableView) == 2 && (section == 0 && downloadableBooks.count == 0 ||
            section == 1 && books.count == 0) ? CGFloat.min : 8
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return numberOfSectionsInTableView(tableView) == 2 && (section == 0 && downloadableBooks.count == 0 ||
            section == 1 && books.count == 0) ? CGFloat.min : 26
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return numberOfSectionsInTableView(tableView) == 2 && (section == 0 && downloadableBooks.count == 0 ||
            section == 1 && books.count == 0) ? nil : {
                let sectionHeaderView = UIView(frame: CGRectMake(0, 0, tableView.frame.size.width, 26))
                sectionHeaderView.addSubview(section == 0 ? sectionTitleLabel1 : sectionTitleLabel2)

                return sectionHeaderView
            }()
    }

    // MARK: - Методы UITableViewDelegate

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView.editing && (numberOfSectionsInTableView(tableView) == 2 && indexPath.section == 1 ||
            numberOfSectionsInTableView(tableView) == 1 && indexPath.section == 0) {
                return
        }

        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        selectedBook = indexPath.section == 0 && numberOfSectionsInTableView(tableView) == 2 ?
            downloadableBooks[indexPath.row] : books[indexPath.row]

        let titleForFavorites = selectedBook.isAddedToFavorites() ? "Удалить из избранного" : "Добавить в избранное"
        let actionSheet: UIActionSheet!

        if selectedBook.isAddedToDownloads() { // Документ загружен
            actionSheet = UIActionSheet(title: selectedBook.name, delegate: self, cancelButtonTitle: "Отмена",
                destructiveButtonTitle: nil, otherButtonTitles: "Просмотреть", "Открыть в другом приложении",
                titleForFavorites, "Удалить файл")
            actionSheet.destructiveButtonIndex = 4
            actionSheet.tag = 1
        } else if selectedBook.isExistsInCurrentDownloads() { // Документ загружается
            var titleForManageDownload = ""

            if let isBookDownloading = selectedBook.isDownloading() {
                titleForManageDownload = isBookDownloading ? "Приостановить загрузку" : "Возобновить загрузку"
            }

            actionSheet = UIActionSheet(title: selectedBook.name, delegate: self, cancelButtonTitle: "Отмена",
                destructiveButtonTitle: nil, otherButtonTitles: titleForManageDownload, "Отменить загрузку",
                titleForFavorites)
            actionSheet.tag = 2
        } else { // Документ не загружен
            actionSheet = UIActionSheet(title: selectedBook.name, delegate: self, cancelButtonTitle: "Отмена",
                destructiveButtonTitle: nil, otherButtonTitles: "Загрузить (\(selectedBook.fileSize))",
                titleForFavorites)
            actionSheet.tag = 3
        }

        actionSheet.actionSheetStyle = .Default
        actionSheet.showInView(view)
    }

    // MARK: - Методы UIActionSheetDelegate

    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        print("actionSheet.tag = \(actionSheet.tag), buttonIndex = \(buttonIndex)")

        switch actionSheet.tag {
        case 1: // Документ загружен
            switch buttonIndex {
            case 1: // "Просмотреть"
                documentInteractionController = UIDocumentInteractionController(URL: selectedBook.localUrl())
                documentInteractionController.delegate = self
                documentInteractionController.name = selectedBook.name
                documentInteractionController.UTI = "com.adobe.pdf"
                documentInteractionController.presentPreviewAnimated(true)
            case 2: // "Открыть в другом приложении"
                documentInteractionController = UIDocumentInteractionController(URL: selectedBook.localUrl())
                documentInteractionController.delegate = self
                documentInteractionController.UTI = "com.adobe.pdf"
                documentInteractionController.presentOpenInMenuFromRect(CGRectZero, inView: self.view, animated: true)
            case 3: // "Добавить/удалить из избранного"
                selectedBook.isAddedToFavorites() ? MisisBooksApi.instance.deleteBooksFromFavorites([selectedBook]) :
                    MisisBooksApi.instance.addBookToFavorites(selectedBook)
            case 4: // "Удалить файл"
                ControllerManager.instance.downloadsTableViewController.deleteBooks([selectedBook])
            default:
                break
            }
        case 2: // Документ загружается
            switch buttonIndex {
            case 1: // "Приостановить/возобновить загрузку"
                if let isBookDownloading = selectedBook.isDownloading() {
                    isBookDownloading ? ControllerManager.instance.downloadsTableViewController.pauseDownloadBook(
                        selectedBook) : ControllerManager.instance.downloadsTableViewController.resumeDownloadBook(
                            selectedBook)
                }
            case 2: // "Отменить загрузку"
                ControllerManager.instance.downloadsTableViewController.cancelDownloadBook(selectedBook)
            case 3: // "Добавить/удалить из избранного"
                selectedBook.isAddedToFavorites() ? MisisBooksApi.instance.deleteBooksFromFavorites([selectedBook]) :
                    MisisBooksApi.instance.addBookToFavorites(selectedBook)
            default:
                break
            }
        case 3: // Документ не загружен
            switch buttonIndex {
            case 1: // "Загрузить"
                ControllerManager.instance.downloadsTableViewController.downloadBook(selectedBook)
            case 2: // "Добавить/удалить из избранного"
                selectedBook.isAddedToFavorites() ? MisisBooksApi.instance.deleteBooksFromFavorites([selectedBook]) :
                    MisisBooksApi.instance.addBookToFavorites(selectedBook)
            default:
                break
            }
        default:
            break
        }
    }

    // MARK: - Методы UIDocumentInteractionControllerDelegate

    func documentInteractionControllerViewControllerForPreview(controller: UIDocumentInteractionController)
        -> UIViewController {
            return navigationController!
    }
}
