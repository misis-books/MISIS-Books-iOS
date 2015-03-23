//
//  DownloadsTableViewController.swift
//  misisbooks
//
//  Created by Maxim Loskov on 01.12.14.
//  Copyright (c) 2014 Maxim Loskov. All rights reserved.
//

import UIKit

class DownloadsTableViewController : UITableViewController, UIDocumentInteractionControllerDelegate, UIActionSheetDelegate {
    
    /// Загруженные книги
    var books = [Book]()
    
    /// Информационный вид
    var informationView : InformationView?
    
    /// Поле заголовка секции
    var sectionTitleLabel : UILabel!
    
    /// Загружаемые книги
    private var downloadableBooks = [Book]()
    
    
    override init() {
        super.init(style: UITableViewStyle.Grouped)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func viewDidAppear(animated: Bool) {
        if books.count == 0 { // Если загруженных книг нет
            // Скрытие кнопки для редактирования таблицы
            self.navigationItem.setRightBarButtonItems(nil, animated: true)
        } else if self.tableView.editing { // Если запущен режим редактирования таблицы
            // Отображение кнопок для удаления докуменов и для отмены редактирования таблицы
            showDeleteAndCancelButtons()
        } else {
            // Отображение кнопки для редактирования таблицы
            showEditButton()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.setLeftBarButtonItem(UIBarButtonItem(image: UIImage(named: "Menu"), style: UIBarButtonItemStyle.Plain, target: ControllerManager.instance.slideMenuController, action: Selector("openLeft")), animated: false)
        // self.navigationItem.setLeftBarButtonItem(UIBarButtonItem(image: UIImage(named: "Menu"), style: UIBarButtonItemStyle.Plain, target: self, action: Selector("showBanner")), animated: false)
        
        self.tableView.allowsMultipleSelectionDuringEditing = true
        self.tableView.backgroundColor = UIColor(red: 241 / 255.0, green: 239 / 255.0, blue: 237 / 255.0, alpha: 1.0)
        self.tableView.separatorColor = UIColor(red: 178 / 255.0, green: 178 / 255.0, blue: 178 / 255.0, alpha: 1.0)
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        self.title = "Загрузки"
        
        books = Database.instance.booksForList("Downloads")
        
        println("Количество загруженных книг: " + String(books.count))
        
        if books.count == 0 {
            self.showInformationView()
        }
    }
    
    func showBanner() {
        AlertBanner(title: "Не удалось добавить в избранное", subtitle: "Невозможно подключиться к серверу").show()
    }

    /// MARK: - Методы для загрузки книги
    
    func smartUrlForString(string: NSString) -> NSURL? {
        var result : NSURL? = nil
        let trimmedString : NSString? = string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        var schemeMarkerRange : NSRange
        var scheme : NSString
        
        if trimmedString != nil && trimmedString!.length != 0 {
            schemeMarkerRange = trimmedString!.rangeOfString("://")
            
            if schemeMarkerRange.location == NSNotFound {
                result = NSURL(string: "http://" + trimmedString!)
            } else {
                scheme = trimmedString!.substringWithRange(NSMakeRange(0, schemeMarkerRange.location))
                
                if scheme.compare("http", options: NSStringCompareOptions.CaseInsensitiveSearch) == NSComparisonResult.OrderedSame || scheme.compare("https", options: NSStringCompareOptions.CaseInsensitiveSearch) == NSComparisonResult.OrderedSame {
                    result = NSURL(string: trimmedString!)
                }
            }
        }
        
        return result
    }
    
    /// Загружает книгу
    ///
    /// :param: book Книга
    func downloadBook(book: Book) {
        if downloadableBooks.count <= 5 {
            if let accessToken = NSUserDefaults.standardUserDefaults().stringForKey("accessToken") {
                MisisBooksApi.getLongUrlFromShortUrl(NSURL(string: "\(book.downloadUrl!)&access_token=\(accessToken)")!, completionHandler: {
                    (success, longUrl) -> Void in
                    if success {
                        if let sourceUrl = self.smartUrlForString(longUrl!.absoluteString!) {
                            self.downloadableBooks.append(book)
                            
                            dispatch_async(dispatch_get_main_queue()) {
                                self.changeDownloadProgress(book, progress: 0.0)
                            }
                            
                            DownloadManager.download("\(book.bookId!).pdf", sourceUrl: sourceUrl, progressBlockCompletion: {
                                (bytesWritten, bytesExpectedToWrite, downloadFileInformation) -> Void in
                                dispatch_async(dispatch_get_main_queue()) {
                                    self.changeDownloadProgress(book, progress: Float(bytesWritten) / Float(bytesExpectedToWrite))
                                }
                                }, responseBlockCompletion: {
                                    (error, downloadFileInformation) -> Void in
                                    for var i = 0; i < self.downloadableBooks.count; ++i {
                                        if self.downloadableBooks[i].bookId == book.bookId {
                                            self.downloadableBooks.removeAtIndex(i)
                                        }
                                    }
                                    
                                    if error == nil {
                                        println("Файл загружен: \(downloadFileInformation.pathDestination.absoluteString!)")
                                        
                                        dispatch_async(dispatch_get_main_queue()) {
                                            self.addBookToDownloads(book)
                                            self.changeDownloadProgress(book, progress: 1.0)
                                        }
                                    } else {
                                        AlertBanner(title: "Не удалось загрузить документ", subtitle: "Соединение с сервером прервано").show()
                                    }
                            })
                        } else {
                            AlertBanner(title: "Невозможно начать загрузку", subtitle: "Некорректный URL для загрузки").show()
                        }
                    } else {
                        AlertBanner(title: "Невозможно начать загрузку", subtitle: "Не получен длинный URL").show()
                    }
                })
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
    func changeDownloadProgress(book: Book, progress: Float) {
        // TODO: Сделать цикл только по инициализированным контроллерам
        
        let controllers = [
            ControllerManager.instance.searchTableViewController,
            ControllerManager.instance.downloadsTableViewController,
            ControllerManager.instance.favoritesTableViewController
        ]
        
        for var i = 0; i < controllers.count; ++i {
            let controller = controllers[i] as UITableViewController
            let rowCount = controller.tableView.numberOfRowsInSection(0)
            
            for var row = 0; row < rowCount; ++row {
                let indexPath = NSIndexPath(forRow: row, inSection: 0)
                
                if let cell = controller.tableView.cellForRowAtIndexPath(indexPath) as? CustomTableViewCell {
                    if cell.tag == book.bookId {
                        let infoLabel = cell.viewWithTag(4) as? UILabel
                        let progressBar = cell.viewWithTag(5) as? UIProgressView
                        
                        if progress == 0.0 {
                            infoLabel?.text = ""
                            progressBar?.setProgress(progress, animated: false)
                            progressBar?.hidden = false
                        } else if progress < 1.0 {
                            infoLabel?.text = "Загрузка: \(Int(progress * 100))%"
                            progressBar?.setProgress(progress, animated: true)
                        } else if progress == 1.0 {
                            infoLabel?.text = "Загружено"
                            progressBar?.hidden = true
                        }
                    }
                }
            }
        }
    }
    
    /// MARK: - Методы для отладки
    
    /* func debugPrintDocumentsList() {
        let documentDirectory: NSString = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).objectAtIndex(0) as NSString
        
        let listPathContent: NSArray = NSBundle(path: documentDirectory).pathsForResourcesOfType("pdf", inDirectory: nil)
        // NSArray *listPathContent = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:documentDirectory error:nil];
        var documents: NSMutableArray = NSMutableArray()
    
        for let i = 0; i < listPathContent.count; i++ {
            documents.addObject(listPathContent.objectAtIndex(i).lastPathComponent)
        }
        
        NSLog("Все загруженные PDF-документы: [%@].", documents.componentsJoinedByString(", "))
    } */
    
    /// MARK: - Методы UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return books.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return CustomTableViewCell(book: books[indexPath.row], query: nil)
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 26.0
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 8.0
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        sectionTitleLabel = UILabel(frame: CGRectMake(15.0, 6.0, tableView.frame.size.width - 30.0, 20.0))
        sectionTitleLabel.backgroundColor = UIColor.clearColor()
        sectionTitleLabel.font = UIFont(name: "HelveticaNeue", size: 13.0)
        sectionTitleLabel.shadowColor = UIColor.whiteColor()
        sectionTitleLabel.shadowOffset = CGSizeMake(0.0, -1.0)
        sectionTitleLabel.textColor = UIColor.darkGrayColor()
        
        // Обновление заголовка секции
        updateSectionTitle()
        
        let sectionHeaderView = UIView(frame: CGRectMake(0.0, 0.0, tableView.frame.size.width, 26.0))
        sectionHeaderView.addSubview(sectionTitleLabel)
        
        return sectionHeaderView
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            changeDownloadProgress(books[indexPath.row], progress: 0.0) // удаление статуса "Загружено"
            NSFileManager.defaultManager().removeItemAtPath(getFullPathToFileByBookId(books[indexPath.row].bookId!), error: nil) // удаление файла загруженной книги
            Database.instance.deleteBookWithId(books[indexPath.row].bookId!, fromList: "Downloads") // удаление загруженной книги из базы данных
            books.removeAtIndex(indexPath.row) // удаление загруженной книги из массива
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade) // удаление загруженной книги из таблицы

            // Обновление заголовка секции
            updateSectionTitle()
            
            if books.count == 0 { // Если загруженных книг нет
                self.showInformationView() // Отображение информационного вида
            }
        }
    }
    
    /// MARK: - Методы UITableViewDelegate
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return CustomTableViewCell.heightForRowWithBook(books[indexPath.row])
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if !tableView.editing { // Если не запущен режим редактирования таблицы
            let documentationInteractionController = UIDocumentInteractionController(URL: NSURL(fileURLWithPath: getFullPathToFileByBookId(books[indexPath.row].bookId!))!)
            documentationInteractionController.delegate = self
            documentationInteractionController.name = books[indexPath.row].name
            documentationInteractionController.presentPreviewAnimated(true)
        }/* else {
            let selectedIndexPaths = self.tableView.indexPathsForSelectedRows()
            var prompt : String?
            
            if selectedIndexPaths?.count == 1 {
                prompt = "Выбран 1 документ"
            } else if selectedIndexPaths?.count > 1 {
                prompt = "Выбрано 2 документа"
            } else if selectedIndexPaths?.count == 0 {
                prompt = nil
            }
            
            self.navigationItem.prompt = prompt
        } */
    }
    
    /// MARK: - Методы DocumentInteractionViewController
    
    func documentInteractionControllerViewControllerForPreview(controller: UIDocumentInteractionController) -> UIViewController {
        return self.navigationController!
    }
    
    /// MARK: - Методы UIActionSheetDelegate
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 0 {
            if var selectedIndexPaths = self.tableView.indexPathsForSelectedRows() { // Если выбраны какие-то ячейки
                // Сортировка индексов ячеек в порядке убывания. В массиве selectedIndexPaths индексы ячеек расположены в порядке их выделения пользователем, поэтому нельзя допустить, чтобы на этапе удаления книги из массива было обращение по несуществующему индексу, потому что размер массива с каждой итерацией уменьшается
                sort(&selectedIndexPaths, { $0.row > $1.row })
                
                // Удаление выбранных книг
                for var i = 0; i < selectedIndexPaths.count; ++i {
                    // Удаление статуса "Загружено" со всех ячеек
                    changeDownloadProgress(books[selectedIndexPaths[i].row], progress: 0.0)
                    
                    // Удаление файла книги
                    NSFileManager.defaultManager().removeItemAtPath(getFullPathToFileByBookId(books[selectedIndexPaths[i].row].bookId!), error: nil)
                    
                    // Удаление книги из базы данных
                    Database.instance.deleteBookWithId(books[selectedIndexPaths[i].row].bookId!, fromList: "Downloads")
                    
                    // удаление книги из массива
                    books.removeAtIndex(selectedIndexPaths[i].row)
                }
                
                // Удаление выбранных книг из таблицы
                self.tableView.deleteRowsAtIndexPaths(selectedIndexPaths, withRowAnimation: UITableViewRowAnimation.Fade)
            } else {
                // Удаление всех книг
                for var i = 0; i < books.count; ++i {
                    // Удаление статуса "Загружено" со всех ячеек
                    changeDownloadProgress(books[i], progress: 0.0)
                    
                    // Удаление файла книги
                    NSFileManager.defaultManager().removeItemAtPath(getFullPathToFileByBookId(books[i].bookId!), error: nil)
                    
                    // Удаление книги из базы данных
                    Database.instance.deleteBookWithId(books[i].bookId!, fromList: "Downloads")
                }
                
                // Удаление всех книг из массива
                books.removeAll()
                
                // Удаление всех книг из таблицы
                self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Fade)
            }
        }
        
        // Отключение режима редактирования таблицы
        self.tableView.setEditing(false, animated: true)
        
        // Обновление заголовка секции
        updateSectionTitle()
        
        if books.count == 0 { // Если книг нет
            // Отображение информационного вида
            showInformationView()
        } else {
            // Отображение кнопки редактирования
            showEditButton()
        }
    }
    
    /// MARK: - Вспомогательные методы
    
    func updateSectionTitle() {
        let numberOfBooks = books.count
        let formats = ["ДОКУМЕНТ", "ДОКУМЕНТА", "ДОКУМЕНТОВ"]
        let keys = [2, 0, 1, 1, 1, 2, 2, 2, 2, 2]
        
        sectionTitleLabel.text = numberOfBooks == 0 ? "" : "\(numberOfBooks) \(formats[numberOfBooks % 100 > 4 && numberOfBooks % 100 < 20 ? 2 : keys[numberOfBooks % 10]])"
    }
    
    /// Загружает файлы из директории с документами
    /*- (void)loadFilesFromDocumentDirectory {
    _downloadedBooks = nil;
    
    NSString *documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSArray *listPathContent = [[NSBundle bundleWithPath:documentDirectory] pathsForResourcesOfType:@"pdf" inDirectory:nil];
    
    _downloadedBooks = [NSMutableArray new];
    
    for (NSInteger i = 0; i < listPathContent.count; i++) {
    NSString *fileName = [[listPathContent objectAtIndex:i] lastPathComponent];
    
    [_downloadedBooks addObject:fileName];
    }
    }*/
    
    /// Показывает кнопку для редактирования таблицы
    func showEditButton() {
        // Отключение режима редактирования таблицы
        self.tableView.setEditing(false, animated: true)
        
        // Создание и добавление кнопки для редактирования таблицы
        self.navigationItem.setRightBarButtonItems([UIBarButtonItem(image: UIImage(named: "Edit"), style: UIBarButtonItemStyle.Plain, target: self, action: Selector("showDeleteAndCancelButtons"))], animated: true)
        
        // self.navigationItem.prompt = nil
    }
    
    /// Показывает кнопку для удаления документов и кнопку для отмены редактирования таблицы
    func showDeleteAndCancelButtons() {
        // Включение режима редактирования таблицы
        self.tableView.setEditing(true, animated: true)
        
        // Создание и добавление кнопок
        let cancelBarButtonItem = UIBarButtonItem(image: UIImage(named: "Cancel"), style: UIBarButtonItemStyle.Plain, target: self, action: Selector("showEditButton"))
        let deleteBarButtonItem = UIBarButtonItem(image: UIImage(named: "Trash"), style: UIBarButtonItemStyle.Plain, target: self, action: Selector("deleteButtonPressed"))
        self.navigationItem.setRightBarButtonItems([cancelBarButtonItem, deleteBarButtonItem], animated: true)
    }
    
    /// Обрабатывает событие, когда нажата кнопка для удаления
    func deleteButtonPressed() {
        let selectedIndexPaths = self.tableView.indexPathsForSelectedRows()
        var actionTitle : String
        
        if selectedIndexPaths?.count == 1 {
            actionTitle = "Вы действительно хотите удалить из загрузок этот документ?"
        } else if selectedIndexPaths?.count > 1 {
            actionTitle = "Вы действительно хотите удалить из загрузок эти документы?"
        } else {
            actionTitle = "Вы действительно хотите удалить из загрузок все документы?"
        }
        
        let actionSheet = UIActionSheet(title: actionTitle, delegate: self, cancelButtonTitle: "Отмена", destructiveButtonTitle: "Удалить")
        actionSheet.actionSheetStyle = UIActionSheetStyle.Default
        actionSheet.showInView(self.view)
    }
    
    /// Показывает информационный вид
    func showInformationView() {
        // Отключение режима редактирования таблицы (он мог быть запущен)
        self.tableView.setEditing(false, animated: true)
        
        // Отключение прокрутки таблицы
        self.tableView.bounces = false
        
        // Скрытие кнопки для редактирования таблицы
        self.navigationItem.setRightBarButtonItems(nil, animated: true)
        
        // Создание и добавление информационного вида
        informationView = InformationView(viewController: self, title: "Нет документов", subtitle: "Здесь будут храниться\nзагруженные документы", linkButtonText: "Начать поиск") {
            self.showSearchController()
        }
        self.tableView.addSubview(informationView!)
    }
    
    func showSearchController() {
        ControllerManager.instance.slideMenuController.changeMainViewController(ControllerManager.instance.menuTableViewController.searchTableViewController, close: true)
        ControllerManager.instance.menuTableViewController.highlightRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0))
    }
    
    /// Скрывает информационный вид
    func hideInformationView() {
        // Включение прокрутки таблицы
        self.tableView.bounces = true
        
        // Удаление информационного вида
        informationView?.removeFromSuperview()
    }
    
    /// Добавляет загруженную книгу в таблицу и базу данных
    ///
    /// :param: book Книга
    func addBookToDownloads(book: Book) {
        // Добавление книги в базу данных
        Database.instance.addBook(book, toList: "Downloads")
        
        // Добавление книги в массив
        books.append(book)
        
        // Скрытие информационного вида
        hideInformationView()
        
        // Обновление данных таблицы
        let indexPathOfNewItem = NSIndexPath(forRow: books.count - 1, inSection: 0)
        self.tableView.beginUpdates()
        self.tableView.insertRowsAtIndexPaths([indexPathOfNewItem], withRowAnimation: UITableViewRowAnimation.Automatic)
        self.tableView.endUpdates()
        // self.tableView.scrollToRowAtIndexPath(indexPathOfNewItem, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
        
        // Обновление заголовка секции
        updateSectionTitle()
    }
    
    /// Возвращает полный путь к файлу с заданным идентификатором книги
    ///
    /// :param: bookId Идентификатор книги
    /// :returns: Полный путь к файлу
    func getFullPathToFileByBookId(bookId: Int) -> String {
        return NSHomeDirectory().stringByAppendingFormat("/Documents/" + String(bookId) + ".pdf") // NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0].stringByAppendingPathComponent(String(bookId) + ".pdf")
    }
}