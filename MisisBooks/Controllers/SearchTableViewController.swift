//
//  SearchTableViewController.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 06.12.14.
//  Copyright (c) 2016 Maxim Loskov. All rights reserved.
//

import UIKit

class SearchTableViewController: BookTableViewController, UISearchBarDelegate, PreloaderViewDelegate {

    var action: ApiAction!
    var activityIndicator: UIActivityIndicatorView!
    private var categoryId = 1
    private var count = 20
    private var filterButton: UIBarButtonItem!
    private var lastInput = ""
    private var loadingMore = false
    private var offset = 0
    var placeholderView: PlaceholderView?
    private var preloaderView: PreloaderView?
    private var searchBar: UISearchBar!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Filter"), style: .plain, target:
            self, action: #selector(filterButtonPressed))

        searchBar = UISearchBar()
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no
        searchBar.autoresizingMask = .flexibleWidth
        searchBar.delegate = self
        searchBar.placeholder = "Поиск"
        searchBar.searchBarStyle = .minimal
        searchBar.tintColor = .darkGray
        navigationItem.titleView = searchBar

        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityIndicator.center = CGPoint(x: view.bounds.size.width / 2, y: 18)
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)

        action = .getPopular
        Api.instance.getPopularBooks(byCategoryId: categoryId, count: count)

        Timer.scheduledTimer(timeInterval: 0.8, target: self, selector: #selector(checkInput), userInfo: nil,
                             repeats: true)
    }

    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation,
                                      duration: TimeInterval) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            placeholderView?.setNeedsLayout()
        }

        activityIndicator.center = CGPoint(x: view.bounds.size.width / 2, y: 18)
    }

    func changeCategory(_ selectedCategoryId: Int) {
        print("Изменена категория: \(selectedCategoryId)")

        books.removeAll(keepingCapacity: false)
        sectionTitleLabel1.text = ""
        removePreloaderView()
        activityIndicator.startAnimating()
        categoryId = selectedCategoryId
        tableView.reloadData()

        if searchBar.text == "" {
            action = .getPopular
            Api.instance.getPopularBooks(byCategoryId: categoryId, count: count)
        } else {
            offset = 0
            action = .search
            Api.instance.searchBooks(byQuery: lastInput, count: count, offset: offset, categoryId: categoryId)
        }
    }

    func checkInput() {
        if lastInput != searchBar.text {
            lastInput = searchBar.text!
            books.removeAll(keepingCapacity: false)
            sectionTitleLabel1.text = ""
            removePreloaderView()
            activityIndicator.startAnimating()

            UIView.transition(with: tableView, duration: 0.2, options: .transitionCrossDissolve, animations: {
                self.tableView.reloadData()
                }, completion: nil)

            if searchBar.text == "" {
                action = .getPopular
                Api.instance.getPopularBooks(byCategoryId: categoryId, count: count)
            } else {
                offset = 0
                action = .search
                Api.instance.searchBooks(byQuery: lastInput, count: count, offset: offset, categoryId:
                    categoryId)
            }
        }
    }

    func filterButtonPressed() {
        let filterTableViewController = FilterTableViewController()
        filterTableViewController.selectedCategoryId = categoryId

        let filterTableViewNavigationController = UINavigationController(rootViewController: filterTableViewController)
        filterTableViewNavigationController.modalTransitionStyle = .coverVertical

        present(filterTableViewNavigationController, animated: true, completion: nil)
    }

    func showPlaceholderView(_ placeholderView: PlaceholderView) {
        loadingMore = false
        searchBar?.resignFirstResponder()
        activityIndicator?.stopAnimating()
        self.placeholderView?.removeFromSuperview()
        self.placeholderView = placeholderView
        sectionTitleLabel1?.text = ""
        books.removeAll(keepingCapacity: false)
        removePreloaderView()
        tableView.reloadData()
        tableView.addSubview(self.placeholderView!)
        tableView.bounces = false
    }

    func updateTable(withReceivedBooks receivedBooks: [Book], totalResults: Int) {
        loadingMore = false
        activityIndicator.stopAnimating()
        placeholderView?.removeFromSuperview()
        placeholderView = nil
        tableView.bounces = true

        if offset == 0 || action == ApiAction.getPopular {
            books = receivedBooks

            UIView.transition(with: tableView, duration: 0.2, options: .transitionCrossDissolve, animations: {
                self.tableView.reloadData()
                }, completion: nil)

            if action == .getPopular {
                sectionTitleLabel1.text = "ПОПУЛЯРНОЕ"
                removePreloaderView()
            } else if action == .search {
                sectionTitleLabel1.text = textForSectionHeaderWithTotalResults(totalResults)
                updatePreloaderViewWithTotalResults(totalResults)
            }
        } else {
            let totalBooks = books.count
            var newPaths = [IndexPath]()

            for i in 0..<receivedBooks.count {
                books.append(receivedBooks[i])
                newPaths.append(IndexPath(row: totalBooks + i, section: 0))
            }

            tableView.insertRows(at: newPaths, with: .automatic)
            preloaderView?.preloaderViewDataSourceDidFinishedLoading()
            updatePreloaderViewWithTotalResults(totalResults)
        }

    }

    private func removePreloaderView() {
        preloaderView = nil
        tableView.tableFooterView = UIView()
    }

    private func textForPreloaderViewWithNextResults(_ nextResults: Int, remainingResults: Int) -> String {
        let pluralForms = [
            "Потяните вверх, чтобы увидеть\nследующий %d результат из %d",
            "Потяните вверх, чтобы увидеть\nследующие %d результата из %d",
            "Потяните вверх, чтобы увидеть\nследующие %d результатов из %d"
        ]
        let keys = [2, 0, 1, 1, 1, 2, 2, 2, 2, 2]
        let ending = nextResults % 100 > 4 && nextResults % 100 < 20 ? 2 : keys[nextResults % 10]

        return String(format: pluralForms[ending], nextResults, remainingResults)
    }

    private func textForSectionHeaderWithTotalResults(_ totalResults: Int) -> String {
        let pluralForms = ["НАЙДЕН %d ДОКУМЕНТ", "НАЙДЕНО %d ДОКУМЕНТА", "НАЙДЕНО %d ДОКУМЕНТОВ"]
        let keys = [2, 0, 1, 1, 1, 2, 2, 2, 2, 2]
        let ending = totalResults % 100 > 4 && totalResults % 100 < 20 ? 2 : keys[totalResults % 10]

        return totalResults == 0 ? "ПОИСК НЕ ДАЛ РЕЗУЛЬТАТОВ" : String(format: pluralForms[ending], totalResults)
    }

    private func updatePreloaderViewWithTotalResults(_ totalResults: Int) {
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

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return CustomTableViewCell(book: books[indexPath.row], query: lastInput)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return books.count
    }

    // MARK: - Методы UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)

        searchBar.resignFirstResponder()
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CustomTableViewCell.getHeightForRow(withBook: books[indexPath.row])
    }

    // MARK: - Методы UIScrollViewDelegate

    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        preloaderView?.preloaderViewScrollViewDidEndDragging(scrollView)
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        preloaderView?.preloaderViewScrollViewDidScroll(scrollView)
    }

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchBar.resignFirstResponder()
    }

    // MARK: - Методы UISearchBarDelegate

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        filterButton = navigationItem.rightBarButtonItem
        navigationItem.setRightBarButton(UIBarButtonItem(image: UIImage(named: "Cancel"), style: .plain, target:
            self, action: #selector(searchCancelButtonClicked)), animated: true)
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        navigationItem.setRightBarButton(filterButton, animated: true)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
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
        
        DispatchQueue.main.asyncAfter(deadline: .now()
            + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                self.action = .search
                Api.instance.searchBooks(
                    byQuery: self.lastInput,
                    count: self.count,
                    offset: self.offset,
                    categoryId: self.categoryId
                )
        }
    }
    
}
