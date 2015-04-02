//
//  SearchTableViewController.swift
//  misisbooks
//
//  Created by Maxim Loskov on 06.12.14.
//  Copyright (c) 2014 Maxim Loskov. All rights reserved.
//

import UIKit

class SearchTableViewController : BookTableViewController, UISearchBarDelegate, UIScrollViewDelegate, PreloaderViewDelegate, FilterTableViewControllerDelegate {
    
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
    
    /// Последний введенный запрос
    var lastInput = ""
    
    /// Количество результатов
    var count = 20
    
    /// Смещение выборки результатов
    var offset = 0
    
    /// Категория
    var category = 1
    
    /// Действие
    var action : MisisBooksApiAction!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let filterBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "Filter"),
            style: .Plain,
            target: self,
            action: Selector("filterButtonPressed")
        )
        navigationItem.setRightBarButtonItem(filterBarButtonItem, animated: false)
        
        searchBar = UISearchBar(frame: CGRectZero)
        searchBar.autocapitalizationType = .None
        searchBar.autocorrectionType = .No
        searchBar.autoresizingMask = .FlexibleWidth
        searchBar.delegate = self
        searchBar.searchBarStyle = .Minimal
        searchBar.placeholder = "Поиск"
        searchBar.tintColor = UIColor.darkGrayColor()
        navigationItem.titleView = searchBar
        
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        activityIndicator.center = CGPointMake(view.frame.size.width / 2, 18.0)
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        
        action = .GetPopular
        MisisBooksApi.sharedInstance.getPopular(count: count, category: category)
        
        NSTimer.scheduledTimerWithTimeInterval(0.8, target: self, selector: Selector("checkInput"), userInfo: nil, repeats: true)
    }
    
    /// MARK: - Вспомогательные методы
    
    /// Проверяет, изменился ли текст в поисковой строке
    func checkInput() {
        if lastInput != searchBar.text {
            lastInput = searchBar.text
            books.removeAll(keepCapacity: false)
            sectionTitleLabel1.text = ""
            removePreloaderView()
            activityIndicator.startAnimating()
            
            UIView.transitionWithView(
                self.tableView,
                duration: 0.2,
                options: .TransitionCrossDissolve,
                animations: {
                    self.tableView.reloadData()
                },
                completion: nil
            )
            
            if searchBar.text == "" {
                action = .GetPopular
                MisisBooksApi.sharedInstance.getPopular(count: count, category: category)
            } else {
                offset = 0
                action = .Search
                MisisBooksApi.sharedInstance.search(query: lastInput, count: count, offset: offset, category: category)
            }
        }
    }
    
    func removePreloaderView() {
        preloaderView = nil
        tableView.tableFooterView = UIView(frame: CGRectZero)
    }
    
    func updatePreloaderView(totalResults: Int) {
        let remainingResults = totalResults - offset - 20
        let nextResults = remainingResults >= 20 ? 20 : remainingResults
        
        if remainingResults <= 0 {
            removePreloaderView()
        } else {
            let textForPreloaderView = getTextForPreloaderView(nextResults, remainingResults: remainingResults)
            
            if preloaderView != nil {
                preloaderView!.label.text = textForPreloaderView
            } else {
                preloaderView = PreloaderView(text: textForPreloaderView, delegate: self)
                tableView.tableFooterView = preloaderView
            }
        }
    }
    
    func getTextForSectionHeader(totalResults: Int) -> String {
        let formats = ["НАЙДЕН %d ДОКУМЕНТ", "НАЙДЕНО %d ДОКУМЕНТА", "НАЙДЕНО %d ДОКУМЕНТОВ"]
        let keys = [2, 0, 1, 1, 1, 2, 2, 2, 2, 2]
        let ending = totalResults % 100 > 4 && totalResults % 100 < 20 ? 2 : keys[totalResults % 10]
        
        return totalResults == 0 ? "ПОИСК НЕ ДАЛ РЕЗУЛЬТАТОВ" : String(format: formats[ending], totalResults)
    }
    
    /// Возвращает текст для подгрузчика результатов
    ///
    /// :param: nextResults Количество следующих результатов
    /// :param: remainingResults Количество оставшихся результатов
    /// :returns: Строка для поля вида подгрузчика результатов
    func getTextForPreloaderView(nextResults: Int, remainingResults: Int) -> String {
        let formats = [
            "Потяните вверх, чтобы увидеть\nследующий %d результат из %d",
            "Потяните вверх, чтобы увидеть\nследующие %d результата из %d",
            "Потяните вверх, чтобы увидеть\nследующие %d результатов из %d"
        ]
        let keys = [2, 0, 1, 1, 1, 2, 2, 2, 2, 2]
        let ending = nextResults % 100 > 4 && nextResults % 100 < 20 ? 2 : keys[nextResults % 10]
        
        return String(format: formats[ending], nextResults, remainingResults)
    }
    
    /// Обрабатывает событие, когда нажата кнопка фильтра
    func filterButtonPressed() {
        let filterTableViewController = FilterTableViewController(selectedCategory: category, delegate: self)
        let viewControllerToPresent = UINavigationController(rootViewController: filterTableViewController)
        viewControllerToPresent.modalTransitionStyle = .CoverVertical
        presentViewController(viewControllerToPresent, animated: true, completion: nil)
    }
    
    /// MARK: - Методы FilterTableViewControllerDelegate
    
    func filterTableViewControllerDidChangeCategory(selectedCategory: Int) {
        println("Изменена категория: \(selectedCategory)")
        
        books.removeAll(keepCapacity: false)
        sectionTitleLabel1.text = ""
        removePreloaderView()
        activityIndicator.startAnimating()
        category = selectedCategory
        tableView.reloadData()
        
        if searchBar.text == "" {
            action = .GetPopular
            MisisBooksApi.sharedInstance.getPopular(count: count, category: category)
        } else {
            offset = 0
            action = .Search
            MisisBooksApi.sharedInstance.search(query: lastInput, count: count, offset: offset, category: category)
        }
    }
    
    /// MARK: - Методы UISearchBarDelegate
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        filterButton = navigationItem.rightBarButtonItem
        
        let cancelBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "Cancel"),
            style: .Plain,
            target: self,
            action: Selector("searchCancelButtonClicked")
        )
        navigationItem.setRightBarButtonItem(cancelBarButtonItem, animated: true)
    }
    
    func searchCancelButtonClicked() {
        searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        navigationItem.setRightBarButtonItem(filterButton, animated: true)
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
    
    /// MARK: - Методы UITableViewDelegate
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return CustomTableViewCell.heightForRowWithBook(books[indexPath.row])
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
        
        searchBar.resignFirstResponder()
    }
    
    /// MARK: - Методы UIScrollViewDelegate
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        preloaderView?.preloaderViewScrollViewDidScroll(scrollView)
    }
    
    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        preloaderView?.preloaderViewScrollViewDidEndDragging(scrollView)
    }
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        searchBar.resignFirstResponder()
    }
        
    /// MARK: - Методы, вызываемые MisisBooksApi
    
    func updateTableWithReceivedBooks(receivedBooks: [Book], totalResults: Int) {
        loadingMore = false
        activityIndicator.stopAnimating()
        informationView?.removeFromSuperview()
        informationView = nil
        tableView.bounces = true
        
        if offset == 0 || action == MisisBooksApiAction.GetPopular {
            books = receivedBooks
            
            UIView.transitionWithView(
                self.tableView,
                duration: 0.2,
                options: .TransitionCrossDissolve,
                animations: {
                    self.tableView.reloadData()
                },
                completion: nil
            )
            
            if action == MisisBooksApiAction.GetPopular {
                sectionTitleLabel1.text = "ПОПУЛЯРНОЕ"
                removePreloaderView()
            } else if action == MisisBooksApiAction.Search {
                sectionTitleLabel1.text = getTextForSectionHeader(totalResults)
                updatePreloaderView(totalResults)
            }
        } else {
            let totalBooks = books.count
            var newPaths = [NSIndexPath]()
            
            for var i = 0; i < receivedBooks.count; ++i {
                books.append(receivedBooks[i])
                newPaths.append(NSIndexPath(forRow: totalBooks + i, inSection: 0))
            }
            
            tableView.insertRowsAtIndexPaths(newPaths, withRowAnimation: .Automatic)
            preloaderView?.preloaderViewDataSourceDidFinishedLoading()
            updatePreloaderView(totalResults)
        }

    }
    
    func showInformationView(informationView: InformationView) {
        loadingMore = false
        searchBar.resignFirstResponder()
        activityIndicator.stopAnimating()
        self.informationView?.removeFromSuperview()
        self.informationView = informationView
        sectionTitleLabel1.text = ""
        books.removeAll(keepCapacity: false)
        removePreloaderView()
        tableView.reloadData()
        tableView.addSubview(informationView)
        tableView.bounces = false
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
            MisisBooksApi.sharedInstance.search(query: self.lastInput, count: self.count, offset: self.offset, category: self.category)
        }
    }
}
