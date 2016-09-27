//
//  BookTableViewController.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 02.04.15.
//  Copyright (c) 2016 Maxim Loskov. All rights reserved.
//

import UIKit

class BookTableViewController: UITableViewController, UIActionSheetDelegate, UIDocumentInteractionControllerDelegate {
    var books = [Book]()
    var downloadableBooks = [Book]()
    var sectionTitleLabel1: UILabel!
    var sectionTitleLabel2: UILabel!
    var selectedBook: Book!
    private var documentInteractionController: UIDocumentInteractionController!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "Menu"),
            style: .plain,
            target: nil,
            action: #selector(ControllerManager.instance.slideMenuController.openLeft)
        )

        tableView.backgroundColor = UIColor(red: 242 / 255.0, green: 238 / 255.0, blue: 235 / 255.0, alpha: 1)
        tableView.separatorColor = UIColor(red: 178 / 255.0, green: 178 / 255.0, blue: 178 / 255.0, alpha: 1)
        tableView.tableFooterView = UIView()
        tableView.register(CustomTableViewCell.self, forCellReuseIdentifier: CustomTableViewCell.reuseId)

        sectionTitleLabel1 = UILabel(frame: CGRect(x: 15, y: 6, width: tableView.frame.size.width - 30, height: 20))
        sectionTitleLabel1.backgroundColor = .clear
        sectionTitleLabel1.font = UIFont(name: "HelveticaNeue", size: 13)
        sectionTitleLabel1.shadowColor = .white
        sectionTitleLabel1.shadowOffset = CGSize(width: 0, height: -1)
        sectionTitleLabel1.textColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1)

        sectionTitleLabel2 = UILabel(frame: CGRect(x: 15, y: 6, width: tableView.frame.size.width - 30, height: 20))
        sectionTitleLabel2.backgroundColor = .clear
        sectionTitleLabel2.font = UIFont(name: "HelveticaNeue", size: 13)
        sectionTitleLabel2.shadowColor = .white
        sectionTitleLabel2.shadowOffset = CGSize(width: 0, height: -1)
        sectionTitleLabel2.textColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1)
    }

    private func addBookToFavorites() {
        Api.instance.addBookToFavorites(selectedBook, failure: { error in
            PopUpMessage(title: "Ошибка", subtitle: error.description).show()
            }) { result in
                if result {
                    ControllerManager.instance.favoritesTableViewController.addBook(self.selectedBook)
                    PopUpMessage(title: "Сервер принял запрос",
                                 subtitle: "Документ успешно добавлен в избранное").show()
                } else {
                    PopUpMessage(title: "Сервер отклонил запрос",
                                 subtitle: "Не удалось добавить документ в избранное").show()
                }
        }
    }

    // MARK: - Методы UITableViewDataSource

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return numberOfSections(in: tableView) == 2 && (section == 0 && downloadableBooks.count == 0 ||
            section == 1 && books.count == 0) ? .leastNormalMagnitude : 8
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return numberOfSections(in: tableView) == 2 && (section == 0 && downloadableBooks.count == 0 ||
            section == 1 && books.count == 0) ? .leastNormalMagnitude : 26
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return numberOfSections(in: tableView) == 2
            && (section == 0 && downloadableBooks.count == 0 || section == 1 && books.count == 0) ? nil : {
                let sectionHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 26))
                sectionHeaderView.addSubview(section == 0 ? sectionTitleLabel1 : sectionTitleLabel2)

                return sectionHeaderView
            }()
    }

    // MARK: - Методы UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing && (numberOfSections(in: tableView) == 2 && indexPath.section == 1 ||
            numberOfSections(in: tableView) == 1 && indexPath.section == 0) {
            return
        }

        tableView.deselectRow(at: indexPath, animated: true)

        selectedBook = indexPath.section == 0 && numberOfSections(in: tableView) == 2 ?
            downloadableBooks[indexPath.row] : books[indexPath.row]

        let titleForFavorites = selectedBook.isAddedToFavorites ? "Удалить из избранного" : "Добавить в избранное"
        let actionSheet: UIActionSheet!

        if selectedBook.isAddedToDownloads { // Документ загружен
            actionSheet = UIActionSheet(
                title: selectedBook.name,
                delegate: self,
                cancelButtonTitle: "Отмена",
                destructiveButtonTitle: nil,
                otherButtonTitles: "Просмотреть", "Открыть в другом приложении",
                titleForFavorites, "Удалить файл"
            )
            actionSheet.destructiveButtonIndex = 4
            actionSheet.tag = 1
        } else if selectedBook.isExistsInCurrentDownloads { // Документ загружается
            var titleForManageDownload = ""

            if let isBookDownloading = selectedBook.isDownloading {
                titleForManageDownload = isBookDownloading ? "Приостановить загрузку" : "Возобновить загрузку"
            }

            actionSheet = UIActionSheet(
                title: selectedBook.name,
                delegate: self,
                cancelButtonTitle: "Отмена",
                destructiveButtonTitle: nil,
                otherButtonTitles: titleForManageDownload, "Отменить загрузку",
                titleForFavorites
            )
            actionSheet.tag = 2
        } else { // Документ не загружен
            actionSheet = UIActionSheet(
                title: selectedBook.name,
                delegate: self,
                cancelButtonTitle: "Отмена",
                destructiveButtonTitle: nil,
                otherButtonTitles: "Загрузить (\(selectedBook.fileSize))",
                titleForFavorites
            )
            actionSheet.tag = 3
        }

        actionSheet.actionSheetStyle = .default
        actionSheet.show(in: view)
    }

    // MARK: - Методы UIActionSheetDelegate

    func actionSheet(_ actionSheet: UIActionSheet, clickedButtonAt buttonIndex: Int) {
        print("actionSheet.tag = \(actionSheet.tag), buttonIndex = \(buttonIndex)")

        switch actionSheet.tag {
        case 1: // Документ загружен
            switch buttonIndex {
            case 1: // "Просмотреть"
                documentInteractionController = UIDocumentInteractionController(url: selectedBook.localUrl)
                documentInteractionController.delegate = self
                documentInteractionController.name = selectedBook.name
                documentInteractionController.uti = "com.adobe.pdf"
                documentInteractionController.presentPreview(animated: true)
            case 2: // "Открыть в другом приложении"
                documentInteractionController = UIDocumentInteractionController(url: selectedBook.localUrl)
                documentInteractionController.delegate = self
                documentInteractionController.uti = "com.adobe.pdf"
                documentInteractionController.presentOpenInMenu(from: .zero, in: self.view, animated: true)
            case 3: // "Добавить/удалить из избранного"
                selectedBook.isAddedToFavorites
                    ? ControllerManager.instance.favoritesTableViewController.deleteBooksFromFavorites([selectedBook])
                    : addBookToFavorites()
            case 4: // "Удалить файл"
                ControllerManager.instance.downloadsTableViewController.deleteBooks([selectedBook])
            default:
                break
            }
        case 2: // Документ загружается
            switch buttonIndex {
            case 1: // "Приостановить/возобновить загрузку"
                if let isBookDownloading = selectedBook.isDownloading {
                    isBookDownloading
                        ? ControllerManager.instance.downloadsTableViewController.pauseDownloadBook(selectedBook)
                        : ControllerManager.instance.downloadsTableViewController.resumeDownloadBook(selectedBook)
                }
            case 2: // "Отменить загрузку"
                ControllerManager.instance.downloadsTableViewController.cancelDownloadBook(selectedBook)
            case 3: // "Добавить/удалить из избранного"
                selectedBook.isAddedToFavorites
                    ? ControllerManager.instance.favoritesTableViewController.deleteBooksFromFavorites([selectedBook])
                    : addBookToFavorites()
            default:
                break
            }
        case 3: // Документ не загружен
            switch buttonIndex {
            case 1: // "Загрузить"
                ControllerManager.instance.downloadsTableViewController.downloadBook(selectedBook)
            case 2: // "Добавить/удалить из избранного"
                selectedBook.isAddedToFavorites
                    ? ControllerManager.instance.favoritesTableViewController.deleteBooksFromFavorites([selectedBook])
                    : addBookToFavorites()
            default:
                break
            }
        default:
            break
        }
    }
    
    // MARK: - Методы UIDocumentInteractionControllerDelegate
    
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController)
        -> UIViewController {
            return navigationController!
    }
}
