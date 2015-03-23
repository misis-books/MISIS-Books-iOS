//
//  FavoritesTableViewController.swift
//  misisbooks
//
//  Created by Maxim Loskov on 06.12.14.
//  Copyright (c) 2014 Maxim Loskov. All rights reserved.
//

import UIKit

class FavoritesTableViewController: UITableViewController, UIActionSheetDelegate {
    
    /// Избранные книги
    var books = [Book]()
    
    /// Информационный вид
    var informationView : InformationView?
    
    /// Поле заголовка секции
    var sectionTitleLabel : UILabel!
    
    
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
        if books.count == 0 { // Если избранных книг нет
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
        self.tableView.allowsMultipleSelectionDuringEditing = true
        self.tableView.backgroundColor = UIColor(red: 241 / 255.0, green: 239 / 255.0, blue: 237 / 255.0, alpha: 1.0)
        self.tableView.separatorColor = UIColor(red: 178 / 255.0, green: 178 / 255.0, blue: 178 / 255.0, alpha: 1.0)
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        self.title = "Избранное"
        
        books = Database.instance.booksForList("Favorites")
        
        println("Количество избранных книг: \(books.count)")
        
        if books.count == 0 {
            showInformationView()
        }
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
            // Удаление избранной книги из базы данных
            Database.instance.deleteBookWithId(books[indexPath.row].bookId!, fromList: "Favorites")
            
            // Удаление книги из массива
            books.removeAtIndex(indexPath.row)
            
            // Удаление избранной книги из таблицы
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
            
            // Обновление заголовка секции
            updateSectionTitle()
            
            if books.count == 0 { // Если избранных книг нет
                // Отображение информационного вида
                showInformationView()
            }
        }
    }
    
    /// MARK: - Методы UITableViewDelegate
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return CustomTableViewCell.heightForRowWithBook(books[indexPath.row])
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        /* let detailTableViewController = DetailTableViewController(book: books[indexPath.row])
        self.navigationController?.pushViewController(detailTableViewController, animated: true) */
        
        // TODO: Сделать выподающее меню, используя ActionSheet
    }
    
    /// MARK: - Методы UIActionSheetDelegate
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 0 {
            if var selectedIndexPaths = self.tableView.indexPathsForSelectedRows() { // Если выбраны какие-то ячейки
                // Сортировка индексов ячеек в порядке убывания. В массиве selectedIndexPaths индексы ячеек расположены в порядке их выделения пользователем, поэтому нельзя допустить, чтобы на этапе удаления книги из массива было обращение по несуществующему индексу, потому что размер массива с каждой итерацией уменьшается
                sort(&selectedIndexPaths, { $0.row > $1.row })
                
                // Удаление выбранных книг
                for var i = 0; i < selectedIndexPaths.count; ++i {
                    // Удаление книги из базы данных
                    Database.instance.deleteBookWithId(books[selectedIndexPaths[i].row].bookId!, fromList: "Favorites")
                    
                    // Удаление книги из массива
                    books.removeAtIndex(selectedIndexPaths[i].row)
                }
                
                // Удаление выбранных книг из таблицы
                self.tableView.deleteRowsAtIndexPaths(selectedIndexPaths, withRowAnimation: UITableViewRowAnimation.Fade)
            } else {
                // Удаление всех книг
                for var i = 0; i < books.count; ++i {
                    // Удаление книги из базы данных
                    Database.instance.deleteBookWithId(books[i].bookId!, fromList: "Favorites")
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
    
    /// Показывает кнопку для редактирования таблицы
    func showEditButton() {
        // Отключение режима редактирования таблицы
        self.tableView.setEditing(false, animated: true)
        
        // Создание и добавление кнопки для редактирования таблицы
        self.navigationItem.setRightBarButtonItems([UIBarButtonItem(image: UIImage(named: "Edit"), style: UIBarButtonItemStyle.Plain, target: self, action: Selector("showDeleteAndCancelButtons"))], animated: true)
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
            actionTitle = "Вы действительно хотите удалить из избранного этот документ?"
        } else if selectedIndexPaths?.count > 1 {
            actionTitle = "Вы действительно хотите удалить из избранного эти документы?"
        } else {
            actionTitle = "Вы действительно хотите удалить из избранного все документы?"
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
        informationView = InformationView(viewController: self, title: "Нет документов", subtitle: "Здесь появятся документы,\nотмеченные как избранные", linkButtonText: "Начать поиск") {
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
    
    /// Добавляет избранную книгу в таблицу и базу данных
    ///
    /// :param: book Книга
    func addBookToFavorites(book: Book) {
        // Скрытие информационного вида
        hideInformationView()
        
        // Добавление избранной книги в базу данных
        Database.instance.addBook(book, toList: "Favorites")
        
        // Добавление избранной книги в массив
        books.append(book)
        
        // Обновление данных таблицы
        let indexPathOfNewItem = NSIndexPath(forRow: books.count - 1, inSection: 0)
        self.tableView.beginUpdates()
        self.tableView.insertRowsAtIndexPaths([indexPathOfNewItem], withRowAnimation: UITableViewRowAnimation.Automatic)
        self.tableView.endUpdates()
        // self.tableView.scrollToRowAtIndexPath(indexPathOfNewItem, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
        
        // Обновление заголовка секции
        updateSectionTitle()
    }
    
    /// Удаляет избранную книгу из таблицы и базы данных
    ///
    /// :param: bookId Идентификатор книги
    func deleteBookFromFavorites(bookId: Int) {
        Database.instance.deleteBookWithId(bookId, fromList: "Favorites") // удаление избранной книги из базы данных
        
        for var i = 0; i < books.count; ++i {
            if books[i].bookId == bookId { // Если идентификатор книги совпал с требуемым
                // Удаление избранной книги из массива
                books.removeAtIndex(i)
                
                // Обновление данных таблицы
                self.tableView.beginUpdates()
                self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: i, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Fade)
                self.tableView.endUpdates()
                
                // Обновление заголовка секции
                updateSectionTitle()
                
                // TODO: Можно не перезагружать всю таблицу, а удалить ячейку
                
                // Если избранных книг нет
                if books.count == 0 {
                    // Отображение вида для пустого списка
                    showInformationView()
                }
                
                break
            }
        }
    }
}
