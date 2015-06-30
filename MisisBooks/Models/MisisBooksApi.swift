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
    Класс для хранения ошибки API MISIS Books
*/
struct MisisBooksApiError {
    
    /// Описание ошибки
    var description: String
    
    /// Заголовок ошибки
    var title: String
    
    /// Краткое описание ошибки
    var shortDescription: String
    
    /**
        Инициализирует структуру заданными параметрами

        - parameter title: Заголовок ошибки
        - parameter description: Описание ошибки
        - parameter shortDescription Краткое описание ошибки
    */
    init(title: String, description: String, shortDescription: String) {
        self.title = title
        self.description = description
        self.shortDescription = shortDescription
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

        - parameter accessToken: Маркер доступа
        - parameter completionHandler: Обработчик завершения
    */
    class func getAccountInformation(accessToken: String, completionHandler: (json: NSDictionary?) -> Void) {
        let url = NSURL(string: "http://twosphere.ru/api/account.getInfo?access_token=\(accessToken)")!
        let request = NSMutableURLRequest(URL: url, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 15)
        
        NSURLSession.sharedSession().dataTaskWithRequest(request) { data, _, error in
            dispatch_async(dispatch_get_main_queue()) {
                if error == nil {
                    do {
                        let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as! NSDictionary
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
        /*
        if accessToken != nil {
            let urlString = "\(baseUrlString)/materials.getCategories?access_token=\(accessToken!)"

            executeAction(.GetCategories, urlString: urlString) { json, error in
                if let json = json, response = json["response"] as? NSDictionary {
                } else if error != nil {
                    PopUpMessage(title: "Ошибка", subtitle: error!.shortDescription).show()
                }
            }
        } else {
            signIn {
                self.getCategories()
            }
        }
        */
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
                if let json = json, response = json["response"] as? NSDictionary, items = response["items"] as? NSArray,
                    totalResults = response["all_items_count"] as? Int {
                        ControllerManager.instance.searchTableViewController.updateTable(self.getReceivedBooksFromItems(items),
                            totalResults: totalResults)
                } else if error != nil {
                    PopUpMessage(title: "Ошибка", subtitle: error!.shortDescription).show()
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
                if let json = json, response = json["response"] as? NSDictionary, items = response["items"] as? NSArray,
                    totalResults = response["all_items_count"] as? Int {
                        ControllerManager.instance.searchTableViewController.updateTable(self.getReceivedBooksFromItems(items),
                            totalResults: totalResults)
                } else if error != nil {
                    PopUpMessage(title: "Ошибка", subtitle: error!.shortDescription).show()
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
                if let json = json, response = json["response"] as? NSDictionary, items = response["items"] as? NSArray,
                    totalResults = response["all_items_count"] as? Int {
                        ControllerManager.instance.searchTableViewController.updateTable(self.getReceivedBooksFromItems(items),
                            totalResults: totalResults)
                } else if error != nil {
                    PopUpMessage(title: "Ошибка", subtitle: error!.shortDescription).show()
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
                if let json = json, response = json["response"] as? NSDictionary, result = response["result"] as? Bool {
                    if result {
                        ControllerManager.instance.favoritesTableViewController.addBook(book)
                        PopUpMessage(title: "Сервер принял запрос", subtitle: "Документ успешно добавлен в избранное").show()
                    } else {
                        PopUpMessage(title: "Сервер отклонил запрос", subtitle: "Не удалось добавить документ в избранное").show()
                    }
                } else if error != nil {
                    PopUpMessage(title: "Ошибка", subtitle: error!.shortDescription).show()
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
                if let json = json, response = json["response"] as? NSDictionary, items = response["items"] as? NSArray,
                    totalResults = response["all_items_count"] as? Int {
                        ControllerManager.instance.favoritesTableViewController.updateTable(
                                self.getReceivedBooksFromItems(items), totalResults: totalResults)
                } else {
                    print("Загружаем избранное из БД")
                    ControllerManager.instance.favoritesTableViewController.loadBooksFromDatabase()
                    
                    if error != nil {
                        if error!.title != "Ошибка соединения" {
                            PopUpMessage(title: "Ошибка", subtitle: error!.shortDescription).show()
                        }
                    }
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
                if let json = json, response = json["response"] as? NSDictionary, result = response["result"] as? Bool {
                    if result {
                        ControllerManager.instance.favoritesTableViewController.deleteAllBooks()
                        PopUpMessage(title: "Сервер принял запрос", subtitle: "Все документы удалены из избранного").show()
                    } else {
                        PopUpMessage(title: "Сервер отклонил запрос", subtitle: "Не удалось удалить все документы из избранного")
                            .show()
                    }
                } else if error != nil {
                    PopUpMessage(title: "Ошибка", subtitle: error!.shortDescription).show()
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
                if let json = json, response = json["response"] as? NSDictionary, result = response["result"] as? Bool {
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
                } else if error != nil {
                    PopUpMessage(title: "Ошибка", subtitle: error!.shortDescription).show()
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
                if let json = json, response = json["response"] as? NSDictionary,
                    accessToken = response["access_token"] as? String {
                        print("Маркер доступа получен")
                        
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
        completionHandler: (json: NSDictionary?, error: MisisBooksApiError?) -> Void) {
            print("Запрос: \(urlString)")
            
            let url = NSURL(string: urlString)!
            let request = NSMutableURLRequest(URL: url, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 15)
            
            let task = session.dataTaskWithRequest(request) { data, response, error in
                let httpResponse = response as! NSHTTPURLResponse?
                let mimeType = httpResponse?.MIMEType
                var apiError: MisisBooksApiError? = nil
                
                if let connectionError = error {
                    switch connectionError.code {
                    case -1009: // NSURLErrorNotConnectedToInternet
                        apiError = MisisBooksApiError(title: "Ошибка соединения",
                            description: "Не удалось установить связь\nс сервером, так как отсутствует\nподключение к Интернету",
                            shortDescription: "Отсутствует подключение к Интернету")
                    case -1001: // NSURLErrorTimedOut
                        apiError = MisisBooksApiError(title: "Ошибка соединения",
                            description: "Не удалось установить связь\nс сервером, так как истекло\nвремя ожидания ответа",
                            shortDescription: "Истекло время ожидания ответа")
                    default:
                        apiError = MisisBooksApiError(title: "Ошибка соединения",
                            description: "Не удалось подключиться к серверу",
                            shortDescription: "Не удалось подключиться к серверу")
                    }
                    
                    print("Код ошибки соединения: \(connectionError.code)")
                } else if data!.length == 0 {
                    apiError = MisisBooksApiError(title: "Ошибка обработки", description: "Сервер не вернул данные",
                        shortDescription: "Сервер не вернул данные")
                } else if httpResponse?.statusCode != 200 {
                    apiError = MisisBooksApiError(title: "Запрос не выполнен",
                        description: "Код состояния HTTP \"\(httpResponse!.statusCode)\"\nне поддерживается",
                        shortDescription: "\"\(httpResponse!.statusCode)\" не поддерживается")
                } else if mimeType == nil {
                    apiError = MisisBooksApiError(title: "Запрос не выполнен", description: "Отсутствует MIME-тип",
                        shortDescription: "Отсутствует MIME-тип")
                } else if mimeType != "application/json" {
                    apiError = MisisBooksApiError(title: "Запрос не выполнен",
                        description: "MIME-тип \"\(mimeType!)\"\nне поддерживается",
                        shortDescription: "\"\(mimeType!)\" не поддерживается")
                } else {
                    do {
                        let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as! NSDictionary

                        if let error = json["error"] as? NSDictionary, errorCode = error["error_code"] as? Int {
                            switch errorCode {
                            case 2: // "The user has no subscription"
                                apiError = MisisBooksApiError(title: "Предупреждение", description: "Вы не оформили подписку",
                                    shortDescription: "Вы не оформили подписку")
                            case 3: // "Too many requests"
                                apiError = MisisBooksApiError(title: "Предупреждение",
                                    description: "Слишком много запросов\nза единицу времени",
                                    shortDescription: "Слишком много запросов")
                            case 4: // "Invalid access token"
                                // Получение нового маркера доступа с возможностью дальнейшего выполнения запроса
                                self.signIn {
                                    self.executeAction(action, urlString: urlString, completionHandler: completionHandler)
                                }
                            case 5: // "Missing access token"
                                apiError = MisisBooksApiError(title: "Ошибка доступа",
                                    description: "Приложение не отправило\nмаркер доступа",
                                    shortDescription: "Нет маркера доступа")
                            case 6: // "Invalid VK access token"
                                apiError = MisisBooksApiError(title: "Ошибка доступа",
                                    description: "Авторизация через ВКонтакте\nотклонена сервером",
                                    shortDescription: "Авторизация через ВКонтакте отклонена")
                            case 7: // "Too many requests to creation token"
                                apiError = MisisBooksApiError(title: "Предупреждение",
                                    description: "Слишком много запросов\nна создание маркера доступа",
                                    shortDescription: "Слишком много запросов на авторизацию")
                            default:
                                apiError = MisisBooksApiError(title: "Неизвестная ошибка",
                                    description: "Cервер вернул ошибку, которую\nприложение не может обработать",
                                    shortDescription: "Невозможно установить причину")
                            }
                        } else {
                            dispatch_async(dispatch_get_main_queue()) {
                                completionHandler(json: json, error: nil)
                            }
                        }
                    } catch {
                        apiError = MisisBooksApiError(title: "Ошибка обработки",
                            description: "Не удалось правильно обработать\nответ сервера",
                            shortDescription: "Данные не обработаны")
                    }
                }
                
                if apiError != nil {
                    switch action {
                    case .Search, .GetPopular, .GetPopularForWeek, .GetCategories:
                        dispatch_async(dispatch_get_main_queue()) {
                            ControllerManager.instance.searchTableViewController.showPlaceholderView(
                                PlaceholderView(viewController: ControllerManager.instance.searchTableViewController,
                                    title: apiError!.title, subtitle: apiError!.description, buttonText: "Повторить попытку") {
                                        self.executeAction(action, urlString: urlString, completionHandler: completionHandler)
                                }
                            )
                        }
                    case .GetFavorites, .AddBookToFavorites, .DeleteBookFromFavorites, .DeleteAllBooksFromFavorites:
                        dispatch_async(dispatch_get_main_queue()) {
                            completionHandler(json: nil, error: apiError!)
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
    private func getReceivedBooksFromItems(items: NSArray) -> [Book] {
        var receivedBooks = [Book]()
        
        for item in items {
            if let authors = item["authors"] as? [String], bigPreviewUrl = item["photo_big"] as? String,
                category = item["category"] as? NSDictionary, categoryId = category["id"] as? Int,
                downloadUrl = item["download_url"] as? String, fileSize = item["size"] as? String, id = item["id"] as? Int,
                isMarkedAsFavorite = item["fave"] as? Bool, name = item["name"] as? String,
                smallPreviewUrl = item["photo_small"] as? String {
                    receivedBooks.append(Book(authors: formattedStringWithAuthors(authors), bigPreviewUrl: bigPreviewUrl,
                        categoryId: categoryId, downloadUrl: downloadUrl, fileSize: formattedStringWithFileSize(fileSize), id: id,
                        isMarkedAsFavorite: isMarkedAsFavorite, name: name, smallPreviewUrl: smallPreviewUrl))
            }
        }
        
        return receivedBooks
    }
}
