//
//  DownloadsTableViewController.swift
//  misisbooks
//
//  Created by Maxim Loskov on 01.12.14.
//  Copyright (c) 2014 Maxim Loskov. All rights reserved.
//

import UIKit

class DownloadsTableViewController: BookTableViewController {
    
    /// Вид-заполнитель
    private var placeholderView: PlaceholderView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsMultipleSelectionDuringEditing = true
        title = "Загрузки"
        
        books = reverse(Database.instance.booksForList("downloads"))
        
        if books.count == 0 {
            showPlaceholderView()
        } else {
            showEditButton()
        }
        
        println("Загруженные книги (\(books.count)): [\(getAllDocuments())]")
    }
    
    override func viewDidAppear(animated: Bool) {
        updateSectionTitle()
    }
    
    /// Добавляет книгу в загрузки
    ///
    /// :param: book Книга
    func addBook(book: Book) {
        books.insert(book, atIndex: 0)
        tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 1)], withRowAnimation: .Automatic)
        changeDownloadProgress(1, isWaiting: false, bookId: book.id)
        Database.instance.addBook(book, toList: "downloads")
        updateSectionTitle()
        hidePlaceholderView()
        showEditButton()
    }
    
    /// Добавляет загружаемую книгу в загрузки
    ///
    /// :param: book Книга
    func addDownloadableBook(book: Book) {
        downloadableBooks.insert(book, atIndex: 0)
        tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Automatic)
        changeDownloadProgress(0.001, isWaiting: false, bookId: book.id)
        updateSectionTitle()
        hidePlaceholderView()
    }
    
    /// Удаляет все книги из загрузок
    func deleteAllBooks() {
        for book in reverse(books) {
            changeDownloadProgress(0, isWaiting: false, bookId: book.id)
            NSFileManager.defaultManager().removeItemAtPath(book.localUrl().path!, error: nil)
        }
        
        books.removeAll(keepCapacity: false)
        tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Fade)
        Database.instance.deleteAllBooksFromList("downloads")
        updateSectionTitle()
        
        if downloadableBooks.count == 0 {
            showPlaceholderView()
        } else {
            tableView.setEditing(false, animated: true)
            navigationItem.setRightBarButtonItems(nil, animated: true)
        }
    }
    
    /// Удаляет книги из загрузок
    ///
    /// :param: booksForDeletion Книги для удаления
    func deleteBooks(booksForDeletion: [Book]) {
        for bookForDeletion in booksForDeletion {
            for i in 0..<books.count {
                if books[i].id == bookForDeletion.id {
                    changeDownloadProgress(0, isWaiting: false, bookId: books[i].id)
                    books.removeAtIndex(i)
                    tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: i, inSection: 1)], withRowAnimation: .Fade)
                    NSFileManager.defaultManager().removeItemAtPath(books[i].localUrl().path!, error: nil)
                    
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
    
    /// Обрабатывает событие, когда нажата кнопка удаления
    func deleteButtonPressed() {
        let selectedIndexPaths = tableView.indexPathsForSelectedRows()
        let actionTitleSubstring: String
        var numberOfBooksToDelete = 0
        
        if selectedIndexPaths?.count == 1 {
            actionTitleSubstring = "этот документ"
            numberOfBooksToDelete = 1
        } else if selectedIndexPaths?.count > 1 {
            actionTitleSubstring = "эти документы"
            numberOfBooksToDelete = selectedIndexPaths!.count
        } else {
            actionTitleSubstring = "все документы"
            numberOfBooksToDelete = books.count
        }
        
        if numberOfBooksToDelete == 0 {
            return
        }
        
        let actionSheet = UIActionSheet(title: "Вы действительно хотите удалить из загрузок \(actionTitleSubstring)?",
            delegate: self, cancelButtonTitle: "Отмена", destructiveButtonTitle: "Удалить (\(numberOfBooksToDelete))")
        actionSheet.actionSheetStyle = .Default
        actionSheet.tag = 0
        actionSheet.showInView(view)
    }
    
    /// Удалает загружаемую книгу из загрузок
    ///
    /// :param: book Книга
    func deleteDownloadableBook(book: Book) {
        for i in 0..<downloadableBooks.count {
            if downloadableBooks[i].id == book.id {
                downloadableBooks.removeAtIndex(i)
                tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: i, inSection: 0)], withRowAnimation: .Fade)
                
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
    
    /// Отменяет загрузку книги
    ///
    /// :param: book
    func cancelDownloadBook(book: Book) {
        if let task = book.getDownloadTask() {
            DownloadManager.cancelDownload(downloadTask: task)
        }
    }
    
    /// Загружает книгу
    ///
    /// :param: book Книга
    func downloadBook(book: Book) {
        if DownloadManager.getCurrentDownloads().count <= 10 {
            if let accessToken = NSUserDefaults.standardUserDefaults().stringForKey("accessToken") {
                let shortUrlString = "\(book.downloadUrl)&access_token=\(accessToken)"
                
                println("Короткий URL: \(shortUrlString)")
                
                addDownloadableBook(book)
                
                if let sourceUrl = NSURL(string: shortUrlString) {
                    DownloadManager.download("\(book.id).pdf", destination: nil, sourceUrl: sourceUrl,
                        progressBlock: { progressPercentage, fileInformation in
                            dispatch_async(dispatch_get_main_queue()) {
                                self.changeDownloadProgress(Float(progressPercentage) / 100, isWaiting: false, bookId: book.id)
                            }
                        }, responseBlock: { error, fileInformation in
                            if error == nil {
                                println("Файл загружен: \(fileInformation.pathDestination.absoluteString!)")
                                
                                dispatch_async(dispatch_get_main_queue()) {
                                    self.deleteDownloadableBook(book)
                                    self.addBook(book)
                                }
                            } else {
                                var errorDescription = [String]()
                                
                                switch error.code {
                                case -1009: // NSURLErrorNotConnectedToInternet
                                    errorDescription = ["Не удалось загрузить документ", "Отсутствует соедениение с Интернетом"]
                                    break
                                case -999: // NSURLErrorDomain
                                    errorDescription = ["Не удалось загрузить документ", "Загрузка была отменена"]
                                    break
                                default:
                                    errorDescription = ["Не удалось загрузить документ", "Соединение с сервером прервано"]
                                    break
                                }
                                
                                println(error.debugDescription)
                                
                                dispatch_async(dispatch_get_main_queue()) {
                                    AlertBanner(title: errorDescription[0], subtitle: errorDescription[1]).show()
                                    self.changeDownloadProgress(0, isWaiting: false, bookId: book.id)
                                    self.deleteDownloadableBook(book)
                                }
                            }
                    })
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        AlertBanner(title: "Невозможно начать загрузку", subtitle: "Получен некорректный URL").show()
                        self.changeDownloadProgress(0, isWaiting: false, bookId: book.id)
                        self.deleteDownloadableBook(book)
                    }
                }
            } else {
                AlertBanner(title: "Невозможно начать загрузку", subtitle: "Отсутствует маркер доступа").show()
            }
        } else {
            AlertBanner(title: "Невозможно начать загрузку", subtitle: "Превышен лимит одновременных загрузок (10)").show()
        }
    }
    
    /// Приостанавливает загрузку книги
    ///
    /// :param: book Книга
    func pauseDownloadBook(book: Book) {
        if let task = book.getDownloadTask() {
            DownloadManager.pauseDownload(downloadTask: task)
            
            let fileInformation = DownloadManager.getFileInformationByTaskId(task.taskIdentifier)
            changeDownloadProgress(Float(fileInformation.progressPercentage) / 100, isWaiting: true, bookId: book.id)
        }
    }
    
    /// Возобновляет загрузку книги
    ///
    /// :param: book Книга
    func resumeDownloadBook(book: Book) {
        if let task = book.getDownloadTask() {
            DownloadManager.resumeDownload(downloadTask: task)
            
            let fileInformation = DownloadManager.getFileInformationByTaskId(task.taskIdentifier)
            changeDownloadProgress(Float(fileInformation.progressPercentage) / 100, isWaiting: false, bookId: book.id)
        }
    }
    
    /// Показывает кнопку для редактирования таблицы
    func showEditButton() {
        tableView.setEditing(false, animated: true)
        
        let editBarButtonItem = UIBarButtonItem(image: UIImage(named: "Edit"), style: .Plain, target: self,
            action: Selector("showDeleteAndCancelButtons"))
        navigationItem.setRightBarButtonItems([editBarButtonItem], animated: true)
    }
    
    /// Показывает кнопки для удаления документов и отмены редактирования таблицы
    func showDeleteAndCancelButtons() {
        setEditing(true, animated: true)
        
        let cancelBarButtonItem = UIBarButtonItem(image: UIImage(named: "Cancel"), style: .Plain, target: self,
            action: Selector("showEditButton"))
        let deleteBarButtonItem = UIBarButtonItem(image: UIImage(named: "Trash"), style: .Plain, target: self,
            action: Selector("deleteButtonPressed"))
        navigationItem.setRightBarButtonItems([cancelBarButtonItem, deleteBarButtonItem], animated: true)
    }
    
    /// MARK: - Внутренние методы
    
    /// Изменяет процесс загрузки книги во всех принадлежащих ей ячейках
    ///
    /// :param: progress Процесс загрузки
    /// :param: isWaiting Флаг, показывающий, приостановлена ли загрузка
    /// :param: bookId Идентификатор книги
    private func changeDownloadProgress(progress: Float, isWaiting: Bool, bookId: Int) {
        let controllers = [ControllerManager.instance.searchTableViewController,
            ControllerManager.instance.downloadsTableViewController, ControllerManager.instance.favoritesTableViewController]
        
        for controller in controllers {
            if let indexPaths = controller.tableView.indexPathsForVisibleRows() {
                for indexPath in indexPaths {
                    if let cell = controller.tableView.cellForRowAtIndexPath(indexPath as! NSIndexPath) as? CustomTableViewCell {
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
    
    /// Возвращает список всех загруженных книг (PDF-документов)
    ///
    /// :returns: Список всех загруженных книг
    private func getAllDocuments() -> String {
        let documentDirectory = NSHomeDirectory().stringByAppendingFormat("/Documents/")
        // let listPathContent = NSFileManager.defaultManager().subpathsOfDirectoryAtPath(documentDirectory, error: nil)
        let listPathContent = NSBundle(path: documentDirectory)!.pathsForResourcesOfType("pdf", inDirectory: nil)
        
        return join(", ", map(listPathContent) { $0.lastPathComponent })
    }
    
    /// Скрывает вид-заполнитель
    private func hidePlaceholderView() {
        tableView.bounces = true
        placeholderView?.removeFromSuperview()
    }
    
    /// Показывает вид-заполнитель
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
    
    /// Показывает контроллер поиска
    private func showSearchController() {
        ControllerManager.instance.slideMenuController.changeMainViewController(
            ControllerManager.instance.menuTableViewController.searchTableViewNavigationController, close: true)
        ControllerManager.instance.menuTableViewController.highlightRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0))
    }
    
    /// Обновляет заголовок секции
    private func updateSectionTitle() {
        let totalBooks = books.count
        let totalDownloadableBooks = downloadableBooks.count
        let keys = [2, 0, 1, 1, 1, 2, 2, 2, 2, 2]
        let words1 = ["ЗАГРУЖАЕМЫЙ ДОКУМЕНТ", "ЗАГРУЖАЕМЫХ ДОКУМЕНТА", "ЗАГРУЖАЕМЫХ ДОКУМЕНТОВ"]
        let word1 = words1[totalDownloadableBooks % 100 > 4 && totalDownloadableBooks % 100 < 20 ?
            2 : keys[totalDownloadableBooks % 10]]
        let words2 = ["ЗАГРУЖЕННЫЙ ДОКУМЕНТ", "ЗАГРУЖЕННЫХ ДОКУМЕНТА", "ЗАГРУЖЕННЫХ ДОКУМЕНТОВ"]
        let word2 = words2[totalBooks % 100 > 4 && totalBooks % 100 < 20 ? 2 : keys[totalBooks % 10]]
        
        sectionTitleLabel1.text = totalDownloadableBooks == 0 ? "" : "\(totalDownloadableBooks) \(word1)"
        sectionTitleLabel2.text = totalBooks == 0 ? "" : "\(totalBooks) \(word2)"
    }
    
    /// MARK: - Методы UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.section != 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return indexPath.section == 0 ?
            CustomTableViewCell(book: downloadableBooks[indexPath.row], query: nil) :
            CustomTableViewCell(book: books[indexPath.row], query: nil)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? downloadableBooks.count : books.count
    }
    
    /// MARK: - Методы UITableViewDelegate
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return indexPath.section == 0 ?
            CustomTableViewCell.heightForRowWithBook(downloadableBooks[indexPath.row]) :
            CustomTableViewCell.heightForRowWithBook(books[indexPath.row])
    }
    
    /// MARK: - Методы UIActionSheetDelegate
    
    override func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        super.actionSheet(actionSheet, clickedButtonAtIndex: buttonIndex)
        
        if actionSheet.tag == 0 && buttonIndex == 0 { // Таблица редактируется
            if let selectedIndexPaths = tableView.indexPathsForSelectedRows() {
                deleteBooks(map(selectedIndexPaths) { self.books[$0.row] })
            } else {
                deleteAllBooks()
            }
        }
    }
}
