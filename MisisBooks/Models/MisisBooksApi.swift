//
//  MisisBooksApi.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 06.12.14.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import Foundation

/**
    Перечисление для действий с API MISIS Books
*/
enum MisisBooksApiAction {
    case AddBookToFavorites, Search, DeleteAllBooksFromFavorites, DeleteBookFromFavorites, GetCategories, GetFavorites,
    GetPopular, GetPopularForWeek, LogOut, SignIn
}

/**
    Перечисление для ошибок API MISIS Books
*/
enum MisisBooksApiError: ErrorType {
    case NotConnectedToInternet, TimedOut, NotConnected, NoData, StatusCodeNotSupported, MissingMimeType, MimeTypeNotSupported,
    NoSubscription, TooManyRequests, MissingAccessToken, InvalidVkAccessToken, TooManyRequestsToCreationToken, UnknownError,
    InvalidJson

    func description() -> (title: String, detail: String, short: String) {
        switch self {
        case .NotConnectedToInternet:
            return ("Ошибка соединения", "Не удалось установить связь\nс сервером, так как отсутствует\nподключение к Интернету",
                "Отсутствует подключение к Интернету")
        case .TimedOut:
            return ("Ошибка соединения", "Не удалось установить связь\nс сервером, так как истекло\nвремя ожидания ответа",
                "Истекло время ожидания ответа")
        case .NotConnected:
            return ("Ошибка соединения", "Не удалось подключиться к серверу", "Не удалось подключиться к серверу")
        case .NoData:
            return ("Ошибка обработки", "Сервер не вернул данные", "Сервер не вернул данные")
        case .StatusCodeNotSupported:
            return ("Запрос не выполнен", "Код состояния HTTP не поддерживается", "Код состояния HTTP не поддерживается")
        case .MissingMimeType:
            return ("Запрос не выполнен", "Отсутствует MIME-тип", "Отсутствует MIME-тип")
        case .MimeTypeNotSupported:
            return ("Запрос не выполнен", "MIME-тип не поддерживается", "MIME-тип не поддерживается")
        case .NoSubscription:
            return ("Предупреждение", "Вы не оформили подписку", "Вы не оформили подписку")
        case .TooManyRequests:
            return ("Предупреждение", "Слишком много запросов\nза единицу времени", "Слишком много запросов")
        case .MissingAccessToken:
            return ("Ошибка доступа", "Приложение не отправило\nмаркер доступа", "Нет маркера доступа")
        case .InvalidVkAccessToken:
            return ("Ошибка доступа", "Авторизация через ВКонтакте\nотклонена сервером", "Авторизация через ВКонтакте отклонена")
        case .TooManyRequestsToCreationToken:
            return ("Предупреждение", "Слишком много запросов\nна создание маркера доступа",
                "Слишком много запросов на авторизацию")
        case .UnknownError:
            return ("Неизвестная ошибка", "Cервер вернул ошибку, которую\nприложение не может обработать",
                "Невозможно установить причину")
        case .InvalidJson:
            return ("Ошибка обработки", "Не удалось правильно обработать\nответ сервера", "Данные не обработаны")
        }
    }
}

/**
    Класс для работы с API MISIS Books
*/
class MisisBooksApi {

    /// Маркер доступа
    var accessToken = NSUserDefaults.standardUserDefaults().stringForKey("accessToken")

    /// Маркер доступа для ВКонтакте
    var vkAccessToken: String!

    /// Задача для работы с аккаунтом
    private var accountDataTask: NSURLSessionDataTask?

    /// Строка базового URL
    private let baseUrlString = "http://twosphere.ru/api"

    /// Задача для работы с поиском
    private var searchDataTask: NSURLSessionDataTask?

    /// Сессия
    private let session = NSURLSession.sharedSession()

    /// Задача для работы с избранным
    private var favoritesDataTask: NSURLSessionDataTask?

    /**
        Возвращает экземпляр класса

        - returns: Экземпляр класса
    */
    class var instance: MisisBooksApi {

        struct Singleton {
            static let instance = MisisBooksApi()
        }

        return Singleton.instance
    }

    /**
        Выполняет запрос к серверу для получения информации об аккаунте

        - parameter completionHandler: Обработчик завершения
    */
    func getAccountInformation(completionHandler: (json: [String: AnyObject]?) -> Void) {
        let url = NSURL(string: "\(baseUrlString)/account.getInfo?access_token=\(accessToken!)")!
        let request = NSMutableURLRequest(URL: url, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 15)

        NSURLSession.sharedSession().dataTaskWithRequest(request) { data, _, error in
            dispatch_async(dispatch_get_main_queue()) {
                if error == nil {
                    do {
                        let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers)
                            as! [String: AnyObject]
                        completionHandler(json: json)
                    } catch {
                        completionHandler(json: nil)
                    }
                } else {
                    completionHandler(json: nil)
                }
            }
            }!.resume()
    }

    // MARK: Методы для работы с поиском

    /**
        Выполненяет запрос к серверу на получение списка всех категорий
    */
    func getCategories() {
        // TODO: Доделать
    }

    /**
        Выполненяет запрос к серверу на получение списка популярных книг

        - parameter count: Количество возвращаемых результатов
        - parameter categoryId: Идентификатор категории
    */
    func getPopular(count count: Int, categoryId: Int) {
        if accessToken != nil {
            let parameters = ["access_token=\(accessToken!)", "category=\(categoryId)", "count=\(count)", "fields=all"]
            let urlString = "\(baseUrlString)/materials.getPopular?" + "&".join(parameters)

            executeAction(.GetPopular, urlString: urlString) { json, error in
                if error != nil {
                    PopUpMessage(title: "Ошибка", subtitle: error!.description().short).show()
                } else if let response = json!["response"] as? [String: AnyObject],
                    items = response["items"] as? [AnyObject],
                    totalResults = response["all_items_count"] as? Int {
                        ControllerManager.instance.searchTableViewController.updateTable(self.getReceivedBooksFromItems(items),
                            totalResults: totalResults)
                }
            }
        } else {
            signIn {
                self.getPopular(count: count, categoryId: categoryId)
            }
        }
    }

    /**
        Выполненяет запрос к серверу на получение списка популярных документов за неделю

        - parameter count: Количество возвращаемых результатов
        - parameter categoryId: Идентификатор категории
    */
    func getPopularForWeek(count count: Int, categoryId: Int) {
        if accessToken != nil {
            let parameters = ["access_token=\(accessToken!)", "category=\(categoryId)", "count=\(count)", "fields=all"]
            let urlString = "\(baseUrlString)/materials.getPopularForWeek?" + "&".join(parameters)

            executeAction(.GetPopularForWeek, urlString: urlString) { json, error in
                if error != nil {
                    PopUpMessage(title: "Ошибка", subtitle: error!.description().short).show()
                } else if let response = json!["response"] as? [String: AnyObject],
                    items = response["items"] as? [AnyObject],
                    totalResults = response["all_items_count"] as? Int {
                        ControllerManager.instance.searchTableViewController.updateTable(self.getReceivedBooksFromItems(items),
                            totalResults: totalResults)
                }
            }
        } else {
            signIn {
                self.getPopularForWeek(count: count, categoryId: categoryId)
            }
        }
    }

    /**
        Выполненяет запрос к серверу на получение результатов поиска

        parameter query: Поисковый запрос
        parameter count: Количество возвращаемых результатов
        parameter offset: Cмещение выборки
        parameter categoryId: Идентификатор категории
    */
    func search(query query: String, count: Int, offset: Int, categoryId: Int) {
        if accessToken != nil {
            let parameters = ["access_token=\(accessToken!)", "category=\(categoryId)", "count=\(count)", "fields=all",
                "offset=\(offset)", "q=\(query.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)"]
            let urlString = "\(baseUrlString)/materials.search?" + "&".join(parameters)

            executeAction(.Search, urlString: urlString) { json, error in
                if error != nil {
                    PopUpMessage(title: "Ошибка", subtitle: error!.description().short).show()
                } else if let response = json!["response"] as? [String: AnyObject],
                    items = response["items"] as? [AnyObject],
                    totalResults = response["all_items_count"] as? Int {
                        ControllerManager.instance.searchTableViewController.updateTable(self.getReceivedBooksFromItems(items),
                            totalResults: totalResults)
                }
            }
        } else {
            signIn {
                self.search(query: query, count: count, offset: offset, categoryId: categoryId)
            }
        }
    }

    // MARK: - Методы для работы с избранным

    /**
        Выполненяет запрос к серверу на добавление книги в избранное

        - parameter book: Книга
    */
    func addBookToFavorites(book: Book) {
        if accessToken != nil {
            let urlString = "\(baseUrlString)/fave.addDocument?edition_id=\(book.id)&access_token=\(accessToken!)"

            executeAction(.AddBookToFavorites, urlString: urlString) { json, error in
                if error != nil {
                    PopUpMessage(title: "Ошибка", subtitle: error!.description().short).show()
                } else if let response = json!["response"] as? [String: AnyObject],
                    result = response["result"] as? Bool {
                        if result {
                            ControllerManager.instance.favoritesTableViewController.addBook(book)
                            PopUpMessage(title: "Сервер принял запрос", subtitle: "Документ успешно добавлен в избранное").show()
                        } else {
                            PopUpMessage(title: "Сервер отклонил запрос", subtitle: "Не удалось добавить документ в избранное").show()
                        }
                }
            }
        } else {
            signIn {
                self.addBookToFavorites(book)
            }
        }
    }

    /**
        Выполненяет запрос к серверу на получение списка избранных документов

        - parameter count: Количество возвращаемых результатов
        - parameter offset: Cмещение выборки
    */
    func getFavorites(count count: Int, offset: Int) {
        if accessToken != nil {
            let parameters = ["access_token=\(accessToken!)", "count=\(count)", "fields=all", "offset=\(offset)"]
            let urlString = "\(baseUrlString)/fave.getDocuments?" + "&".join(parameters)

            executeAction(.GetFavorites, urlString: urlString) { json, error in
                if error != nil {
                    if error!.description().title != "Ошибка соединения" {
                        PopUpMessage(title: "Ошибка", subtitle: error!.description().short).show()
                    }

                    print("Загружаем избранное из БД")

                    ControllerManager.instance.favoritesTableViewController.loadBooksFromDatabase()
                } else if let response = json!["response"] as? [String: AnyObject],
                    items = response["items"] as? [AnyObject],
                    totalResults = response["all_items_count"] as? Int {
                        ControllerManager.instance.favoritesTableViewController.updateTable(
                                self.getReceivedBooksFromItems(items), totalResults: totalResults)
                }
            }
        } else {
            signIn {
                self.getFavorites(count: count, offset: offset)
            }
        }
    }

    /**
        Выполненяет запрос к серверу на удаление всех книг из избранного
    */
    func deleteAllBooksFromFavorites() {
        if accessToken != nil {
            let urlString = "\(baseUrlString)/fave.deleteAllDocuments?access_token=\(accessToken!)"

            executeAction(.DeleteAllBooksFromFavorites, urlString: urlString) { json, error in
                if error != nil {
                    PopUpMessage(title: "Ошибка", subtitle: error!.description().short).show()
                } else if let response = json!["response"] as? [String: AnyObject],
                    result = response["result"] as? Bool {
                        if result {
                            ControllerManager.instance.favoritesTableViewController.deleteAllBooks()
                            PopUpMessage(title: "Сервер принял запрос", subtitle: "Все документы удалены из избранного").show()
                        } else {
                            PopUpMessage(title: "Сервер отклонил запрос", subtitle: "Не удалось удалить все документы из избранного")
                                .show()
                        }
                }
            }
        } else {
            signIn {
                self.deleteAllBooksFromFavorites()
            }
        }
    }

    /**
        Выполненяет запрос к серверу на удаление книг из избранного

        - parameter books: Книги
    */
    func deleteBooksFromFavorites(books: [Book]) {
        if accessToken != nil {
            let bookIdsString = ",".join(books.map { String($0.id) })
            let urlString = "\(baseUrlString)/fave.deleteDocument?edition_id=\(bookIdsString)&access_token=\(accessToken!)"

            executeAction(.DeleteBookFromFavorites, urlString: urlString) { json, error in
                if error != nil {
                    PopUpMessage(title: "Ошибка", subtitle: error!.description().short).show()
                } else if let response = json!["response"] as? [String: AnyObject],
                    result = response["result"] as? Bool {
                        if result {
                            ControllerManager.instance.favoritesTableViewController.deleteBooks(books)

                            if books.count == 1 {
                                PopUpMessage(title: "Сервер принял запрос", subtitle: "Документ успешно удален из избранного").show()
                            } else {
                                PopUpMessage(title: "Сервер принял запрос", subtitle: "Документы успешно удалены из избранного").show()
                            }
                        } else {
                            if books.count == 1 {
                                PopUpMessage(title: "Сервер отклонил запрос", subtitle: "Не удалось удалить документ из избранного")
                                    .show()
                            } else {
                                PopUpMessage(title: "Сервер отклонил запрос", subtitle: "Не удалось удалить документы из избранного")
                                    .show()
                            }
                        }
                }
            }
        } else {
            signIn {
                self.deleteBooksFromFavorites(books)
            }
        }
    }

    // MARK: - Методы для работы с аккаунтом

    /**
        Выполняет запрос к серверу на получение маркера доступа

        - parameter completionHandler: Обработчик завершения
    */
    func signIn(completionHandler: () -> Void) {
        if vkAccessToken != nil {
            let urlString = "\(baseUrlString)/auth.signin?vk_access_token=\(vkAccessToken)"

            executeAction(.SignIn, urlString: urlString) { json, _ in
                if let json = json, response = json["response"] as? [String: AnyObject],
                    accessToken = response["access_token"] as? String {
                        print("Маркер доступа получен: \(accessToken)")

                        let standardUserDefaults = NSUserDefaults.standardUserDefaults()
                        standardUserDefaults.setObject(accessToken, forKey: "accessToken")
                        standardUserDefaults.synchronize()
                        self.accessToken = accessToken

                        ControllerManager.instance.menuTableViewController.updateTableHeaderView()
                        completionHandler()
                }
            }
        } else {
            ControllerManager.instance.searchTableViewController.showPlaceholderView(PlaceholderView(
                viewController: ControllerManager.instance.searchTableViewController, title: "Поиск недоступен",
                subtitle: "Чтобы искать документы,\nнеобходимо авторизоваться", buttonText: "Авторизоваться") {
                    ControllerManager.instance.menuTableViewController.logInButtonPressed()
                })
            ControllerManager.instance.favoritesTableViewController.showPlaceholderView(PlaceholderView(
                viewController: ControllerManager.instance.favoritesTableViewController,
                title: "Избранное недоступно", subtitle: "Чтобы работать с избранным,\nнеобходимо авторизоваться",
                buttonText: "Авторизоваться") {
                    ControllerManager.instance.menuTableViewController.logInButtonPressed()
                })
        }
    }

    // MARK: - Внутренние методы

    /**
        Выполняет запрос к серверу с заданными параметрами

        - parameter action: Действие
        - parameter urlString: Строка URL
        - parameter completionHandler: Обработчик завершения
    */
    private func executeAction(action: MisisBooksApiAction, urlString: String,
        completionHandler: (json: [String: AnyObject]?, error: MisisBooksApiError?) -> Void) {
            print("Запрос: \(urlString)")

            let url = NSURL(string: urlString)!
            let request = NSMutableURLRequest(URL: url, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 15)

            let task = session.dataTaskWithRequest(request) { data, response, error in
                do {
                    let httpResponse = response as! NSHTTPURLResponse?
                    let mimeType = httpResponse?.MIMEType

                    if error != nil {
                        print("Код ошибки соединения: \(error!.code)")

                        switch error!.code {
                        case -1009: // NSURLErrorNotConnectedToInternet
                            throw MisisBooksApiError.NotConnectedToInternet
                        case -1001: // NSURLErrorTimedOut
                            throw MisisBooksApiError.TimedOut
                        default:
                            throw MisisBooksApiError.NotConnected
                        }
                    } else if data!.length == 0 {
                        throw MisisBooksApiError.NoData
                    } else if httpResponse?.statusCode != 200 {
                        throw MisisBooksApiError.StatusCodeNotSupported
                    } else if mimeType == nil {
                        throw MisisBooksApiError.MissingMimeType
                    } else if mimeType != "application/json" {
                        throw MisisBooksApiError.MimeTypeNotSupported
                    }

                    do {
                        let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers)
                            as! [String: AnyObject]

                        if let error = json["error"] as? [String: AnyObject],
                            errorCode = error["error_code"] as? Int {
                                switch errorCode {
                                case 2: // "The user has no subscription"
                                    throw MisisBooksApiError.NoSubscription
                                case 3: // "Too many requests"
                                    throw MisisBooksApiError.TooManyRequests
                                case 4: // "Invalid access token"
                                    // Получение нового маркера доступа с возможностью дальнейшего выполнения запроса
                                    self.signIn {
                                        self.executeAction(action, urlString: urlString, completionHandler: completionHandler)
                                    }
                                case 5: // "Missing access token"
                                    throw MisisBooksApiError.MissingAccessToken
                                case 6: // "Invalid VK access token"
                                    throw MisisBooksApiError.InvalidVkAccessToken
                                case 7: // "Too many requests to creation token"
                                    throw MisisBooksApiError.TooManyRequestsToCreationToken
                                default:
                                    throw MisisBooksApiError.UnknownError
                                }
                        } else {
                            dispatch_async(dispatch_get_main_queue()) {
                                completionHandler(json: json, error: nil)
                            }
                        }
                    } catch {
                        throw MisisBooksApiError.InvalidJson
                    }
                } catch let error {
                    let error = error as! MisisBooksApiError

                    switch action {
                    case .Search, .GetPopular, .GetPopularForWeek, .GetCategories:
                        dispatch_async(dispatch_get_main_queue()) {
                            ControllerManager.instance.searchTableViewController.showPlaceholderView(
                                PlaceholderView(viewController: ControllerManager.instance.searchTableViewController,
                                    title: error.description().title, subtitle: error.description().detail, buttonText: "Повторить попытку") {
                                        self.executeAction(action, urlString: urlString, completionHandler: completionHandler)
                                }
                            )
                        }
                    case .GetFavorites, .AddBookToFavorites, .DeleteBookFromFavorites, .DeleteAllBooksFromFavorites:
                        dispatch_async(dispatch_get_main_queue()) {
                            completionHandler(json: nil, error: error)
                        }
                    case .SignIn:
                        ControllerManager.instance.menuTableViewController.vkLogInFailed()
                    default:
                        break
                    }
                }
            }

            switch action {
            case .Search, .GetPopular, .GetPopularForWeek, .GetCategories:
                searchDataTask?.cancel()
                searchDataTask = task
            case .GetFavorites, .AddBookToFavorites, .DeleteBookFromFavorites, .DeleteAllBooksFromFavorites:
                favoritesDataTask?.cancel()
                favoritesDataTask = task
            case .SignIn, .LogOut:
                accountDataTask?.cancel()
                accountDataTask = task
            }

            task!.resume()
    }

    /**
        Возвращает отформатированную строку с авторами, которые перечислены через запятую, учитывая, что нельзя отделять инициалы
        от фамилии или один инициал от другого (используются неразрывные пробелы)

        - parameter authors: Авторы

        - returns: Отформатированная строка с авторами
    */
    private func formattedStringWithAuthors(authors: [String]) -> String {
        var result = "|".join(authors)
        let from = [" ", "|", ".", "\u{00a0}\u{00a0}", ".\u{00a0},"]
        let to = ["\u{00a0}", ", ", ".\u{00a0}", "\u{00a0}", ".,"]

        for i in 0...4 {
            result = result.stringByReplacingOccurrencesOfString(from[i], withString: to[i], options: .LiteralSearch, range: nil)
        }

        return result
    }

    /**
        Возвращает отформатированную строку с размером файла, где число отделено от единицы измерения неразрывным пробелом

        - parameter fileSize: Размер файла

        - returns: Отформатированная строка с размером файла
    */
    private func formattedStringWithFileSize(fileSize: String) -> String {
        var result = fileSize
        let from = ["Mb", "Kb"]
        let to = ["\u{00a0}МБ", "\u{00a0}КБ"]

        for i in 0...1 {
            result = result.stringByReplacingOccurrencesOfString(from[i], withString: to[i], options: .LiteralSearch, range: nil)
        }

        return result
    }

    /**
        Обрабатывает и возвращает полученные от сервера книги

        - parameter items: Элементы

        - returns: Книги
    */
    private func getReceivedBooksFromItems(items: [AnyObject]) -> [Book] {
        var receivedBooks = [Book]()

        for item in items {
            if let authors = item["authors"] as? [String],
                bigPreviewUrl = item["photo_big"] as? String,
                category = item["category"] as? [String: AnyObject],
                categoryId = category["id"] as? Int,
                downloadUrl = item["download_url"] as? String,
                fileSize = item["size"] as? String,
                id = item["id"] as? Int,
                isMarkedAsFavorite = item["fave"] as? Bool,
                name = item["name"] as? String,
                smallPreviewUrl = item["photo_small"] as? String {
                    receivedBooks.append(Book(authors: formattedStringWithAuthors(authors), bigPreviewUrl: bigPreviewUrl,
                        categoryId: categoryId, downloadUrl: downloadUrl, fileSize: formattedStringWithFileSize(fileSize), id: id,
                        isMarkedAsFavorite: isMarkedAsFavorite, name: name, smallPreviewUrl: smallPreviewUrl))
            }
        }

        return receivedBooks
    }
}
