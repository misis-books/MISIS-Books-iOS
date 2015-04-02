//
//  DownloadsTableViewController.swift
//  misisbooks
//
//  Created by Maxim Loskov on 01.12.14.
//  Copyright (c) 2014 Maxim Loskov. All rights reserved.
//

import UIKit

class DownloadsTableViewController : BookTableViewController {
    
    /// Информационный вид
    var informationView : InformationView?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        books = Database.sharedInstance.booksForList("Downloads")
        
        tableView.allowsMultipleSelectionDuringEditing = true
        title = "Загрузки"
        
        if books.count == 0 {
            showInformationView()
        } else {
            showEditButton()
        }
        
        println("Загруженные книги (\(books.count)): [\(getAllDocuments())]")
    }
    
    override func viewDidAppear(animated: Bool) {
        updateSectionTitle()
    }

    /// MARK: - Методы для загрузки книги
    
    /// Приостанавливает загрузку книги
    ///
    /// :param: book
    func pauseDownloadBook(book: Book) {
        if let task = book.getDownloadTask() {
            DownloadManager.pauseDownload(downloadTask: task)
            
            let fileInformation = DownloadManager.getFileInformationByTaskId(task.taskIdentifier)
            changeDownloadProgress(Float(fileInformation.progressPercentage) / 100, text: "Пауза: \(fileInformation.progressPercentage)%", bookId: book.bookId)
        }
    }
    
    /// Возобновляет загрузку книги
    ///
    /// :param: book
    func resumeDownloadBook(book: Book) {
        if let task = book.getDownloadTask() {
            DownloadManager.resumeDownload(downloadTask: task)
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
        if DownloadManager.getCurrentDownloads().count <= 5 {
            if let accessToken = NSUserDefaults.standardUserDefaults().stringForKey("accessToken") {
                let shortUrlString = "\(book.downloadUrl!)&access_token=\(accessToken)"
                
                println("Короткий URL: \(shortUrlString)")
                
                addDownloadableBookToDownloads(book)
                
                MisisBooksApi.getLongUrlFromShortUrl(NSURL(string: shortUrlString)!) {
                    (longUrl) -> Void in
                    if longUrl != nil {
                        println("Длинный URL: \(longUrl!.absoluteString!)")
                        
                        if let sourceUrl = NSURL(string: longUrl!.absoluteString!) {
                            DownloadManager.download("\(book.bookId).pdf", sourceUrl: sourceUrl, progressBlockCompletion: {
                                (progressPercentage, fileInformation) -> Void in
                                dispatch_async(dispatch_get_main_queue()) {
                                    self.changeDownloadProgress(Float(progressPercentage) / 100, text: "Загрузка: \(progressPercentage)%", bookId: book.bookId)
                                }
                                }, responseBlockCompletion: {
                                    (error, fileInformation) -> Void in
                                    
                                    if error == nil {
                                        println("Файл загружен: \(fileInformation.pathDestination.absoluteString!)")
                                        
                                        dispatch_async(dispatch_get_main_queue()) {
                                            self.deleteDownloadableBookToDownloads(book)
                                            self.addBookToDownloads(book)
                                        }
                                    } else {
                                        dispatch_async(dispatch_get_main_queue()) {
                                            switch error.code {
                                            case -999:
                                                AlertBanner(title: "Не удалось загрузить документ", subtitle: "Загрузка была отменена").show()
                                                break
                                            default:
                                                AlertBanner(title: "Не удалось загрузить документ", subtitle: "Соединение с сервером прервано").show()
                                                break
                                            }
                                            
                                            self.changeDownloadProgress(0.0, text: "", bookId: book.bookId)
                                            self.deleteDownloadableBookToDownloads(book)
                                            
                                            println(error.debugDescription)
                                        }
                                    }
                            })
                        } else {
                            dispatch_async(dispatch_get_main_queue()) {
                                AlertBanner(title: "Невозможно начать загрузку", subtitle: "Некорректный URL для загрузки").show()
                                self.changeDownloadProgress(0.0, text: "", bookId: book.bookId)
                                self.deleteDownloadableBookToDownloads(book)
                            }
                        }
                    } else {
                        dispatch_async(dispatch_get_main_queue()) {
                            AlertBanner(title: "Невозможно начать загрузку", subtitle: "Не получен длинный URL").show()
                            self.changeDownloadProgress(0.0, text: "", bookId: book.bookId)
                            self.deleteDownloadableBookToDownloads(book)
                        }
                    }
                }
            } else {
                AlertBanner(title: "Невозможно начать загрузку", subtitle: "Отсутствует маркер доступа").show()
            }
        } else {
            AlertBanner(title: "Невозможно начать загрузку", subtitle: "Превышен лимит одновременных загрузок (5)").show()
        }
    }
    
    /// MARK: - Методы DownloadManagerDelegate
    
    /// Изменяет прогресс загрузки книги во всех соответствующих ей ячейках
    ///
    /// :param: book Книга
    /// :param: progress Прогресс (от 0.0 до 1.0)
    func changeDownloadProgress(progress: Float, text: String, bookId: Int) {
        // TODO: Сделать цикл только по инициализированным контроллерам
        
        let controllers = [
            ControllerManager.sharedInstance.searchTableViewController,
            ControllerManager.sharedInstance.downloadsTableViewController,
            ControllerManager.sharedInstance.favoritesTableViewController
        ]
        
        for var i = 0; i < controllers.count; ++i {
            let controller = controllers[i] as UITableViewController
            let rowCount = controller.tableView.numberOfRowsInSection(0)
            
            for var row = 0; row < rowCount; ++row {
                let indexPath = NSIndexPath(forRow: row, inSection: 0)
                
                if let cell = controller.tableView.cellForRowAtIndexPath(indexPath) as? CustomTableViewCell {
                    if cell.tag == bookId {
                        let informationLabel = cell.viewWithTag(4) as? UILabel
                        let progressBar = cell.viewWithTag(5) as? UIProgressView
                        
                        if progress == 0.0 {
                            informationLabel?.text = text
                            progressBar?.setProgress(progress, animated: false)
                            progressBar?.hidden = false
                        } else if progress < 1.0 {
                            informationLabel?.text = text
                            progressBar?.setProgress(progress, animated: true)
                        } else if progress == 1.0 {
                            informationLabel?.text = "Загружено"
                            progressBar?.hidden = true
                        }
                    }
                }
            }
        }
    }
    
    /// MARK: - Методы для отладки
    
    /// Возвращает список всех загруженных книг (pdf-документов)
    ///
    /// :returns: Список всех загруженных книг
    func getAllDocuments() -> String {
        let documentDirectory = NSHomeDirectory().stringByAppendingFormat("/Documents/")
        // let listPathContent = NSFileManager.defaultManager().subpathsOfDirectoryAtPath(documentDirectory, error: nil)
        let listPathContent = NSBundle(path: documentDirectory)!.pathsForResourcesOfType("pdf", inDirectory: nil)
        
        return join(", ", map(listPathContent) { $0.lastPathComponent })
    }
    
    /// MARK: - Методы UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? downloadableBooks.count : books.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return indexPath.section == 0 ?
            CustomTableViewCell(book: downloadableBooks[indexPath.row], query: nil) :
            CustomTableViewCell(book: books[indexPath.row], query: nil)
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.section != 0
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
                deleteBooksFromDownloads(map(selectedIndexPaths, { self.books[$0.row] }))
            } else {
                deleteAllBooksFromDownloads()
            }
        }
    }
    
    /// MARK: - Вспомогательные методы
    
    /// Обновляет заголовок секции
    func updateSectionTitle() {
        let totalBooks = books.count
        let totalDownloadableBooks = downloadableBooks.count
        let keys = [2, 0, 1, 1, 1, 2, 2, 2, 2, 2]
        let words1 = ["ЗАГРУЖАЕМЫЙ ДОКУМЕНТ", "ЗАГРУЖАЕМЫХ ДОКУМЕНТА", "ЗАГРУЖАЕМЫХ ДОКУМЕНТОВ"]
        let word1 = words1[totalDownloadableBooks % 100 > 4 && totalDownloadableBooks % 100 < 20 ? 2 : keys[totalDownloadableBooks % 10]]
        let words2 = ["ЗАГРУЖЕННЫЙ ДОКУМЕНТ", "ЗАГРУЖЕННЫХ ДОКУМЕНТА", "ЗАГРУЖЕННЫХ ДОКУМЕНТОВ"]
        let word2 = words2[totalBooks % 100 > 4 && totalBooks % 100 < 20 ? 2 : keys[totalBooks % 10]]
        
        sectionTitleLabel1.text = totalDownloadableBooks == 0 ? "" : "\(totalDownloadableBooks) \(word1)"
        sectionTitleLabel2.text = totalBooks == 0 ? "" : "\(totalBooks) \(word2)"
    }
    
    /// Показывает кнопку для редактирования таблицы
    func showEditButton() {
        tableView.setEditing(false, animated: true)
        
        let editBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "Edit"),
            style: .Plain,
            target: self,
            action: Selector("showDeleteAndCancelButtons")
        )
        navigationItem.setRightBarButtonItems([editBarButtonItem], animated: true)
    }
    
    /// Показывает кнопку для удаления документов и кнопку для отмены редактирования таблицы
    func showDeleteAndCancelButtons() {
        tableView.setEditing(true, animated: true)
        
        // Создание и добавление кнопок
        let cancelBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "Cancel"),
            style: .Plain,
            target: self,
            action: Selector("showEditButton")
        )
        let deleteBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "Trash"),
            style: .Plain,
            target: self,
            action: Selector("deleteButtonPressed")
        )
        navigationItem.setRightBarButtonItems([cancelBarButtonItem, deleteBarButtonItem], animated: true)
    }
    
    /// Обрабатывает событие, когда нажата кнопка удаления
    func deleteButtonPressed() {
        let selectedIndexPaths = tableView.indexPathsForSelectedRows()
        var actionTitleSubstring : String
        var numberOfBooksToDelete : Int
        
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
        
        let actionSheet = UIActionSheet(
            title: "Вы действительно хотите удалить из загрузок \(actionTitleSubstring)?",
            delegate: self,
            cancelButtonTitle: "Отмена",
            destructiveButtonTitle: "Удалить (\(numberOfBooksToDelete))"
        )
        actionSheet.actionSheetStyle = .Default
        actionSheet.tag = 0
        actionSheet.showInView(view)
    }
    
    /// Показывает информационный вид
    func showInformationView() {
        tableView.setEditing(false, animated: true)
        tableView.bounces = false
        navigationItem.setRightBarButtonItems(nil, animated: true)
        informationView?.removeFromSuperview()
        informationView = InformationView(
            viewController: self,
            title: "Нет документов",
            subtitle: "Здесь будут храниться\nзагруженные документы",
            buttonText: "Начать поиск") {
                self.showSearchController()
        }
        tableView.addSubview(informationView!)
    }
    
    func showSearchController() {
        ControllerManager.sharedInstance.slideMenuController.changeMainViewController(ControllerManager.sharedInstance.menuTableViewController.searchTableViewController, close: true)
        ControllerManager.sharedInstance.menuTableViewController.highlightRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0))
    }
    
    /// Скрывает информационный вид
    func hideInformationView() {
        tableView.bounces = true
        informationView?.removeFromSuperview()
    }
    
    /// Добавляет загружаемую книгу в таблицу
    ///
    /// :param: book Книга
    func addDownloadableBookToDownloads(book: Book) {
        println(book)
        changeDownloadProgress(0.0, text: "Подготовка", bookId: book.bookId)
        downloadableBooks.append(book)
        hideInformationView()
        
        let indexPathOfNewItem = NSIndexPath(forRow: downloadableBooks.count - 1, inSection: 0)
        tableView.insertRowsAtIndexPaths([indexPathOfNewItem], withRowAnimation: .Automatic)
        
        updateSectionTitle()
    }
    
    /// Удалает загружаемую книгу из таблицу
    ///
    /// :param: book Книга
    func deleteDownloadableBookToDownloads(book: Book) {
        for var i = 0; i < downloadableBooks.count; ++i {
            if downloadableBooks[i].bookId == book.bookId {
                downloadableBooks.removeAtIndex(i)
                
                let indexPathForDeletion = NSIndexPath(forRow: i, inSection: 0)
                tableView.deleteRowsAtIndexPaths([indexPathForDeletion], withRowAnimation: .Fade)
                
                break
            }
        }
        
        updateSectionTitle()
        
        if books.count == 0 && downloadableBooks.count == 0 {
            showInformationView()
        } else if books.count == 0 {
            tableView.setEditing(false, animated: true)
            navigationItem.setRightBarButtonItems(nil, animated: true)
        } else {
            showEditButton()
        }
    }
    
    /// Добавляет загруженную книгу в таблицу
    ///
    /// :param: book Книга
    func addBookToDownloads(book: Book) {
        changeDownloadProgress(1.0, text: "Загружено", bookId: book.bookId)
        books.append(book)
        hideInformationView()
        Database.sharedInstance.addBook(book, toList: "Downloads")
        updateSectionTitle()
        showEditButton()
        
        let indexPathOfNewItem = NSIndexPath(forRow: books.count - 1, inSection: 1)
        tableView.insertRowsAtIndexPaths([indexPathOfNewItem], withRowAnimation: .Automatic)
    }
    
    /// Удаляет книги из загрузок
    ///
    /// :param: books Книги для удаления
    func deleteBooksFromDownloads(booksForDeletion: [Book]) {
        for var i = 0; i < booksForDeletion.count; ++i {
            for var j = 0; j < books.count; ++j {
                if books[j].bookId == booksForDeletion[i].bookId {
                    changeDownloadProgress(0.0, text: "", bookId: books[j].bookId)
                    NSFileManager.defaultManager().removeItemAtPath(getLocalBookUrl(books[j].bookId).path!, error: nil)
                    books.removeAtIndex(j)
                    
                    let indexPathForDeletion = NSIndexPath(forRow: j, inSection: 1)
                    tableView.deleteRowsAtIndexPaths([indexPathForDeletion], withRowAnimation: .Fade)
                    
                    break
                }
            }
            
            Database.sharedInstance.deleteBookWithId(booksForDeletion[i].bookId, fromList: "Downloads")
        }
        
        updateSectionTitle()
        
        if books.count == 0 && downloadableBooks.count == 0 {
            showInformationView()
        } else if books.count == 0 {
            tableView.setEditing(false, animated: true)
            navigationItem.setRightBarButtonItems(nil, animated: true)
        } else {
            showEditButton()
        }
    }
    
    /// Удаляет все книги из загрузок
    func deleteAllBooksFromDownloads() {
        for var i = books.count - 1; i >= 0; --i {
            changeDownloadProgress(0.0, text: "", bookId: books[i].bookId)
            NSFileManager.defaultManager().removeItemAtPath(getLocalBookUrl(books[i].bookId).path!, error: nil)
        }
        
        books.removeAll(keepCapacity: false)
        tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Fade)
        Database.sharedInstance.deleteAllBooksFromList("Downloads")
        updateSectionTitle()
        
        if downloadableBooks.count == 0 {
            showInformationView()
        } else {
            tableView.setEditing(false, animated: true)
            navigationItem.setRightBarButtonItems(nil, animated: true)
        }
    }
    
    /// Возвращает локальный URL книги
    ///
    /// :param: bookId Идентификатор книги
    /// :returns: Локальный URL книги
    func getLocalBookUrl(bookId: Int) -> NSURL {
        return NSURL(fileURLWithPath: NSHomeDirectory().stringByAppendingFormat("/Documents/\(bookId).pdf"))!
    }
}
