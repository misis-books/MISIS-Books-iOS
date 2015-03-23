//
//  SearchTableViewController.swift
//  misisbooks
//
//  Created by Maxim Loskov on 06.12.14.
//  Copyright (c) 2014 Maxim Loskov. All rights reserved.
//

import UIKit

class SearchTableViewController : UITableViewController, UISearchBarDelegate, UIScrollViewDelegate, UIDocumentInteractionControllerDelegate, PreloaderViewDelegate, FilterTableViewControllerDelegate {
    
    /// Последний введенный запрос
    var lastInput = ""
    
    /// Массив книг
    var books = [Book]()
    
    /// Поисковая строка
    var searchBar : UISearchBar!
    
    /// Кнопка фильтрации разультатов
    var filterButton : UIBarButtonItem!
    
    /// Вид подгрузчика результатов
    var preloaderView : PreloaderView?
    
    /// Информационный вид
    var informationView : InformationView?
    
    /// Флаг состояния подгрузки
    var loadingMore = false
    
    /// Индикатор активности
    var activityIndicator : UIActivityIndicatorView!
    
    /// API MISIS Books
    var misisBooksApi : MisisBooksApi!
    
    /// Количество результатов
    var count = 20
    
    /// Смещение выборки результатов
    var offset = 0
    
    /// Категория
    var category = 1
    
    /// Действие
    var action : MisisBooksApiAction!
    
    /// Строка для заголовка секции
    private var sectionTitle : String!
    
    
    override init() {
        super.init(style: UITableViewStyle.Grouped)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.setLeftBarButtonItem(UIBarButtonItem(image: UIImage(named: "Menu"), style: UIBarButtonItemStyle.Plain, target: ControllerManager.instance.slideMenuController, action: Selector("openLeft")), animated: false)
        self.navigationItem.setRightBarButtonItem(UIBarButtonItem(image: UIImage(named: "Filter"), style: UIBarButtonItemStyle.Plain, target: self, action: Selector("filterButtonPressed")), animated: false)
        self.tableView.registerClass(CustomTableViewCell.self, forCellReuseIdentifier: CustomTableViewCell.reuseIdentifier)
        self.tableView.backgroundColor = UIColor(red: 241 / 255.0, green: 239 / 255.0, blue: 237 / 255.0, alpha: 1.0)
        self.tableView.separatorColor = UIColor(red: 178 / 255.0, green: 178 / 255.0, blue: 178 / 255.0, alpha: 1.0)
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        
        searchBar = UISearchBar(frame: CGRectZero)
        searchBar.autocapitalizationType = UITextAutocapitalizationType.None
        searchBar.autocorrectionType = UITextAutocorrectionType.No
        searchBar.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        searchBar.delegate = self
        searchBar.searchBarStyle = UISearchBarStyle.Minimal
        searchBar.placeholder = "Поиск"
        searchBar.tintColor = UIColor.darkGrayColor()
        self.navigationItem.titleView = searchBar
        
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        activityIndicator.center = CGPointMake(self.view.frame.size.width / 2, 18.0)
        activityIndicator.startAnimating()
        self.view.addSubview(activityIndicator)
        
        action = MisisBooksApiAction.GetPopular
        misisBooksApi.getPopular(count: count, category: category)
        
        NSTimer.scheduledTimerWithTimeInterval(0.8, target: self, selector: Selector("checkInput"), userInfo: nil, repeats: true)
    }
    
    /// MARK: - Вспомогательные методы
    
    /// Проверяет, изменился ли текст в поисковой строке
    func checkInput() {
        if lastInput != searchBar.text {
            lastInput = searchBar.text
            books = [Book]()
            sectionTitle = ""
            setEmptyTableFooterView()
            self.tableView.reloadData()
            activityIndicator.startAnimating()
            
            if searchBar.text == "" {
                action = MisisBooksApiAction.GetPopular
                misisBooksApi.getPopular(count: count, category: category)
            } else {
                offset = 0
                action = MisisBooksApiAction.Search
                misisBooksApi.search(query: lastInput, count: count, offset: offset, category: category)
            }
        }
    }
    
    func setEmptyTableFooterView() {
        preloaderView = nil
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
    }
    
    func setTableFooterView(allItemsCount: Int) {
        let numberOfRemainingResults = allItemsCount - offset - 20 // количество оставшихся результатов, которые можно подгрузить
        let numberOfNextResults = numberOfRemainingResults >= 20 ? 20 : numberOfRemainingResults // количество элементов, которые будут подгружены
        
        if numberOfRemainingResults <= 0 {
            println("Больше нечего подгружать.")
            
            setEmptyTableFooterView()
        } else {
            println("Результаты, которые можно подгрузить: \(numberOfNextResults), оставшиеся результаты: \(numberOfRemainingResults).")
            
            if preloaderView != nil { // возможна следующая подгрузка для данного запроса
                preloaderView?.textLabel?.text = getStringForLabelOfPreloaderView(numberOfNextResults, numberOfRemainingResults: numberOfRemainingResults)
            } else { // возможна первая подгрузка для данного запроса
                preloaderView = PreloaderView(frame: CGRectMake(0.0, 0.0, self.tableView.bounds.size.width, self.tableView.bounds.size.height))
                preloaderView!.textLabel?.text = getStringForLabelOfPreloaderView(numberOfNextResults, numberOfRemainingResults: numberOfRemainingResults)
                preloaderView!.delegate = self
                self.tableView.tableFooterView = preloaderView!
            }
        }
    }
    
    func getStringForSectionHeader(numberOfAllResults: Int) -> String {
        let formats = ["НАЙДЕН %d ДОКУМЕНТ",
            "НАЙДЕНО %d ДОКУМЕНТА",
            "НАЙДЕНО %d ДОКУМЕНТОВ"]
        let keys = [2, 0, 1, 1, 1, 2, 2, 2, 2, 2]
        let ending = numberOfAllResults % 100 > 4 && numberOfAllResults % 100 < 20 ? 2 : keys[numberOfAllResults % 10]
        
        return numberOfAllResults == 0 ? "ПОИСК НЕ ДАЛ РЕЗУЛЬТАТОВ" : String(format: formats[ending], numberOfAllResults)
    }
    
    /// Возвращает строку для поля вида подгрузчика результатов с правильным сколонением слов
    ///
    /// :param: numberOfNextResults Количество следующих результатов
    /// :param: numberOfRemainingResults Количество оставшихся результатов
    /// :returns: Строка для поля вида подгрузчика результатов
    func getStringForLabelOfPreloaderView(numberOfNextResults: Int, numberOfRemainingResults: Int) -> String {
        let formats = ["Потяните вверх, чтобы увидеть\nследующий %d результат из %d",
            "Потяните вверх, чтобы увидеть\nследующие %d результата из %d",
            "Потяните вверх, чтобы увидеть\nследующие %d результатов из %d"]
        let keys = [2, 0, 1, 1, 1, 2, 2, 2, 2, 2]
        let ending = numberOfNextResults % 100 > 4 && numberOfNextResults % 100 < 20 ? 2 : keys[numberOfNextResults % 10]
        
        return String(format: formats[ending], numberOfNextResults, numberOfRemainingResults)
    }
    
    /// Обрабатывает событие, когда нажата кнопка фильтрации результатов
    func filterButtonPressed() {
        let filterTableViewController = FilterTableViewController(selectedCategory: category, delegate: self)
        let presentViewController = UINavigationController(rootViewController: filterTableViewController)
        presentViewController.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
        self.presentViewController(presentViewController, animated: true, completion: nil)
    }
    
    /// MARK: - Методы FilterTableViewControllerDelegate
    
    func filterTableViewControllerDidChangeCategory(selectedCategory: Int) {
        println("Выбрана категория: \(selectedCategory).")
        
        books = [Book]()
        sectionTitle = ""
        setEmptyTableFooterView()
        self.tableView.reloadData()
        activityIndicator.startAnimating()
        category = selectedCategory
        
        if searchBar.text == "" {
            action = MisisBooksApiAction.GetPopular
            misisBooksApi.getPopular(count: count, category: category)
        } else {
            offset = 0
            action = MisisBooksApiAction.Search
            misisBooksApi.search(query: lastInput, count: count, offset: offset, category: category)
        }
    }
    
    /// MARK: - Методы UISearchBarDelegate
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        filterButton = self.navigationItem.rightBarButtonItem
        self.navigationItem.setRightBarButtonItem(UIBarButtonItem(image: UIImage(named: "Cancel"), style: UIBarButtonItemStyle.Plain, target: self, action: Selector("searchCancelButtonClicked")), animated: true)
    }
    
    func searchCancelButtonClicked() {
        searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        self.navigationItem.setRightBarButtonItem(filterButton, animated: true)
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    /// MARK: - Методы UITableViewDataSource

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return books.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return CustomTableViewCell(book: books[indexPath.row], query: lastInput)
    }
            
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 26.0
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 8.0
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionTitleLabel = UILabel(frame: CGRectMake(15.0, 6.0, tableView.frame.size.width - 30.0, 20.0))
        sectionTitleLabel.backgroundColor = UIColor.clearColor()
        sectionTitleLabel.font = UIFont(name: "HelveticaNeue", size: 13.0)
        sectionTitleLabel.shadowColor = UIColor.whiteColor()
        sectionTitleLabel.shadowOffset = CGSizeMake(0.0, -1.0)
        sectionTitleLabel.text = sectionTitle
        sectionTitleLabel.textColor = UIColor.darkGrayColor()
        
        let sectionHeaderView = UIView(frame: CGRectMake(0.0, 0.0, tableView.frame.size.width, 26.0))
        sectionHeaderView.addSubview(sectionTitleLabel)
        
        return sectionHeaderView
    }
    
    /// MARK: - Методы UITableViewDelegate
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return CustomTableViewCell.heightForRowWithBook(books[indexPath.row])
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        searchBar.resignFirstResponder()
        
        let book = books[indexPath.row]
        let isBookAddedToDownloads = Database.instance.isBookWithId(book.bookId!, addedToList: "Downloads")
        let isBookAddedToFavorites = Database.instance.isBookWithId(book.bookId!, addedToList: "Favorites")
        
        let alertController = UIAlertController(title: book.name!, message: "Размер файла: " + book.fileSize!, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        if isBookAddedToDownloads {
            alertController.addAction(UIAlertAction(title: "Просмотреть документ", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                let documentationInteractionController = UIDocumentInteractionController(URL: NSURL(fileURLWithPath: ControllerManager.instance.downloadsTableViewController.getFullPathToFileByBookId(book.bookId!))!)
                documentationInteractionController.delegate = self
                documentationInteractionController.name = book.name
                documentationInteractionController.presentPreviewAnimated(true)
            }))
        } else {
            alertController.addAction(UIAlertAction(title: "Загрузить документ", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                ControllerManager.instance.downloadsTableViewController.downloadBook(book)
            }))
        }
        
        if isBookAddedToFavorites {
            alertController.addAction(UIAlertAction(title: "Удалить из избранного", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                ControllerManager.instance.favoritesTableViewController.deleteBookFromFavorites(book.bookId!)
            }))
        } else {
            alertController.addAction(UIAlertAction(title: "Добавить в избранное", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                ControllerManager.instance.favoritesTableViewController.addBookToFavorites(book)
            }))
        }
        
        alertController.addAction(UIAlertAction(title: "Отмена", style: UIAlertActionStyle.Cancel, handler: nil))
        
        
        if let popoverPresentationController = alertController.popoverPresentationController {
            let sender = tableView.cellForRowAtIndexPath(indexPath)!
            popoverPresentationController.sourceView = sender
            popoverPresentationController.sourceRect = sender.bounds
            popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirection.Any
        }
        
        self.presentViewController(alertController, animated: true, completion: nil)
        
        /* if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone {
            self.presentViewController(alertController, animated: true, completion: nil)
        } else {
            let popup = UIPopoverController(contentViewController: alertController)
            popup.presentPopoverFromRect(CGRectMake(UIScreen.mainScreen().bounds.size.width / 2, UIScreen.mainScreen().bounds.size.height / 2, 0, 0), inView: self.view, permittedArrowDirections: UIPopoverArrowDirection.allZeros, animated: true)
        } */
    }
    
    /// MARK: - Методы DocumentInteractionViewController
    
    func documentInteractionControllerViewControllerForPreview(controller: UIDocumentInteractionController) -> UIViewController {
        return self.navigationController!
    }
    
    /// MARK: - Методы UIScrollViewDelegate
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        preloaderView?.preloaderViewScrollViewDidScroll(scrollView)
        
        // [scrollView setBounces:(scrollView.contentOffset.y > 10)];
    }
    
    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        preloaderView?.preloaderViewScrollViewDidEndDragging(scrollView)
    }
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        searchBar.resignFirstResponder()
    }
        
    /// MARK: - Методы, вызываемые MisisBooksApi
    
    func updateTableWithReceivedBooks(receivedBooks: [Book], allItemsCount: Int) {
        loadingMore = false
        activityIndicator.stopAnimating()
        
        informationView?.removeFromSuperview() // удаление информационного вида
        informationView = nil
        self.tableView.bounces = true // включение прокрутки таблицы
        
        if offset == 0 {
            books = receivedBooks
            
            // Плавное обновление таблицы
            UIView.transitionWithView(self.tableView, duration: 0.2, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
                self.tableView.reloadData()
                }, completion: nil)
            
            if action == MisisBooksApiAction.GetPopular {
                sectionTitle = "ПОПУЛЯРНОЕ"
                setEmptyTableFooterView()
            } else if action == MisisBooksApiAction.Search {
                sectionTitle = getStringForSectionHeader(allItemsCount)
                setTableFooterView(allItemsCount)
            }
        } else {
            let numberOfBooks = books.count
            var newPaths = [NSIndexPath]()
            
            for var i = 0; i < receivedBooks.count; ++i {
                books.append(receivedBooks[i])
                newPaths.append(NSIndexPath(forRow: numberOfBooks + i, inSection: 0))
            }
            
            self.tableView.beginUpdates()
            self.tableView.insertRowsAtIndexPaths(newPaths, withRowAnimation: UITableViewRowAnimation.Automatic)
            self.tableView.endUpdates()
            
            preloaderView?.preloaderViewDataSourceDidFinishedLoading()
            
            setTableFooterView(allItemsCount)
        }

    }
    
    func showInformationView(informationView: InformationView) {
        loadingMore = false
        
        // Возвращение поисковой строки в обычное состояние
        searchBar.resignFirstResponder()
        
        // Отключение анимации индикатора активности
        activityIndicator.stopAnimating()
        
        // Удаление старого информационного вида
        self.informationView?.removeFromSuperview()
        
        // Установка нового информационного вида
        self.informationView = informationView
        
        // Отображение информационного вида
        self.tableView.addSubview(informationView)
        
        // Отключение прокрутки таблицы
        self.tableView.bounces = false
    }
    
    /// MARK: - Методы PreloaderViewDelegate
    
    func preloaderViewDataSourceIsLoading() -> Bool! {
        return loadingMore
    }
    
    func preloaderViewDidTriggerRefresh() {
        loadingMore = true
        offset += count
        
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue()) {
            self.action = MisisBooksApiAction.Search
            self.misisBooksApi.search(query: self.lastInput, count: self.count, offset: self.offset, category: self.category)
        }
    }
}
