//
//  FavoritesTableViewController.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 06.12.14.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit

/**
    Класс для представления контроллера избранного
*/
class FavoritesTableViewController: BookTableViewController, PreloaderViewDelegate {
    
    /// Действие
    var action: MisisBooksApiAction!
    
    /// Индикатор активности
    var activityIndicator: UIActivityIndicatorView!
    
    /// Количество результатов
    private var count = 20
    
    /// Флаг состояния готовности контроллера
    var isReady = false
    
    /// Флаг состояния подгрузки
    private var loadingMore = false
    
    /// Смещение выборки
    private var offset = 0
    
    /// Вид-подгрузчик
    private var preloaderView: PreloaderView?
    
    /// Вид-заполнитель
    var placeholderView: PlaceholderView?
    
    /// Общее количество разультатов
    private var totalResults = 0
    
    override func viewDidAppear(animated: Bool) {
        updateSectionTitle()
        isReady = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsMultipleSelectionDuringEditing = true
        title = "Избранное"
        
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        activityIndicator.center = CGPointMake(view.bounds.size.width / 2, 18)
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        
        action = .GetFavorites
        MisisBooksApi.instance.getFavorites(count: count, offset: offset)
    }
    
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation,
        duration: NSTimeInterval) {
            if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                placeholderView?.setNeedsLayout()
            }

            activityIndicator.center = CGPointMake(view.bounds.size.width / 2, 18)
    }
    
    /**
        Добавляет книгу в избранное

        - parameter book: Книга
    */
    func addBook(book: Book) {
        for bookInSearch in ControllerManager.instance.searchTableViewController.books {
            if bookInSearch.id == book.id {
                bookInSearch.isMarkedAsFavorite = true
            }
        }
        
        books.insert(book, atIndex: 0)
        
        if isReady {
            tableView?.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Automatic)
        }
        
        changeFavoriteState(true, bookId: book.id)
        Database.instance.addBook(book, toList: "favorites")
        totalResults += 1
        sectionTitleLabel1.text = textForSectionHeader(totalResults)
        showUpdateAndEditButtons()
        hidePlaceholderView()
    }
    
    /**
        Удаляет все книги из избранного
    */
    func deleteAllBooks() {
        for book in books {
            for bookInSearch in ControllerManager.instance.searchTableViewController.books {
                if bookInSearch.id == book.id {
                    bookInSearch.isMarkedAsFavorite = false
                }
            }
            
            changeFavoriteState(false, bookId: book.id)
        }
        
        books.removeAll(keepCapacity: false)
        tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Fade)
        Database.instance.deleteAllBooksFromList("favorites")
        totalResults = 0
        offset = 0
        sectionTitleLabel1.text = textForSectionHeader(totalResults)
        removePreloaderView()
        showPlaceholderView(PlaceholderView(viewController: self, title: "Нет документов",
            subtitle: "Здесь появятся документы,\nотмеченные как избранные", buttonText: "Начать поиск") {
                self.showSearchController()
            })
    }
    
    /**
        Удаляет книги из избранного

        - parameter booksForDeletion: Книги для удаления
    */
    func deleteBooks(booksToDelete: [Book]) {
        for bookForDeletion in booksToDelete {
            for bookInSearch in ControllerManager.instance.searchTableViewController.books {
                if bookInSearch.id == bookForDeletion.id {
                    bookInSearch.isMarkedAsFavorite = false
                }
                
                changeFavoriteState(false, bookId: bookForDeletion.id)
            }
            
            for i in 0..<books.count {
                if books[i].id == bookForDeletion.id {
                    books.removeAtIndex(i)
                    
                    if isReady {
                        tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: i, inSection: 0)], withRowAnimation: .Fade)
                    }
                    
                    break
                }
            }
            
            Database.instance.deleteBook(bookForDeletion, fromList: "favorites")
        }
        
        // offset += booksToDelete.count
        totalResults -= booksToDelete.count
        sectionTitleLabel1.text = textForSectionHeader(totalResults)
        // updateSectionTitle()
        
        if books.count == 0 {
            showPlaceholderView(PlaceholderView(viewController: self, title: "Нет документов",
                subtitle: "Здесь появятся документы,\nотмеченные как избранные", buttonText: "Начать поиск") {
                    self.showSearchController()
                })
        } else {
            showUpdateAndEditButtons()
        }
    }
    
    /**
        Обрабатывает событие, когда нажата кнопка удаления
    */
    func deleteButtonPressed() {
        let selectedIndexPaths = tableView.indexPathsForSelectedRows
        let actionTitleSubstring: String
        let numberOfBooksToDelete: Int
        
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
        
        let actionSheet = UIActionSheet(title: "Вы действительно хотите удалить из избранного \(actionTitleSubstring)?",
            delegate: self, cancelButtonTitle: "Отмена", destructiveButtonTitle: "Удалить (\(numberOfBooksToDelete))")
        actionSheet.actionSheetStyle = .Default
        actionSheet.tag = 0
        actionSheet.showInView(view)
    }
    
    /**
        Загружает книги из базы данных
    */
    func loadBooksFromDatabase() {
        activityIndicator.stopAnimating()
        books = Array(Database.instance.booksForList("favorites").reverse())
        totalResults = books.count
        sectionTitleLabel1.text = textForSectionHeader(totalResults)
        
        if books.count == 0 {
            showPlaceholderView(PlaceholderView(viewController: self, title: "Нет документов",
                subtitle: "Здесь появятся документы,\nотмеченные как избранные", buttonText: "Начать поиск") {
                    self.showSearchController()
                })
        } else {
            showUpdateAndEditButtons()
            
        }
        
        let allDocuments = ", ".join(books.map { String($0.id) })
        print("Избранные книги (\(books.count)): [\(allDocuments)]")
        
        tableView.reloadData()
    }
    
    /**
        Показывает кнопки для удаления документов и отмены редактирования таблицы
    */
    func showDeleteAndCancelButtons() {
        setEditing(true, animated: true)
        navigationItem.setRightBarButtonItems([UIBarButtonItem(image: UIImage(named: "Cancel"), style: .Plain, target: self,
            action: "showUpdateAndEditButtons"), UIBarButtonItem(image: UIImage(named: "Trash"), style: .Plain, target: self,
                action: "deleteButtonPressed")], animated: true)
    }
    
    /**
        Показывает вид-заполнитель
    
        - parameter placeholderView: Вид-заполнитель
    */
    func showPlaceholderView(placeholderView: PlaceholderView) {
        showUpdateButton()
        loadingMore = false
        activityIndicator.stopAnimating()
        self.placeholderView?.removeFromSuperview()
        self.placeholderView = placeholderView
        books.removeAll(keepCapacity: false)
        tableView.reloadData()
        tableView.addSubview(self.placeholderView!)
        tableView.bounces = false
        setEditing(false, animated: true)
    }
    
    /**
        Показывает кнопки для обновления и редактирования таблицы
    */
    func showUpdateAndEditButtons() {
        setEditing(false, animated: true)
        navigationItem.setRightBarButtonItems([UIBarButtonItem(image: UIImage(named: "Edit"), style: .Plain, target: self,
            action: "showDeleteAndCancelButtons"), UIBarButtonItem(image: UIImage(named: "Update"), style: .Plain, target: self,
                action: "updateButtonPressed")], animated: true)
    }
    
    /**
        Показывает кнопку для обновления таблицы
    */
    func showUpdateButton() {
        navigationItem.setRightBarButtonItems([UIBarButtonItem(image: UIImage(named: "Update"), style: .Plain, target: self,
            action: "updateButtonPressed")], animated: true)
    }
    
    /**
        Обрабатывает событие, когда нажата кнопка обновления
    */
    func updateButtonPressed() {
        books.removeAll(keepCapacity: false)
        sectionTitleLabel1.text = ""
        removePreloaderView()
        activityIndicator.startAnimating()
        placeholderView?.removeFromSuperview()
        placeholderView = nil
        
        UIView.transitionWithView(self.tableView, duration: 0.2, options: .TransitionCrossDissolve, animations: {
            self.tableView.reloadData()
            }, completion: nil)
        
        count = 20
        offset = 0
        action = .GetFavorites
        MisisBooksApi.instance.getFavorites(count: count, offset: offset)
    }
    
    /**
        Обновляет таблицу

        - parameter receivedBooks: Полученные книги
        - parameter totalResults: Общее количество результатов
    */
    func updateTable(receivedBooks: [Book], totalResults: Int) {
        loadingMore = false
        activityIndicator.stopAnimating()
        placeholderView?.removeFromSuperview()
        placeholderView = nil
        tableView.bounces = true
        
        if offset == 0 {
            books = receivedBooks
            
            UIView.transitionWithView(self.tableView, duration: 0.2, options: .TransitionCrossDissolve, animations: {
                self.tableView.reloadData()
                }, completion: nil)
            
            if totalResults == 0 {
                showPlaceholderView(PlaceholderView(viewController: self, title: "Нет документов",
                    subtitle: "Здесь появятся документы,\nотмеченные как избранные", buttonText: "Начать поиск") {
                        self.showSearchController()
                    })
                removePreloaderView()
            } else {
                showUpdateAndEditButtons()
                updatePreloaderView(totalResults)
            }
        } else {
            let totalBooks = books.count
            var newPaths = [NSIndexPath]()
            
            for i in 0..<receivedBooks.count {
                books.append(receivedBooks[i])
                newPaths.append(NSIndexPath(forRow: totalBooks + i, inSection: 0))
            }
            
            tableView.insertRowsAtIndexPaths(newPaths, withRowAnimation: .Automatic)
            preloaderView?.preloaderViewDataSourceDidFinishedLoading()
            updatePreloaderView(totalResults)
        }
        
        self.totalResults = totalResults
        sectionTitleLabel1.text = textForSectionHeader(totalResults)
        
        for receivedBook in Array(receivedBooks.reverse()) {
            if !Database.instance.isBook(receivedBook, addedToList: "favorites") {
                print("Добавляем " + receivedBook.name)
                Database.instance.addBook(receivedBook, toList: "favorites")
            }
        }
    }
    
    // MARK: - Внутренние методы
    
    /**
        Изменяет состояние наличия в избранном книги во всех принадлежащих ей ячейках

        - parameter isMarkedAsFavorite: Флаг наличия книги в избранном
        - parameter bookId: Идентификатор книги
    */
    private func changeFavoriteState(isMarkedAsFavorite: Bool, bookId: Int) {
        let controllers = [ControllerManager.instance.searchTableViewController,
            ControllerManager.instance.downloadsTableViewController, ControllerManager.instance.favoritesTableViewController]
        
        for controller in controllers {
            if let indexPaths = controller.tableView.indexPathsForVisibleRows {
                for indexPath in indexPaths {
                    if let cell = controller.tableView.cellForRowAtIndexPath(indexPath) as? CustomTableViewCell {
                        if cell.tag == bookId {
                            cell.starImage.tintColor = isMarkedAsFavorite ?
                                UIColor(red: 1, green: 70 / 255.0, blue: 70 / 255.0, alpha: 1) :
                                UIColor(white: 0.8, alpha: 1)
                        }
                    }
                }
            }
        }
    }
    
    /**
        Скрывает вид-заполнитель
    */
    private func hidePlaceholderView() {
        tableView.bounces = true
        placeholderView?.removeFromSuperview()
    }
    
    /**
        Возвращает текст для вида-подгрузчика с количеством следующих и оставшихся результатов

        - parameter nextResults: Количество следующих результатов
        - parameter remainingResults: Количество оставшихся результатов

        - returns: Текст для вида-подгрузчика
    */
    private func textForPreloaderView(nextResults: Int, remainingResults: Int) -> String {
        let pluralForms = ["Потяните вверх, чтобы увидеть\nследующий %d документ из %d",
            "Потяните вверх, чтобы увидеть\nследующие %d документа из %d",
            "Потяните вверх, чтобы увидеть\nследующие %d документов из %d"]
        let keys = [2, 0, 1, 1, 1, 2, 2, 2, 2, 2]
        let ending = nextResults % 100 > 4 && nextResults % 100 < 20 ? 2 : keys[nextResults % 10]
        
        return String(format: pluralForms[ending], nextResults, remainingResults)
    }
    
    /**
        Возвращает текст для заголовка секции

        - parameter totalResults: Общее количество результатов

        - returns: Текст для заголовка секции
    */
    private func textForSectionHeader(totalResults: Int) -> String {
        let pluralForms = ["%d ИЗБРАННЫЙ ДОКУМЕНТ", "%d ИЗБРАННЫХ ДОКУМЕНТА", "%d ИЗБРАННЫХ ДОКУМЕНТОВ"]
        let keys = [2, 0, 1, 1, 1, 2, 2, 2, 2, 2]
        let ending = totalResults % 100 > 4 && totalResults % 100 < 20 ? 2 : keys[totalResults % 10]
        
        return totalResults == 0 ? "" : String(format: pluralForms[ending], totalResults)
    }
    
    /**
        Удаляет вид-продгрузчик
    */
    private func removePreloaderView() {
        preloaderView = nil
        tableView.tableFooterView = UIView()
    }
    
    /**
        Показывает контроллер поиска
    */
    private func showSearchController() {
        ControllerManager.instance.slideMenuController.changeMainViewController(
            ControllerManager.instance.menuTableViewController.searchTableViewNavigationController, close: true)
        ControllerManager.instance.menuTableViewController.highlightRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0))
    }
    
    /**
        Обновляет вид-подгрузчик

        - parameter totalResults: Общее количество результатов
    */
    private func updatePreloaderView(totalResults: Int) {
        let remainingResults = totalResults - offset - 20
        let nextResults = remainingResults >= 20 ? 20 : remainingResults
        
        if remainingResults <= 0 {
            removePreloaderView()
        } else {
            let text = textForPreloaderView(nextResults, remainingResults: remainingResults)
            
            if preloaderView != nil {
                preloaderView!.label.text = text
            } else {
                preloaderView = PreloaderView(text: text, delegate: self)
                tableView.tableFooterView = preloaderView
            }
        }
    }
    
    /**
        Обновляет заголовок секции
    */
    private func updateSectionTitle() {
        let totalBooks = books.count
        let keys = [2, 0, 1, 1, 1, 2, 2, 2, 2, 2]
        let words = ["ИЗБРАННЫЙ ДОКУМЕНТ", "ИЗБРАННЫХ ДОКУМЕНТА", "ИЗБРАННЫХ ДОКУМЕНТОВ"]
        let word = words[totalBooks % 100 > 4 && totalBooks % 100 < 20 ? 2 : keys[totalBooks % 10]]
        
        sectionTitleLabel1?.text = totalBooks == 0 ? "" : "\(totalBooks) \(word)"
    }
    
    // MARK: - Методы UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return CustomTableViewCell(book: books[indexPath.row], query: nil)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return books.count
    }
    
    // MARK: - Методы UITableViewDelegate
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return CustomTableViewCell.heightForRowWithBook(books[indexPath.row])
    }
    
    // MARK: - Методы UIActionSheetDelegate
    
    override func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        super.actionSheet(actionSheet, clickedButtonAtIndex: buttonIndex)
        
        if actionSheet.tag == 0 && buttonIndex == 0 {
            if let selectedIndexPaths = tableView.indexPathsForSelectedRows {
                MisisBooksApi.instance.deleteBooksFromFavorites(selectedIndexPaths.map { self.books[$0.row] })
            } else {
                MisisBooksApi.instance.deleteAllBooksFromFavorites()
            }
        }
    }
    
    // MARK: - Методы UIScrollViewDelegate
    
    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        preloaderView?.preloaderViewScrollViewDidEndDragging(scrollView)
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        preloaderView?.preloaderViewScrollViewDidScroll(scrollView)
    }
    
    // MARK: - Методы PreloaderViewDelegate
    
    func preloaderViewDataSourceIsLoading() -> Bool! {
        return loadingMore
    }
    
    func preloaderViewDidTriggerRefresh() {
        loadingMore = true
        offset += count
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            self.action = .GetFavorites
            MisisBooksApi.instance.getFavorites(count: self.count, offset: self.offset)
        }
    }
}
