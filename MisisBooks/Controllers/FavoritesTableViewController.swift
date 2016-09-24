//
//  FavoritesTableViewController.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 06.12.14.
//  Copyright (c) 2016 Maxim Loskov. All rights reserved.
//

import UIKit

class FavoritesTableViewController: BookTableViewController, PreloaderViewDelegate {

    var action: ApiAction!
    var activityIndicator: UIActivityIndicatorView!
    var isReady = false
    var placeholderView: PlaceholderView?
    private var count = 20
    private var loadingMore = false
    private var offset = 0
    private var preloaderView: PreloaderView?
    private var totalResults = 0

    override func viewDidAppear(_ animated: Bool) {
        updateSectionTitle()
        isReady = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.allowsMultipleSelectionDuringEditing = true
        title = "Избранное"

        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityIndicator.center = CGPoint(x: view.bounds.size.width / 2, y: 18)
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)

        action = .getFavorites
        Api.instance.getFavorites(byCount: count, offset: offset)
    }

    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            placeholderView?.setNeedsLayout()
        }

        activityIndicator.center = CGPoint(x: view.bounds.size.width / 2, y: 18)
    }

    func addBook(_ book: Book) {
        for bookInSearch in ControllerManager.instance.searchTableViewController.books {
            if bookInSearch.id == book.id {
                bookInSearch.isMarkedAsFavorite = true
            }
        }

        books.insert(book, at: 0)

        if isReady {
            tableView?.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        }

        changeFavoriteState(to: true, bookId: book.id)
        Database.instance.addBook(book, toList: "favorites")
        totalResults += 1
        sectionTitleLabel1.text = textForSectionHeaderWithTotalResults(totalResults)
        showUpdateAndEditButtons()
        hidePlaceholderView()
    }

    func deleteAllBooks() {
        for book in books {
            for bookInSearch in ControllerManager.instance.searchTableViewController.books {
                if bookInSearch.id == book.id {
                    bookInSearch.isMarkedAsFavorite = false
                }
            }

            changeFavoriteState(to: false, bookId: book.id)
        }

        books.removeAll(keepingCapacity: false)
        tableView.reloadSections(IndexSet(integer: 0), with: .fade)
        Database.instance.deleteAllBooks(fromList: "favorites")
        totalResults = 0
        offset = 0
        sectionTitleLabel1.text = textForSectionHeaderWithTotalResults(totalResults)
        removePreloaderView()
        showPlaceholderView(
            PlaceholderView(
                viewController: self,
                title: "Нет документов",
                subtitle: "Здесь появятся документы,\nотмеченные как избранные",
                buttonText: "Начать поиск"
            ) {
                self.showSearchController()
            }
        )
    }

    func deleteBooks(_ booksToDelete: [Book]) {
        for bookForDeletion in booksToDelete {
            for bookInSearch in ControllerManager.instance.searchTableViewController.books {
                if bookInSearch.id == bookForDeletion.id {
                    bookInSearch.isMarkedAsFavorite = false
                }

                changeFavoriteState(to: false, bookId: bookForDeletion.id)
            }

            for i in 0..<books.count {
                if books[i].id == bookForDeletion.id {
                    books.remove(at: i)

                    if isReady {
                        tableView.deleteRows(at: [IndexPath(row: i, section: 0)], with:
                            .fade)
                    }

                    break
                }
            }

            Database.instance.deleteBook(bookForDeletion, fromList: "favorites")
        }

        totalResults -= booksToDelete.count
        sectionTitleLabel1.text = textForSectionHeaderWithTotalResults(totalResults)

        if books.count == 0 {
            showPlaceholderView(
                PlaceholderView(
                    viewController: self,
                    title: "Нет документов",
                    subtitle: "Здесь появятся документы,\nотмеченные как избранные",
                    buttonText: "Начать поиск"
                ) {
                    self.showSearchController()
                }
            )
        } else {
            showUpdateAndEditButtons()
        }
    }

    func deleteButtonPressed() {
        let selectedIndexPaths = tableView.indexPathsForSelectedRows
        let actionTitleSubstring: String
        let numberOfBooksToDelete: Int

        if selectedIndexPaths?.count == 1 {
            actionTitleSubstring = "этот документ"
            numberOfBooksToDelete = 1
        } else if (selectedIndexPaths?.count)! > 1 {
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
        actionSheet.actionSheetStyle = .default
        actionSheet.tag = 0
        actionSheet.show(in: view)
    }

    func loadBooksFromDatabase() {
        activityIndicator.stopAnimating()
        books = Array(Database.instance.getBooks(fromList: "favorites").reversed())
        totalResults = books.count
        sectionTitleLabel1.text = textForSectionHeaderWithTotalResults(totalResults)

        if books.count == 0 {
            showPlaceholderView(
                PlaceholderView(
                    viewController: self,
                    title: "Нет документов",
                    subtitle: "Здесь появятся документы,\nотмеченные как избранные",
                    buttonText: "Начать поиск"
                ) {
                    self.showSearchController()
                }
            )
        } else {
            showUpdateAndEditButtons()

        }

        let allDocuments = books.map { String($0.id) }.joined(separator: ", ")
        print("Избранные книги (\(books.count)): [\(allDocuments)]")

        tableView.reloadData()
    }

    func showDeleteAndCancelButtons() {
        setEditing(true, animated: true)
        navigationItem.setRightBarButtonItems(
            [
                UIBarButtonItem(
                    image: UIImage(named: "Cancel"),
                    style: .plain,
                    target: self,
                    action: #selector(showUpdateAndEditButtons)
                ),
                UIBarButtonItem(
                    image: UIImage(named: "Trash"),
                    style: .plain,
                    target: self,
                    action: #selector(deleteButtonPressed)
                )
            ],
            animated: true
        )
    }

    func showPlaceholderView(_ placeholderView: PlaceholderView) {
        showUpdateButton()
        loadingMore = false
        activityIndicator.stopAnimating()
        self.placeholderView?.removeFromSuperview()
        self.placeholderView = placeholderView
        books.removeAll(keepingCapacity: false)
        tableView.reloadData()
        tableView.addSubview(self.placeholderView!)
        tableView.bounces = false
        setEditing(false, animated: true)
    }

    func showUpdateAndEditButtons() {
        setEditing(false, animated: true)
        navigationItem.setRightBarButtonItems(
            [
                UIBarButtonItem(
                    image: UIImage(named: "Edit"),
                    style: .plain,
                    target: self,
                    action: #selector(showDeleteAndCancelButtons)
                ),
                UIBarButtonItem(
                    image: UIImage(named: "Update"),
                    style: .plain,
                    target: self,
                    action: #selector(updateButtonPressed)
                )
            ],
            animated: true
        )
    }

    func showUpdateButton() {
        navigationItem.setRightBarButtonItems(
            [
                UIBarButtonItem(
                    image: UIImage(named: "Update"),
                    style: .plain,
                    target: self,
                    action: #selector(updateButtonPressed)
                )
            ],
            animated: true
        )
    }

    func updateButtonPressed() {
        books.removeAll(keepingCapacity: false)
        sectionTitleLabel1.text = ""
        removePreloaderView()
        activityIndicator.startAnimating()
        placeholderView?.removeFromSuperview()
        placeholderView = nil

        UIView.transition(with: tableView, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.tableView.reloadData()
            }, completion: nil)

        count = 20
        offset = 0
        action = .getFavorites
        Api.instance.getFavorites(byCount: count, offset: offset)
    }

    func updateTable(_ receivedBooks: [Book], totalResults: Int) {
        loadingMore = false
        activityIndicator.stopAnimating()
        placeholderView?.removeFromSuperview()
        placeholderView = nil
        tableView.bounces = true

        if offset == 0 {
            books = receivedBooks

            UIView.transition(with: tableView, duration: 0.2, options: .transitionCrossDissolve, animations: {
                self.tableView.reloadData()
                }, completion: nil)

            if totalResults == 0 {
                showPlaceholderView(
                    PlaceholderView(
                        viewController: self,
                        title: "Нет документов",
                        subtitle: "Здесь появятся документы,\nотмеченные как избранные",
                        buttonText: "Начать поиск"
                    ) {
                        self.showSearchController()
                    }
                )
                removePreloaderView()
            } else {
                showUpdateAndEditButtons()
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

        self.totalResults = totalResults
        sectionTitleLabel1.text = textForSectionHeaderWithTotalResults(totalResults)

        for receivedBook in Array(receivedBooks.reversed()) {
            if !Database.instance.isBook(receivedBook, addedToList: "favorites") {
                print("Добавляем " + receivedBook.name)
                Database.instance.addBook(receivedBook, toList: "favorites")
            }
        }
    }

    private func changeFavoriteState(to isMarkedAsFavorite: Bool, bookId: Int) {
        let controllers = [
            ControllerManager.instance.searchTableViewController,
            ControllerManager.instance.downloadsTableViewController,
            ControllerManager.instance.favoritesTableViewController
        ]

        for controller in controllers {
            if let indexPaths = controller.tableView.indexPathsForVisibleRows {
                for indexPath in indexPaths {
                    if let cell = controller.tableView.cellForRow(at: indexPath) as? CustomTableViewCell {
                        if cell.tag == bookId {
                            cell.starImage.tintColor = isMarkedAsFavorite
                                ? UIColor(red: 1, green: 70 / 255.0, blue: 70 / 255.0, alpha: 1)
                                : UIColor(white: 0.8, alpha: 1)
                        }
                    }
                }
            }
        }
    }

    private func hidePlaceholderView() {
        tableView.bounces = true
        placeholderView?.removeFromSuperview()
    }

    private func textForPreloaderViewWithNextResults(_ nextResults: Int, remainingResults: Int) -> String {
        let pluralForms = [
            "Потяните вверх, чтобы увидеть\nследующий %d документ из %d",
            "Потяните вверх, чтобы увидеть\nследующие %d документа из %d",
            "Потяните вверх, чтобы увидеть\nследующие %d документов из %d"
        ]
        let keys = [2, 0, 1, 1, 1, 2, 2, 2, 2, 2]
        let ending = nextResults % 100 > 4 && nextResults % 100 < 20 ? 2 : keys[nextResults % 10]

        return String(format: pluralForms[ending], nextResults, remainingResults)
    }

    private func textForSectionHeaderWithTotalResults(_ totalResults: Int) -> String {
        let pluralForms = ["%d ИЗБРАННЫЙ ДОКУМЕНТ", "%d ИЗБРАННЫХ ДОКУМЕНТА", "%d ИЗБРАННЫХ ДОКУМЕНТОВ"]
        let keys = [2, 0, 1, 1, 1, 2, 2, 2, 2, 2]
        let ending = totalResults % 100 > 4 && totalResults % 100 < 20 ? 2 : keys[totalResults % 10]

        return totalResults == 0 ? "" : String(format: pluralForms[ending], totalResults)
    }

    private func removePreloaderView() {
        preloaderView = nil
        tableView.tableFooterView = UIView()
    }

    private func showSearchController() {
        ControllerManager.instance.slideMenuController.changeMainViewController(
            to: ControllerManager.instance.menuTableViewController.searchTableViewNavigationController,
            close: true
        )
        ControllerManager.instance.menuTableViewController.highlightRowAtIndexPath(IndexPath(row: 0, section: 0))
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

    private func updateSectionTitle() {
        let totalBooks = books.count
        let keys = [2, 0, 1, 1, 1, 2, 2, 2, 2, 2]
        let words = ["ИЗБРАННЫЙ ДОКУМЕНТ", "ИЗБРАННЫХ ДОКУМЕНТА", "ИЗБРАННЫХ ДОКУМЕНТОВ"]
        let word = words[totalBooks % 100 > 4 && totalBooks % 100 < 20 ? 2 : keys[totalBooks % 10]]

        sectionTitleLabel1?.text = totalBooks == 0 ? "" : "\(totalBooks) \(word)"
    }

    // MARK: - Методы UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return CustomTableViewCell(book: books[indexPath.row], query: nil)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return books.count
    }

    // MARK: - Методы UITableViewDelegate

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CustomTableViewCell.getHeightForRow(withBook: books[indexPath.row])
    }

    // MARK: - Методы UIActionSheetDelegate

    override func actionSheet(_ actionSheet: UIActionSheet, clickedButtonAt buttonIndex: Int) {
        super.actionSheet(actionSheet, clickedButtonAt: buttonIndex)

        if actionSheet.tag == 0 && buttonIndex == 0 {
            if let selectedIndexPaths = tableView.indexPathsForSelectedRows {
                Api.instance.deleteBooksFromFavorites(selectedIndexPaths.map { self.books[$0.row] })
            } else {
                Api.instance.deleteAllBooksFromFavorites()
            }
        }
    }
    
    // MARK: - Методы UIScrollViewDelegate
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        preloaderView?.preloaderViewScrollViewDidEndDragging(scrollView)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        preloaderView?.preloaderViewScrollViewDidScroll(scrollView)
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
                self.action = .getFavorites
                Api.instance.getFavorites(byCount: self.count, offset: self.offset)
        }
    }
    
}
