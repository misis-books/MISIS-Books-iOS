//
//  FavoritesTableViewController.swift
//  misisbooks
//
//  Created by Maxim Loskov on 06.12.14.
//  Copyright (c) 2014 Maxim Loskov. All rights reserved.
//

import UIKit

class FavoritesTableViewController : BookTableViewController {
    
    /// Информационный вид
    var informationView : InformationView?
    
    /// Флаг стостояния загрузки вида
    var isViewLoaded = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        books = Database.sharedInstance.booksForList("Favorites")
        
        tableView.allowsMultipleSelectionDuringEditing = true
        title = "Избранное"
        
        if books.count == 0 {
            showInformationView()
        } else {
            showUpdateAndEditButtons()
        }
        
        let allDocuments = join(", ", map(books, { String($0.bookId) }))
        println("Избранные книги (\(books.count)): [\(allDocuments)]")
    }
    
    override func viewDidAppear(animated: Bool) {
        updateSectionTitle()
        isViewLoaded = true
    }
    
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
    
    /// MARK: - Методы UITableViewDelegate
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return CustomTableViewCell.heightForRowWithBook(books[indexPath.row])
    }
    
    /// MARK: - Методы UIActionSheetDelegate
    
    override func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        super.actionSheet(actionSheet, clickedButtonAtIndex: buttonIndex)
        
        if actionSheet.tag == 0 && buttonIndex == 0 { // Таблица редактируется
            if let selectedIndexPaths = tableView.indexPathsForSelectedRows() {
                MisisBooksApi.sharedInstance.deleteBooksFromFavorites(map(selectedIndexPaths, { self.books[$0.row] }))
            } else {
                MisisBooksApi.sharedInstance.deleteAllBooksFromFavorites()
            }
        }
    }
    
    /// MARK: - Вспомогательные методы
    
    /// Обновляет заголовок секции
    func updateSectionTitle() {
        let totalBooks = books.count
        let keys = [2, 0, 1, 1, 1, 2, 2, 2, 2, 2]
        let words = ["ИЗБРАННЫЙ ДОКУМЕНТ", "ИЗБРАННЫХ ДОКУМЕНТА", "ИЗБРАННЫХ ДОКУМЕНТОВ"]
        let word = words[totalBooks % 100 > 4 && totalBooks % 100 < 20 ? 2 : keys[totalBooks % 10]]
        
        sectionTitleLabel1?.text = totalBooks == 0 ? "" : "\(totalBooks) \(word)"
    }
    
    /// Показывает кнопки для обновления и редактирования таблицы
    func showUpdateAndEditButtons() {
        tableView.setEditing(false, animated: true)
        
        let editBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "Edit"),
            style: .Plain,
            target: self,
            action: Selector("showDeleteAndCancelButtons")
        )
        let updateBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "Update"),
            style: .Plain,
            target: self,
            action: Selector("updateButtonPressed")
        )
        navigationItem.setRightBarButtonItems([editBarButtonItem, updateBarButtonItem], animated: true)
    }
    
    /// Показывает кнопку для обновления таблицы
    func showUpdateButton() {
        let updateBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "Update"),
            style: .Plain,
            target: self,
            action: Selector("updateButtonPressed")
        )
        navigationItem.setRightBarButtonItems([updateBarButtonItem], animated: true)
    }
    
    /// Показывает кнопки для удаления документов и отмены редактирования таблицы
    func showDeleteAndCancelButtons() {
        tableView.setEditing(true, animated: true)
        
        let cancelBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "Cancel"),
            style: .Plain,
            target: self,
            action: Selector("showUpdateAndEditButtons")
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
        
        let actionSheet = UIActionSheet(
            title: "Вы действительно хотите удалить из избранного \(actionTitleSubstring)?",
            delegate: self,
            cancelButtonTitle: "Отмена",
            destructiveButtonTitle: "Удалить (\(numberOfBooksToDelete))"
        )
        actionSheet.actionSheetStyle = .Default
        actionSheet.tag = 0
        actionSheet.showInView(view)
    }
    
    /// Обрабатывает событие, когда нажата кнопка обновления
    func updateButtonPressed() {
        MisisBooksApi.sharedInstance.getFavorites()
    }
    
    /// Показывает информационный вид
    func showInformationView() {
        // navigationItem.setRightBarButtonItems(nil, animated: true)
        showUpdateButton()
        tableView.setEditing(false, animated: true)
        tableView.bounces = false
        informationView?.removeFromSuperview()
        informationView = InformationView(
            viewController: self,
            title: "Нет документов",
            subtitle: "Здесь появятся документы,\nотмеченные как избранные",
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
    
    /// Добавляет книгу в избранное
    ///
    /// :param: book Книга
    func addBookToFavorites(book: Book) {
        books.append(book)
        
        if isViewLoaded {
            let newIndexPath = NSIndexPath(forRow: books.count - 1, inSection: 0)
            tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Automatic)
        }
        
        Database.sharedInstance.addBook(book, toList: "Favorites")
        updateSectionTitle()
        showUpdateAndEditButtons()
        hideInformationView()
    }
    
    /// Удаляет книги из избранного
    ///
    /// :param: books Книги для удаления
    func deleteBooksFromFavorites(booksForDeletion: [Book]) {
        for var i = 0; i < booksForDeletion.count; ++i {
            for var j = 0; j < books.count; ++j {
                if books[j].bookId == booksForDeletion[i].bookId {
                    books.removeAtIndex(j)
                    
                    if isViewLoaded {
                        let indexPathForDeletion = NSIndexPath(forRow: j, inSection: 0)
                        tableView.deleteRowsAtIndexPaths([indexPathForDeletion], withRowAnimation: .Fade)
                    }
                    
                    break
                }
            }
            
            Database.sharedInstance.deleteBookWithId(booksForDeletion[i].bookId, fromList: "Favorites")
        }
        
        updateSectionTitle()
        
        if books.count == 0 && isViewLoaded {
            showInformationView()
        } else {
            showUpdateAndEditButtons()
        }
    }
    
    /// Удаляет все книги из избранного
    func deleteAllBooksFromFavorites() {
        books.removeAll(keepCapacity: false)
        tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Fade)
        Database.sharedInstance.deleteAllBooksFromList("Favorites")
        updateSectionTitle()
        showInformationView()
    }
}
