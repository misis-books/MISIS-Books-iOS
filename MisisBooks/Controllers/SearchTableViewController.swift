//
//  SearchTableViewController.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 06.12.14.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit

/**
    Класс для представления контроллера поиска
*/
class SearchTableViewController: BookTableViewController, UISearchBarDelegate, PreloaderViewDelegate {

    /// Действие
    var action: MisisBooksApiAction!

    /// Индикатор активности
    var activityIndicator: UIActivityIndicatorView!

    /// Идентификатор категории
    private var categoryId = 1

    /// Количество результатов
    private var count = 20

    /// Кнопка фильтра
    private var filterButton: UIBarButtonItem!

    /// Последний введенный запрос
    private var lastInput = ""

    /// Флаг состояния подгрузки
    private var loadingMore = false

    /// Смещение выборки результатов
    private var offset = 0

    /// Вид-заполнитель
    var placeholderView: PlaceholderView?

    /// Вид-подгрузчик
    private var preloaderView: PreloaderView?

    /// Строка поиска
    private var searchBar: UISearchBar!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Filter"), style: .Plain, target:
            self, action: "filterButtonPressed")

        searchBar = UISearchBar()
        searchBar.autocapitalizationType = .None
        searchBar.autocorrectionType = .No
        searchBar.autoresizingMask = .FlexibleWidth
        searchBar.delegate = self
        searchBar.placeholder = "Поиск"
        searchBar.searchBarStyle = .Minimal
        searchBar.tintColor = .darkGrayColor()
        navigationItem.titleView = searchBar

        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        activityIndicator.center = CGPointMake(view.bounds.size.width / 2, 18)
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)

        action = .GetPopular
        MisisBooksApi.instance.getPopularBooksByCount(count, categoryId: categoryId)

        NSTimer.scheduledTimerWithTimeInterval(0.8, target: self, selector: "checkInput", userInfo: nil, repeats: true)
    }

    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation,
        duration: NSTimeInterval) {
            if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                placeholderView?.setNeedsLayout()
            }

            activityIndicator.center = CGPointMake(view.bounds.size.width / 2, 18)
    }

    /**
        Изменяет категорию на выбранную

        - parameter selectedCategoryId: Идентификатор выбранной категории
    */
    func changeCategory(selectedCategoryId: Int) {
        print("Изменена категория: \(selectedCategoryId)")

        books.removeAll(keepCapacity: false)
        sectionTitleLabel1.text = ""
        removePreloaderView()
        activityIndicator.startAnimating()
        categoryId = selectedCategoryId
        tableView.reloadData()

        if searchBar.text == "" {
            action = .GetPopular
            MisisBooksApi.instance.getPopularBooksByCount(count, categoryId: categoryId)
        } else {
            offset = 0
            action = .Search
            MisisBooksApi.instance.searchBooksByQuery(lastInput, count: count, offset: offset, categoryId: categoryId)
        }
    }

    /**
        Проверяет, изменился ли текст в поисковой строке. Запускает запросы к серверу
    */
    func checkInput() {
        if lastInput != searchBar.text {
            lastInput = searchBar.text!
            books.removeAll(keepCapacity: false)
            sectionTitleLabel1.text = ""
            removePreloaderView()
            activityIndicator.startAnimating()

            UIView.transitionWithView(self.tableView, duration: 0.2, options: .TransitionCrossDissolve, animations: {
                self.tableView.reloadData()
                }, completion: nil)

            if searchBar.text == "" {
                action = .GetPopular
                MisisBooksApi.instance.getPopularBooksByCount(count, categoryId: categoryId)
            } else {
                offset = 0
                action = .Search
                MisisBooksApi.instance.searchBooksByQuery(lastInput, count: count, offset: offset, categoryId:
                    categoryId)
            }
        }
    }

    /**
        Обрабатывает событие, когда нажата кнопка фильтра
    */
    func filterButtonPressed() {
        let filterTableViewController = FilterTableViewController()
        filterTableViewController.selectedCategoryId = categoryId

        let filterTableViewNavigationController = UINavigationController(rootViewController: filterTableViewController)
        filterTableViewNavigationController.modalTransitionStyle = .CoverVertical

        presentViewController(filterTableViewNavigationController, animated: true, completion: nil)
    }

    /**
        Показывает вид-подгрузчик

        - parameter placeholderView: Вид-подгрузчик
    */
    func showPlaceholderView(placeholderView: PlaceholderView) {
        loadingMore = false
        searchBar?.resignFirstResponder()
        activityIndicator?.stopAnimating()
        self.placeholderView?.removeFromSuperview()
        self.placeholderView = placeholderView
        sectionTitleLabel1?.text = ""
        books.removeAll(keepCapacity: false)
        removePreloaderView()
        tableView.reloadData()
        tableView.addSubview(self.placeholderView!)
        tableView.bounces = false
    }

    /**
        Обновляет таблицу

        - parameter receivedBooks: Полученные книги
        - parameter totalResults: Общее количество результатов
    */
    func updateTableWithReceivedBooks(receivedBooks: [Book], totalResults: Int) {
        loadingMore = false
        activityIndicator.stopAnimating()
        placeholderView?.removeFromSuperview()
        placeholderView = nil
        tableView.bounces = true

        if offset == 0 || action == MisisBooksApiAction.GetPopular {
            books = receivedBooks

            UIView.transitionWithView(self.tableView, duration: 0.2, options: .TransitionCrossDissolve, animations: {
                self.tableView.reloadData()
                }, completion: nil)

            if action == .GetPopular {
                sectionTitleLabel1.text = "ПОПУЛЯРНОЕ"
                removePreloaderView()
            } else if action == .Search {
                sectionTitleLabel1.text = textForSectionHeaderWithTotalResults(totalResults)
                updatePreloaderViewWithTotalResults(totalResults)
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
            updatePreloaderViewWithTotalResults(totalResults)
        }

    }

    // MARK: - Внутренние методы

    /**
        Удаляет вид-подгрузчик
    */
    private func removePreloaderView() {
        preloaderView = nil
        tableView.tableFooterView = UIView()
    }

    /**
        Возвращает текст для поля вида-подгрузчика

        - parameter nextResults: Количество следующих результатов
        - parameter remainingResults: Количество оставшихся результатов

        - returns: Текст для поля вида-подгрузчика
    */
    private func textForPreloaderViewWithNextResults(nextResults: Int, remainingResults: Int) -> String {
        let pluralForms = ["Потяните вверх, чтобы увидеть\nследующий %d результат из %d",
            "Потяните вверх, чтобы увидеть\nследующие %d результата из %d",
            "Потяните вверх, чтобы увидеть\nследующие %d результатов из %d"]
        let keys = [2, 0, 1, 1, 1, 2, 2, 2, 2, 2]
        let ending = nextResults % 100 > 4 && nextResults % 100 < 20 ? 2 : keys[nextResults % 10]

        return String(format: pluralForms[ending], nextResults, remainingResults)
    }

    /**
        Возвращает текст для заголовка секции

        - parameter totalResults: Общее количество результатов

        - returns: Текст для заголовка секции
    */
    private func textForSectionHeaderWithTotalResults(totalResults: Int) -> String {
        let pluralForms = ["НАЙДЕН %d ДОКУМЕНТ", "НАЙДЕНО %d ДОКУМЕНТА", "НАЙДЕНО %d ДОКУМЕНТОВ"]
        let keys = [2, 0, 1, 1, 1, 2, 2, 2, 2, 2]
        let ending = totalResults % 100 > 4 && totalResults % 100 < 20 ? 2 : keys[totalResults % 10]

        return totalResults == 0 ? "ПОИСК НЕ ДАЛ РЕЗУЛЬТАТОВ" : String(format: pluralForms[ending], totalResults)
    }

    /**
        Обновляет вид-подгрузчик

        - parameter totalResults: Общее количество результатов
    */
    private func updatePreloaderViewWithTotalResults(totalResults: Int) {
        let remainingResults = totalResults - offset - 20
        let nextResults = remainingResults >= 20 ? 20 : remainingResults

        if remainingResults <= 0 {
            removePreloaderView()
        } else {
            let text = textForPreloaderViewWithNextResults(nextResults, remainingResults: remainingResults)

            if preloaderView != nil {
                preloaderView!.label.text = text
            } else {
                preloaderView = PreloaderView(text: text, delegate: self)
                tableView.tableFooterView = preloaderView
            }
        }
    }

    // MARK: - Методы UITableViewDataSource

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return CustomTableViewCell(book: books[indexPath.row], query: lastInput)
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return books.count
    }

    // MARK: - Методы UITableViewDelegate

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        super.tableView(tableView, didSelectRowAtIndexPath: indexPath)

        searchBar.resignFirstResponder()
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return CustomTableViewCell.heightForRowWithBook(books[indexPath.row])
    }

    // MARK: - Методы UIScrollViewDelegate

    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        preloaderView?.preloaderViewScrollViewDidEndDragging(scrollView)
    }

    override func scrollViewDidScroll(scrollView: UIScrollView) {
        preloaderView?.preloaderViewScrollViewDidScroll(scrollView)
    }

    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        searchBar.resignFirstResponder()
    }

    // MARK: - Методы UISearchBarDelegate

    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        filterButton = navigationItem.rightBarButtonItem
        navigationItem.setRightBarButtonItem(UIBarButtonItem(image: UIImage(named: "Cancel"), style: .Plain, target:
            self, action: "searchCancelButtonClicked"), animated: true)
    }

    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        navigationItem.setRightBarButtonItem(filterButton, animated: true)
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchCancelButtonClicked() {
        searchBar.resignFirstResponder()
    }

    // MARK: - Методы PreloaderViewDelegate

    func preloaderViewDataSourceIsLoading() -> Bool! {
        return loadingMore
    }

    func preloaderViewDidTriggerRefresh() {
        loadingMore = true
        offset += count

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            self.action = .Search
            MisisBooksApi.instance.searchBooksByQuery(self.lastInput, count: self.count, offset: self.offset,
                categoryId: self.categoryId)
        }
    }
}
