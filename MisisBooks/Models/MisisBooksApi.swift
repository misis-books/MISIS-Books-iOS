//
//  MisisBooksApi.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 06.12.14.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import Foundation

enum MisisBooksApiAction {
    
    case AddBookToFavorites
    case Search
    case DeleteAllBooksFromFavorites
    case DeleteBookFromFavorites
    case GetCategories
    case GetFavorites
    case GetPopular
    case GetPopularForWeek
    case LogOut
    case SignIn
}

struct MisisBooksApiError {
    
    /// Описание ошибки
    var description: String
    
    /// Заголовок ошибки
    var title: String
    
    /// Краткое описание ошибки
    var shortDescription: String
    
    /// Инициализирует структуру заданными параметрами
    ///
    /// :param: title Заголовок ошибки
    /// :param: description Описание ошибки
    /// :oaram: shortDescription Краткое описание ошибки
    init(title: String, description: String, shortDescription: String) {
        self.title = title
        self.description = description
        self.shortDescription = shortDescription
    }
}

/// Класс для работы с API MISIS Books
class MisisBooksApi {
    
    /// Маркер доступа
    var accessToken = NSUserDefaults.standardUserDefaults().stringForKey("accessToken")
    
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
    
    /// Возвращает экземпляр класса
    ///
    /// :returns: Экземпляр класса
    class var instance: MisisBooksApi {
        
        struct Singleton {
            
            static let instance = MisisBooksApi()
        }
        
        return Singleton.instance
    }
    
    /// Выполняет запрос к серверу для получения информации об аккаунте
    ///
    /// :param: accessToken Маркер доступа
    /// :param: completionHandler Обработчик завершения
    class func getAccountInformation(accessToken: String, completionHandler: (json: NSDictionary?) -> Void) {
        let url = NSURL(string: "http://twosphere.ru/api/account.getInfo?access_token=\(accessToken)")!
        let request = NSMutableURLRequest(URL: url, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 10)
        
        NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
            if error == nil {
                var jsonError: NSError?
                let json = NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers, error: &jsonError)
                    as! NSDictionary
                
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler(json: jsonError == nil ? json : nil)
                }
            }
            }.resume()
    }
    
    /// MARK: Методы для работы с поиском
    
    /// Выполненяет запрос к серверу на получение списка всех категорий
    func getCategories() {
        if accessToken != nil {
            let urlString = "\(baseUrlString)/materials.getCategories?access_token=\(accessToken!)"
            
            executeAction(.GetCategories, urlString: urlString) { json, error in
                if let json = json, response = json["response"] as? NSDictionary {
                    // TODO: Доделать
                } else if error != nil {
                    AlertBanner(title: "Ошибка", subtitle: error!.shortDescription).show()
                }
            }
        } else {
            signIn {
                self.getCategories()
            }
        }
    }
    
    /// Выполненяет запрос к серверу на получение списка популярных книг
    ///
    /// :param: count Количество возвращаемых результатов
    /// :param: categoryId Идентификатор категории
    func getPopular(#count: Int, categoryId: Int) {
        if accessToken != nil {
            let parameters = ["access_token=\(accessToken!)", "category=\(categoryId)", "count=\(count)", "fields=all"]
            let urlString = "\(baseUrlString)/materials.getPopular?" + join("&", parameters)
            
            executeAction(.GetPopular, urlString: urlString) { json, error in
                if let json = json, response = json["response"] as? NSDictionary, items = response["items"] as? NSArray,
                    totalResults = response["all_items_count"] as? Int {
                        ControllerManager.instance.searchTableViewController.updateTable(self.getReceivedBooksFromItems(items),
                            totalResults: totalResults)
                } else if error != nil {
                    AlertBanner(title: "Ошибка", subtitle: error!.shortDescription).show()
                }
            }
        } else {
            signIn {
                self.getPopular(count: count, categoryId: categoryId)
            }
        }
    }
    
    /// Выполненяет запрос к серверу на получение списка популярных документов за неделю
    ///
    /// :param: count Количество возвращаемых результатов
    /// :param: categoryId Идентификатор категории
    func getPopularForWeek(#count: Int, categoryId: Int) {
        if accessToken != nil {
            let parameters = ["access_token=\(accessToken!)", "category=\(categoryId)", "count=\(count)", "fields=all"]
            let urlString = "\(baseUrlString)/materials.getPopularForWeek?" + join("&", parameters)
            
            executeAction(.GetPopularForWeek, urlString: urlString) { json, error in
                if let json = json, response = json["response"] as? NSDictionary, items = response["items"] as? NSArray,
                    totalResults = response["all_items_count"] as? Int {
                        ControllerManager.instance.searchTableViewController.updateTable(self.getReceivedBooksFromItems(items),
                            totalResults: totalResults)
                } else if error != nil {
                    AlertBanner(title: "Ошибка", subtitle: error!.shortDescription).show()
                }
            }
        } else {
            signIn {
                self.getPopularForWeek(count: count, categoryId: categoryId)
            }
        }
    }
    
    /// Выполненяет запрос к серверу на получение результатов поиска
    ///
    /// :param: query Поисковый запрос
    /// :param: count Количество возвращаемых результатов
    /// :param: offset Cмещение выборки
    /// :param: categoryId Идентификатор категории
    func search(#query: String, count: Int, offset: Int, categoryId: Int) {
        if accessToken != nil {
            let parameters = ["access_token=\(accessToken!)", "category=\(categoryId)", "count=\(count)", "fields=all",
                "offset=\(offset)", "q=\(query.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)"]
            let urlString = "\(baseUrlString)/materials.search?" + join("&", parameters)
            
            executeAction(.Search, urlString: urlString) { json, error in
                if let json = json, response = json["response"] as? NSDictionary, items = response["items"] as? NSArray,
                    totalResults = response["all_items_count"] as? Int {
                        ControllerManager.instance.searchTableViewController.updateTable(self.getReceivedBooksFromItems(items),
                            totalResults: totalResults)
                } else if error != nil {
                    AlertBanner(title: "Ошибка", subtitle: error!.shortDescription).show()
                }
            }
        } else {
            signIn {
                self.search(query: query, count: count, offset: offset, categoryId: categoryId)
            }
        }
    }
    
    /// MARK: Методы для работы с избранным
    
    /// Выполненяет запрос к серверу на добавление книги в избранное
    ///
    /// :param: book Книга
    func addBookToFavorites(book: Book) {
        if accessToken != nil {
            let urlString = "\(baseUrlString)/fave.addDocument?edition_id=\(book.id)&access_token=\(accessToken!)"
            
            executeAction(.AddBookToFavorites, urlString: urlString) { json, error in
                if let json = json, response = json["response"] as? NSDictionary, result = response["result"] as? Bool {
                    if result {
                        ControllerManager.instance.favoritesTableViewController.addBook(book)
                        AlertBanner(title: "Сервер принял запрос", subtitle: "Документ успешно добавлен в избранное").show()
                    } else {
                        AlertBanner(title: "Сервер отклонил запрос", subtitle: "Не удалось добавить документ в избранное").show()
                    }
                } else if error != nil {
                    AlertBanner(title: "Ошибка", subtitle: error!.shortDescription).show()
                }
            }
        } else {
            signIn {
                self.addBookToFavorites(book)
            }
        }
    }
    
    /// Выполненяет запрос к серверу на получение списка избранных документов
    ///
    /// :param: count Количество возвращаемых результатов
    /// :param: offset Cмещение выборки
    func getFavorites(#count: Int, offset: Int) {
        if accessToken != nil {
            let parameters = ["access_token=\(accessToken!)", "count=\(count)", "fields=all", "offset=\(offset)"]
            let urlString = "\(baseUrlString)/fave.getDocuments?" + join("&", parameters)
            
            executeAction(.GetFavorites, urlString: urlString) { json, error in
                if let json = json, response = json["response"] as? NSDictionary, items = response["items"] as? NSArray,
                    totalResults = response["all_items_count"] as? Int {
                        ControllerManager.instance.favoritesTableViewController.updateTable(
                                self.getReceivedBooksFromItems(items), totalResults: totalResults)
                } else {
                    println("Загружаем избранное из БД")
                    ControllerManager.instance.favoritesTableViewController.loadBooksFromDatabase()
                    
                    if error != nil {
                        if error!.title != "Ошибка соединения" {
                            AlertBanner(title: "Ошибка", subtitle: error!.shortDescription).show()
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
    
    /// Выполненяет запрос к серверу на удаление всех книг из избранного
    func deleteAllBooksFromFavorites() {
        if accessToken != nil {
            let urlString = "\(baseUrlString)/fave.deleteAllDocuments?access_token=\(accessToken!)"
            
            executeAction(.DeleteAllBooksFromFavorites, urlString: urlString) { json, error in
                if let json = json, response = json["response"] as? NSDictionary, result = response["result"] as? Bool {
                    if result {
                        ControllerManager.instance.favoritesTableViewController.deleteAllBooks()
                        AlertBanner(title: "Сервер принял запрос", subtitle: "Все документы удалены из избранного").show()
                    } else {
                        AlertBanner(title: "Сервер отклонил запрос", subtitle: "Не удалось удалить все документы из избранного")
                            .show()
                    }
                } else if error != nil {
                    AlertBanner(title: "Ошибка", subtitle: error!.shortDescription).show()
                }
            }
        } else {
            signIn {
                self.deleteAllBooksFromFavorites()
            }
        }
    }
    
    /// Выполненяет запрос к серверу на удаление книг из избранного
    ///
    /// :param: books Книги
    func deleteBooksFromFavorites(books: [Book]) {
        if accessToken != nil {
            let bookIdsString = join(",", map(books) { String($0.id) })
            let urlString = "\(baseUrlString)/fave.deleteDocument?edition_id=\(bookIdsString)&access_token=\(accessToken!)"
            
            executeAction(.DeleteBookFromFavorites, urlString: urlString) { json, error in
                if let json = json, response = json["response"] as? NSDictionary, result = response["result"] as? Bool {
                    if result {
                        ControllerManager.instance.favoritesTableViewController.deleteBooks(books)
                        
                        if books.count == 1 {
                            AlertBanner(title: "Сервер принял запрос", subtitle: "Документ успешно удален из избранного").show()
                        } else {
                            AlertBanner(title: "Сервер принял запрос", subtitle: "Документы успешно удалены из избранного").show()
                        }
                    } else {
                        if books.count == 1 {
                            AlertBanner(title: "Сервер отклонил запрос", subtitle: "Не удалось удалить документ из избранного")
                                .show()
                        } else {
                            AlertBanner(title: "Сервер отклонил запрос", subtitle: "Не удалось удалить документы из избранного")
                                .show()
                        }
                    }
                } else if error != nil {
                    AlertBanner(title: "Ошибка", subtitle: error!.shortDescription).show()
                }
            }
        } else {
            signIn {
                self.deleteBooksFromFavorites(books)
            }
        }
    }
    
    /// Методы для работы с аккаунтом
    
    /// Выполняет запрос к серверу на получение маркера доступа
    ///
    /// :param: completionHandler Обработчик завершения
    func signIn(completionHandler: () -> Void) {
        if let vkAccessToken = NSUserDefaults.standardUserDefaults().stringForKey("vkAccessToken") {
            let urlString = "\(baseUrlString)/auth.signin?vk_access_token=\(vkAccessToken)"
            
            executeAction(.SignIn, urlString: urlString) { json, errorDescription in
                if let json = json, response = json["response"] as? NSDictionary,
                    accessToken = response["access_token"] as? String {
                        println("Маркер доступа получен.")
                        
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
                viewController: ControllerManager.instance.searchTableViewController,
                title: "Избранное недоступно", subtitle: "Чтобы работать с избранным,\nнеобходимо авторизоваться",
                buttonText: "Авторизоваться") {
                    ControllerManager.instance.menuTableViewController.logInButtonPressed()
                })
        }
    }
    
    /// MARK: - Внутренние методы
    
    /// Выполняет запрос к серверу с заданными параметрами
    ///
    /// :param: action Действие
    /// :param: urlString Строка URL
    /// :param: completionHandler Обработчик завершения
    private func executeAction(action: MisisBooksApiAction, urlString: String,
        completionHandler: (json: NSDictionary?, error: MisisBooksApiError?) -> Void) {
            println("Запрос: \(urlString)")
            
            let url = NSURL(string: urlString)!
            let request = NSMutableURLRequest(URL: url, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 10)
            
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
                        break
                    case -1001: // NSURLErrorTimedOut
                        apiError = MisisBooksApiError(title: "Ошибка соединения",
                            description: "Не удалось установить связь\nс сервером, так как истекло\nвремя ожидания ответа",
                            shortDescription: "Истекло время ожидания ответа")
                        break
                    default:
                        apiError = MisisBooksApiError(title: "Ошибка соединения",
                            description: "Не удалось подключиться к серверу",
                            shortDescription: "Не удалось подключиться к серверу")
                        break
                    }
                    
                    println("Код ошибки соединения: \(connectionError.code)")
                } else if data.length == 0 {
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
                    var jsonError: NSError?
                    let json = NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers, error: &jsonError)
                        as! NSDictionary
                    
                    if jsonError != nil {
                        apiError = MisisBooksApiError(title: "Ошибка обработки",
                            description: "Не удалось правильно обработать\nответ сервера",
                            shortDescription: "Данные не обработаны")
                    } else if let error = json["error"] as? NSDictionary, errorCode = error["error_code"] as? Int {
                        switch errorCode {
                        case 2: // "The user has no subscription"
                            apiError = MisisBooksApiError(title: "Предупреждение", description: "Вы не оформили подписку",
                                shortDescription: "Вы не оформили подписку")
                            break
                        case 3: // "Too many requests"
                            apiError = MisisBooksApiError(title: "Предупреждение",
                                description: "Слишком много запросов\nза единицу времени",
                                shortDescription: "Слишком много запросов")
                            break
                        case 4: // "Invalid access token"
                            // Получение нового маркера доступа с возможностью дальнейшего выполнения запроса
                            self.signIn {
                                self.executeAction(action, urlString: urlString, completionHandler: completionHandler)
                            }
                            break
                        case 5: // "Missing access token"
                            apiError = MisisBooksApiError(title: "Ошибка доступа",
                                description: "Приложение не отправило\nмаркер доступа",
                                shortDescription: "Нет маркера доступа")
                            break
                        case 6: // "Invalid VK access token"
                            apiError = MisisBooksApiError(title: "Ошибка доступа",
                                description: "Авторизация через ВКонтакте\nотклонена сервером",
                                shortDescription: "Авторизация через ВКонтакте отклонена")
                            break
                        case 7: // "Too many requests to creation token"
                            apiError = MisisBooksApiError(title: "Предупреждение",
                                description: "Слишком много запросов\nна создание маркера доступа",
                                shortDescription: "Слишком много запросов на авторизацию")
                            break
                        default:
                            apiError = MisisBooksApiError(title: "Неизвестная ошибка",
                                description: "Cервер вернул ошибку, которую\nприложение не может обработать",
                                shortDescription: "Невозможно установить причину")
                            break
                        }
                    } else {
                        dispatch_async(dispatch_get_main_queue()) {
                            completionHandler(json: json, error: nil)
                        }
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
                        break
                    case .GetFavorites, .AddBookToFavorites, .DeleteBookFromFavorites, .DeleteAllBooksFromFavorites:
                        dispatch_async(dispatch_get_main_queue()) {
                            completionHandler(json: nil, error: apiError!)
                        }
                        break
                    case .SignIn:
                        ControllerManager.instance.menuTableViewController.vkLogInFailed()
                        break
                    default:
                        break
                    }
                }
            }
        
        switch action {
        case .Search, .GetPopular, .GetPopularForWeek, .GetCategories:
            searchDataTask?.cancel()
            searchDataTask = task
            break
        case .GetFavorites, .AddBookToFavorites, .DeleteBookFromFavorites, .DeleteAllBooksFromFavorites:
            favoritesDataTask?.cancel()
            favoritesDataTask = task
            break
        case .SignIn, .LogOut:
            accountDataTask?.cancel()
            accountDataTask = task
            break
        default:
            break
        }
        
        task.resume()
    }
    
    /// Возвращает отформатированную строку с авторами, которые перечислены через запятую, учитывая, что нельзя отделять инициалы
    /// от фамилии или один инициал от другого (используются неразрывные пробелы)
    ///
    /// :param: authors Авторы
    /// :returns: Отформатированная строка с авторами
    private func formattedStringWithAuthors(authors: [String]) -> String {
        var result = join("|", authors)
        let from = [" ", "|", ".", "\u{00a0}\u{00a0}", ".\u{00a0},"]
        let to = ["\u{00a0}", ", ", ".\u{00a0}", "\u{00a0}", ".,"]
        
        for i in 0...4 {
            result = result.stringByReplacingOccurrencesOfString(from[i], withString: to[i], options: .LiteralSearch, range: nil)
        }
        
        return result
    }
    
    /// Возвращает отформатированную строку с размером файла, где число отделено от единицы измерения неразрывным пробелом
    ///
    /// :param: fileSize Размер файла
    /// :returns: Отформатированная строка с размером файла
    private func formattedStringWithFileSize(fileSize: String) -> String {
        var result = fileSize
        let from = ["Mb", "Kb"]
        let to = ["\u{00a0}МБ", "\u{00a0}КБ"]
        
        for i in 0...1 {
            result = result.stringByReplacingOccurrencesOfString(from[i], withString: to[i], options: .LiteralSearch, range: nil)
        }
        
        return result
    }
    
    /// Обрабатывает и возвращает полученные от сервера книги
    ///
    /// :param: items Элементы
    /// :returns: Книги
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