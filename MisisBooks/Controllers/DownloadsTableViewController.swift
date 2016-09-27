//
//  DownloadsTableViewController.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 01.12.14.
//  Copyright (c) 2016 Maxim Loskov. All rights reserved.
//

import UIKit

class DownloadsTableViewController: BookTableViewController {
    private var placeholderView: PlaceholderView?

    override func viewDidAppear(_ animated: Bool) {
        updateSectionTitle()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.allowsMultipleSelectionDuringEditing = true
        title = "Загрузки"

        books = Array(Database.instance.getBooks(fromList: "downloads").reversed())
        books.count == 0 ? showPlaceholderView() : showEditButton()

        print("Загруженные книги (\(books.count)): [\(getAllDocuments())]")
    }

    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation,
        duration: TimeInterval) {
            if UIDevice.current.userInterfaceIdiom == .pad {
                placeholderView?.setNeedsLayout()
            }
    }

    func addBook(_ book: Book) {
        books.insert(book, at: 0)
        tableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
        changeDownloadProgress(to: 1, isWaiting: false, bookId: book.id)
        Database.instance.addBook(book, toList: "downloads")
        updateSectionTitle()
        hidePlaceholderView()
        showEditButton()
    }

    func addDownloadableBook(_ downloadableBook: Book) {
        downloadableBooks.insert(downloadableBook, at: 0)
        tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        changeDownloadProgress(to: 0.001, isWaiting: false, bookId: downloadableBook.id)
        updateSectionTitle()
        hidePlaceholderView()
    }

    func deleteAllBooks() {
        for book in Array(books.reversed()) {
            changeDownloadProgress(to: 0, isWaiting: false, bookId: book.id)

            do {
                try FileManager.default.removeItem(atPath: book.localUrl.path)
            } catch {
                print("Не удалось удалить книгу \(book.localUrl)")
            }
        }

        books.removeAll(keepingCapacity: false)
        tableView.reloadSections(IndexSet(integer: 1), with: .fade)
        Database.instance.deleteAllBooks(fromList: "downloads")
        updateSectionTitle()

        if downloadableBooks.count == 0 {
            showPlaceholderView()
        } else {
            tableView.setEditing(false, animated: true)
            navigationItem.setRightBarButtonItems(nil, animated: true)
        }
    }

    func deleteBooks(_ booksForDeletion: [Book]) {
        for bookForDeletion in booksForDeletion {
            for i in 0..<books.count {
                if books[i].id == bookForDeletion.id {
                    do {
                        try FileManager.default.removeItem(atPath: books[i].localUrl.path)
                    } catch {
                        print("Не удалось удалить книгу \(books[i].localUrl)")
                    }

                    changeDownloadProgress(to: 0, isWaiting: false, bookId: books[i].id)
                    books.remove(at: i)
                    tableView.deleteRows(at: [IndexPath(row: i, section: 1)], with: .fade)

                    break
                }
            }

            Database.instance.deleteBook(bookForDeletion, fromList: "downloads")
        }

        updateSectionTitle()

        if books.count == 0 && downloadableBooks.count == 0 {
            showPlaceholderView()
        } else if books.count == 0 {
            tableView.setEditing(false, animated: true)
            navigationItem.setRightBarButtonItems(nil, animated: true)
        } else {
            showEditButton()
        }
    }

    func deleteButtonPressed() {
        let selectedIndexPaths = tableView.indexPathsForSelectedRows
        let actionTitleSubstring: String
        var numberOfBooksToDelete = 0

        if selectedIndexPaths?.count == 1 {
            actionTitleSubstring = "этот документ"
            numberOfBooksToDelete = 1
        } else if (selectedIndexPaths?.count)! > 1 {
            actionTitleSubstring = "эти документы"
            numberOfBooksToDelete = selectedIndexPaths!.count
        } else {
            actionTitleSubstring = "все документы"
            numberOfBooksToDelete = books.count
        }

        if numberOfBooksToDelete == 0 {
            return
        }

        let actionSheet = UIActionSheet(
            title: "Вы действительно хотите удалить из загрузок \(actionTitleSubstring)?",
            delegate: self,
            cancelButtonTitle: "Отмена",
            destructiveButtonTitle: "Удалить (\(numberOfBooksToDelete))"
        )
        actionSheet.actionSheetStyle = .default
        actionSheet.tag = 0
        actionSheet.show(in: view)
    }

    func deleteDownloadableBook(_ book: Book) {
        for i in 0..<downloadableBooks.count {
            if downloadableBooks[i].id == book.id {
                downloadableBooks.remove(at: i)
                tableView.deleteRows(at: [IndexPath(row: i, section: 0)], with: .fade)

                break
            }
        }

        updateSectionTitle()

        if books.count == 0 && downloadableBooks.count == 0 {
            showPlaceholderView()
        } else if books.count == 0 {
            tableView.setEditing(false, animated: true)
            navigationItem.setRightBarButtonItems(nil, animated: true)
        } else {
            showEditButton()
        }
    }

    func cancelDownloadBook(_ book: Book) {
        if let task = book.getDownloadTask() {
            DownloadManager.cancelDownloadTask(task)
        }
    }

    func downloadBook(_ book: Book) {
        if DownloadManager.getCurrentDownloads().count <= 10 {
            print("Загружается файл по URL: \(book.downloadUrl)")

            addDownloadableBook(book)

            if let sourceUrl = URL(string: book.downloadUrl) {
                _ = DownloadManager.download("\(book.id).pdf", destinationUrl: nil, sourceUrl: sourceUrl, progressBlock: {
                    progressPercentage, _ in
                    DispatchQueue.main.async {
                        self.changeDownloadProgress(
                            to: Float(progressPercentage) / 100,
                            isWaiting: false,
                            bookId: book.id
                        )
                    }
                    }) { error, fileInformation in
                        DispatchQueue.main.async {
                            if error == nil {
                                print("Файл загружен: \(fileInformation.destinationUrl.absoluteString)")

                                self.deleteDownloadableBook(book)
                                self.addBook(book)
                            } else {
                                let errorDescription: String

                                switch error!._code {
                                case -1009: // NSURLErrorNotConnectedToInternet
                                    errorDescription = "Отсутствует соедениение с Интернетом"
                                case -999: // NSURLErrorDomain
                                    errorDescription = "Загрузка была отменена"
                                default:
                                    errorDescription = "Соединение с сервером прервано"
                                }

                                print(error.debugDescription)

                                PopUpMessage(title: "Не удалось загрузить документ", subtitle: errorDescription).show()
                                self.changeDownloadProgress(to: 0, isWaiting: false, bookId: book.id)
                                self.deleteDownloadableBook(book)
                            }
                        }
                }
            } else {
                DispatchQueue.main.async {
                    PopUpMessage(title: "Невозможно начать загрузку", subtitle: "Получен некорректный URL").show()
                    self.changeDownloadProgress(to: 0, isWaiting: false, bookId: book.id)
                    self.deleteDownloadableBook(book)
                }
            }
        } else {
            PopUpMessage(title: "Невозможно начать загрузку", subtitle: "Превышен лимит одновременных загрузок (10)")
                .show()
        }
    }

    func pauseDownloadBook(_ book: Book) {
        if let task = book.getDownloadTask() {
            DownloadManager.pauseDownloadTask(task)

            if let fileInformation = DownloadManager.getFileInformationByTaskId(task.taskIdentifier) {
                changeDownloadProgress(
                    to: Float(fileInformation.progressPercentage) / 100,
                    isWaiting: true,
                    bookId: book.id
                )
            }
        }
    }

    func resumeDownloadBook(_ book: Book) {
        if let task = book.getDownloadTask() {
            DownloadManager.resumeDownloadTask(task)

            if let fileInformation = DownloadManager.getFileInformationByTaskId(task.taskIdentifier) {
                changeDownloadProgress(
                    to: Float(fileInformation.progressPercentage) / 100,
                    isWaiting: false,
                    bookId: book.id
                )
            }
        }
    }

    func showEditButton() {
        tableView.setEditing(false, animated: true)
        navigationItem.setRightBarButtonItems([UIBarButtonItem(image: UIImage(named: "Edit"), style: .plain, target:
            self, action: #selector(showDeleteAndCancelButtons))], animated: true)
    }

    func showDeleteAndCancelButtons() {
        setEditing(true, animated: true)
        navigationItem.setRightBarButtonItems(
            [
                UIBarButtonItem(
                    image: UIImage(named: "Cancel"),
                    style: .plain,
                    target: self,
                    action: #selector(showEditButton)
                ),
                UIBarButtonItem(
                    image: UIImage(named: "Trash"),
                    style: .plain,
                    target: self,
                    action: #selector(deleteButtonPressed)
                )
            ],
            animated: true
        )
    }

    private func changeDownloadProgress(to progress: Float, isWaiting: Bool, bookId: Int) {
        let controllers = [
            ControllerManager.instance.searchTableViewController,
            ControllerManager.instance.downloadsTableViewController,
            ControllerManager.instance.favoritesTableViewController
        ]

        for controller in controllers {
            if let indexPaths = controller.tableView.indexPathsForVisibleRows {
                for indexPath in indexPaths {
                    if let cell = controller.tableView.cellForRow(at: indexPath) as? CustomTableViewCell {
                        if cell.tag == bookId {
                            if cell.roundProgressView?.isWaiting != isWaiting {
                                cell.roundProgressView?.isWaiting = isWaiting
                            }

                            cell.roundProgressView?.percent = CGFloat(progress * 100)
                        }
                    }
                }
            }
        }
    }

    private func getAllDocuments() -> String {
        let listPathContent = Bundle(url: FileManager.default.urls(for: .documentDirectory,
            in: .userDomainMask)[0])!.paths(forResourcesOfType: "pdf", inDirectory: nil)

        return listPathContent.map { URL(string: $0)!.lastPathComponent }.joined(separator: ", ")
    }

    private func hidePlaceholderView() {
        tableView.bounces = true
        placeholderView?.removeFromSuperview()
    }

    private func showPlaceholderView() {
        tableView.setEditing(false, animated: true)
        tableView.bounces = false
        navigationItem.setRightBarButtonItems(nil, animated: true)
        placeholderView?.removeFromSuperview()
        placeholderView = PlaceholderView(viewController: self, title: "Нет документов",
            subtitle: "Здесь будут храниться\nзагруженные документы", buttonText: "Начать поиск") {
                self.showSearchController()
        }
        tableView.addSubview(placeholderView!)
    }

    private func showSearchController() {
        ControllerManager.instance.slideMenuController.changeMainViewController(
            to: ControllerManager.instance.menuTableViewController.searchTableViewNavigationController,
            close: true
        )
        ControllerManager.instance.menuTableViewController.highlightRowAtIndexPath(IndexPath(row: 0, section: 0))
    }

    private func updateSectionTitle() {
        let totalBooks = books.count
        let totalDownloadableBooks = downloadableBooks.count
        let keys = [2, 0, 1, 1, 1, 2, 2, 2, 2, 2]
        let pluralForms1 = ["ЗАГРУЖАЕМЫЙ ДОКУМЕНТ", "ЗАГРУЖАЕМЫХ ДОКУМЕНТА", "ЗАГРУЖАЕМЫХ ДОКУМЕНТОВ"]
        let pluralForm1 = pluralForms1[totalDownloadableBooks % 100 > 4 && totalDownloadableBooks % 100 < 20
            ? 2 : keys[totalDownloadableBooks % 10]]
        let pluralForms2 = ["ЗАГРУЖЕННЫЙ ДОКУМЕНТ", "ЗАГРУЖЕННЫХ ДОКУМЕНТА", "ЗАГРУЖЕННЫХ ДОКУМЕНТОВ"]
        let pluralForm2 = pluralForms2[totalBooks % 100 > 4 && totalBooks % 100 < 20 ? 2 : keys[totalBooks % 10]]

        sectionTitleLabel1.text = totalDownloadableBooks == 0 ? "" : "\(totalDownloadableBooks) \(pluralForm1)"
        sectionTitleLabel2.text = totalBooks == 0 ? "" : "\(totalBooks) \(pluralForm2)"
    }

    // MARK: - Методы UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section != 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return indexPath.section == 0
            ? CustomTableViewCell(book: downloadableBooks[indexPath.row], query: nil)
            : CustomTableViewCell(book: books[indexPath.row], query: nil)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? downloadableBooks.count : books.count
    }

    // MARK: - Методы UITableViewDelegate

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == 0
            ? CustomTableViewCell.getHeightForRow(withBook: downloadableBooks[indexPath.row])
            : CustomTableViewCell.getHeightForRow(withBook: books[indexPath.row])
    }

    // MARK: - Методы UIActionSheetDelegate

    override func actionSheet(_ actionSheet: UIActionSheet, clickedButtonAt buttonIndex: Int) {
        super.actionSheet(actionSheet, clickedButtonAt: buttonIndex)

        if actionSheet.tag == 0 && buttonIndex == 0 { // Таблица редактируется
            if let selectedIndexPaths = tableView.indexPathsForSelectedRows {
                deleteBooks(selectedIndexPaths.map { self.books[$0.row] })
            } else {
                deleteAllBooks()
            }
        }
    }
}
