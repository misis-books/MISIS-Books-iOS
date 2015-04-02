//
//  MisisBooksApi.swift
//  misisbooks
//
//  Created by Maxim Loskov on 06.12.14.
//  Copyright (c) 2014 Maxim Loskov. All rights reserved.
//

import Foundation

enum MisisBooksApiAction {
    
    case Search
    case GetPopular
    case GetPopularForWeek
    case GetCategories
    
    case GetFavorites
    case AddBookToFavorites
    case DeleteBookFromFavorites
    case DeleteAllBooksFromFavorites
    
    case SignIn
    case LogOut
}

/// Класс для работы с API MISIS Books
class MisisBooksApi {
    
    /// Маркер доступа
    var accessToken = NSUserDefaults.standardUserDefaults().stringForKey("accessToken")
    
    /// Строка базового URL
    private let baseUrlString = "http://twosphere.ru/api"
    
    /// Сессия
    private var session = NSURLSession.sharedSession()
    
    /// Задача для работы с поиском
    private var searchDataTask : NSURLSessionDataTask?
    
    /// Задача для работы с избранным
    private var favoritesDataTask : NSURLSessionDataTask?
    
    /// Задача для работы с аккаунтом
    private var accountDataTask : NSURLSessionDataTask?
    
    
    /// Возвращает экземпляр класса
    ///
    /// :returns: Экземпляр класса
    class var sharedInstance : MisisBooksApi {
        
        struct Singleton {
            static let sharedInstance = MisisBooksApi()
        }
        
        return Singleton.sharedInstance
    }
    
    /// MARK: Методы для работы с поиском
    
    /// Выполненяет запрос к серверу на получение результатов поиска
    ///
    /// :param: query Поисковый запрос
    /// :param: count Количество возвращаемых результатов
    /// :param: offset Cмещение выборки
    /// :param: category Категория
    func search(#query: String, count: Int, offset: Int, category: Int) {
        if accessToken != nil {
            let action = MisisBooksApiAction.Search
            let urlString = "\(baseUrlString)/materials.search?fields=all&q=\(query.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)&count=\(count)&offset=\(offset)&category=\(category)&access_token=\(accessToken!)"
            
            executeAction(action, urlString: urlString) {
                (json) -> Void in
                if let response = json["response"] as? NSDictionary {
                    if let items = response["items"] as? NSArray {
                        if let allItemsCount = response["all_items_count"] as? Int {
                            ControllerManager.sharedInstance.searchTableViewController.updateTableWithReceivedBooks(self.getReceivedBooksFromItems(items), totalResults: allItemsCount)
                        }
                    }
                }
            }
        } else {
            signIn {
                self.search(query: query, count: count, offset: offset, category: category)
            }
        }
    }
    
    /// Выполненяет запрос к серверу на получение списка популярных книг
    ///
    /// :param: count Количество возвращаемых результатов
    /// :param: category Категория
    func getPopular(#count: Int, category: Int) {
        if accessToken != nil {
            let urlString = "\(baseUrlString)/materials.getPopular?fields=all&count=\(count)&category=\(category)&access_token=\(accessToken!)"
            
            executeAction(.GetPopular, urlString: urlString) {
                (json) -> Void in
                if let response = json["response"] as? NSDictionary {
                    if let items = response["items"] as? NSArray {
                        if let allItemsCount = response["all_items_count"] as? Int {
                            ControllerManager.sharedInstance.searchTableViewController.updateTableWithReceivedBooks(self.getReceivedBooksFromItems(items), totalResults: allItemsCount)
                        }
                    }
                }
            }
        } else {
            signIn {
                self.getPopular(count: count, category: count)
            }
        }
    }
    
    /// Выполненяет запрос к серверу на получение списка популярных документов за неделю
    ///
    /// :param: count Количество возвращаемых результатов
    /// :param: category Категория
    func getPopularForWeek(#count: Int, category: Int) {
        if accessToken != nil {
            let urlString = "\(baseUrlString)/materials.getPopularForWeek?fields=all&count=\(count)&category=\(category)&access_token=\(accessToken!)"
            
            executeAction(.GetPopularForWeek, urlString: urlString) {
                (json) -> Void in
                if let response = json["response"] as? NSDictionary {
                    if let items = response["items"] as? NSArray {
                        if let allItemsCount = response["all_items_count"] as? Int {
                            ControllerManager.sharedInstance.searchTableViewController.updateTableWithReceivedBooks(self.getReceivedBooksFromItems(items), totalResults: allItemsCount)
                        }
                    }
                }
            }
        } else {
            signIn {
                self.getPopularForWeek(count: count, category: count)
            }
        }
    }
    
    /// Выполненяет запрос к серверу на получение списка всех категорий
    func getCategories() {
        if accessToken != nil {
            let urlString = "\(baseUrlString)/materials.getCategories?access_token=\(accessToken!)"
            
            executeAction(.GetCategories, urlString: urlString) {
                (json) -> Void in
                if let response = json["response"] as? NSDictionary {
                    // TODO: Доделать
                }
            }
        } else {
            signIn {
                self.getCategories()
            }
        }
    }
    
    /// MARK: Методы для работы с избранным
    
    /// Выполненяет запрос к серверу на получение списка избранных документов
    func getFavorites() {
        if accessToken != nil {
            let urlString = "\(baseUrlString)/fave.getDocuments?fields=all&access_token=\(accessToken!)"
            
            executeAction(.GetFavorites, urlString: urlString) {
                (json) -> Void in
                if let response = json["response"] as? NSDictionary {
                    if let items = response["items"] as? NSArray {
                        AlertBanner(title: "Синхронизация избранного завершена", subtitle: "Документы получены от сервера").show()
                        
                        let receivedBooks = self.getReceivedBooksFromItems(items)
                        let books = ControllerManager.sharedInstance.favoritesTableViewController.books
                        
                        for book in books {
                            var isBookFound = false
                            
                            for receivedBook in receivedBooks {
                                if receivedBook.bookId == book.bookId {
                                    isBookFound = true
                                }
                            }
                            
                            if !isBookFound {
                                ControllerManager.sharedInstance.favoritesTableViewController.deleteBooksFromFavorites([book])
                            }
                        }
                        
                        for receivedBook in receivedBooks {
                            var isReceivedBookFound = false
                            
                            for book in books {
                                if book.bookId == receivedBook.bookId {
                                    isReceivedBookFound = true
                                }
                            }
                            
                            if !isReceivedBookFound {
                                ControllerManager.sharedInstance.favoritesTableViewController.addBookToFavorites(receivedBook)
                            }
                        }
                        

                    }
                }
            }
        } else {
            signIn {
                self.getFavorites()
            }
        }
    }
    
    func addBookToFavorites(book: Book) {
        if accessToken != nil {
            let urlString = "\(baseUrlString)/fave.addDocument?edition_id=\(book.bookId)&access_token=\(accessToken!)"
            
            executeAction(.AddBookToFavorites, urlString: urlString) {
                (json) -> Void in
                if let response = json["response"] as? NSDictionary {
                    if let result = response["result"] as? Bool {
                        if result {
                            ControllerManager.sharedInstance.favoritesTableViewController.addBookToFavorites(book)
                            AlertBanner(title: "Сервер принял запрос", subtitle: "Документ успешно добавлен в избранное").show()
                        } else {
                            AlertBanner(title: "Сервер отклонил запрос", subtitle: "Не удалось добавить документ в избранное").show()
                        }
                    }
                }
            }
        } else {
            signIn {
                self.addBookToFavorites(book)
            }
        }
    }
    
    func deleteBooksFromFavorites(books: [Book]) {
        if accessToken != nil {
            let bookIdsString = join(",", map(books, { String($0.bookId) }))
            let urlString = "\(baseUrlString)/fave.deleteDocument?edition_id=\(bookIdsString)&access_token=\(accessToken!)"
            
            executeAction(.DeleteBookFromFavorites, urlString: urlString) {
                (json) -> Void in
                if let response = json["response"] as? NSDictionary {
                    if let result = response["result"] as? Bool {
                        if result {
                            ControllerManager.sharedInstance.favoritesTableViewController.deleteBooksFromFavorites(books)
                            
                            if books.count == 1 {
                                AlertBanner(title: "Сервер принял запрос", subtitle: "Документ успешно удален из избранного").show()
                            } else {
                                AlertBanner(title: "Сервер принял запрос", subtitle: "Документы успешно удалены из избранного").show()
                            }
                        } else {
                            if books.count == 1 {
                                AlertBanner(title: "Сервер отклонил запрос", subtitle: "Не удалось удалить документ из избранного").show()
                            } else {
                                AlertBanner(title: "Сервер отклонил запрос", subtitle: "Не удалось удалить документы из избранного").show()
                            }
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
    
    func deleteAllBooksFromFavorites() {
        if accessToken != nil {
            let urlString = "\(baseUrlString)/fave.deleteAllDocuments?access_token=\(accessToken!)"
            
            executeAction(.DeleteAllBooksFromFavorites, urlString: urlString) {
                (json) -> Void in
                if let response = json["response"] as? NSDictionary {
                    if let result = response["result"] as? Bool {
                        ControllerManager.sharedInstance.favoritesTableViewController.deleteAllBooksFromFavorites()
                        
                        if result {
                            AlertBanner(title: "Сервер принял запрос", subtitle: "Все документы удалены из избранного").show()
                        } else {
                            AlertBanner(title: "Сервер отклонил запрос", subtitle: "Не удалось удалить все документы из избранного").show()
                        }
                    }
                }
            }
        } else {
            signIn {
                self.deleteAllBooksFromFavorites()
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
            
            executeAction(.SignIn, urlString: urlString) {
                (json) -> Void in
                if let response = json["response"] as? NSDictionary {
                    if let accessToken = response["access_token"] as? String {
                        println("Маркер доступа получен.")
                        
                        let standardUserDefaults = NSUserDefaults.standardUserDefaults()
                        standardUserDefaults.setObject(accessToken, forKey: "accessToken")
                        standardUserDefaults.synchronize()
                        self.accessToken = accessToken
                        
                        ControllerManager.sharedInstance.menuTableViewController.updateTableHeaderView()
                        
                        completionHandler()
                    }
                }
            }
        } else {
            ControllerManager.sharedInstance.searchTableViewController.showInformationView(InformationView(
                viewController: ControllerManager.sharedInstance.searchTableViewController,
                title: "Поиск недоступен",
                subtitle: "Чтобы искать документы,\nнеобходимо авторизоваться",
                buttonText: "Авторизоваться") {
                    ControllerManager.sharedInstance.menuTableViewController.logInButtonPressed()
                })
        }
    }
    
    /// Выполняет запрос к серверу с заданными параметрами
    ///
    /// :param: action Действие
    /// :param: urlString Строка URL
    /// :param: completionHandler Обработчик завершения
    func executeAction(action: MisisBooksApiAction, urlString: String, completionHandler: (json: NSDictionary) -> Void) {
        println("Запрос: \(urlString)")
        
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 10.0)
        
        let task = session.dataTaskWithRequest(request) {
            (data, response, error) -> Void in
            let httpResponse = response as NSHTTPURLResponse?
            let contentTypeHeader = httpResponse?.MIMEType
            var errorDescription = [String]()
            
            if let connectionError = error {
                switch connectionError.code {
                case -1009: // NSURLErrorNotConnectedToInternet
                    errorDescription = [
                        "Ошибка соединения",
                        "Не удалось установить связь\nс сервером, так как отсутствует\nподключение к Интернету"
                    ]
                    break
                case -1001: // NSURLErrorTimedOut
                    errorDescription = [
                        "Ошибка соединения",
                        "Не удалось установить связь\nс сервером, так как истекло\nвремя ожидания ответа"
                    ]
                    break
                default:
                    errorDescription = [
                        "Ошибка соединения",
                        "Не удалось подключиться к серверу"
                    ]
                    break
                }
                
                println("Код ошибки соединения: \(connectionError.code)")
            } else if data.length == 0 {
                errorDescription = [
                    "Ошибка обработки",
                    "Сервер не вернул данные"
                ]
            } else if httpResponse?.statusCode != 200 {
                errorDescription = [
                    "Запрос не выполнен",
                    "Код состояния HTTP \"\(httpResponse?.statusCode)\"\nне поддерживается"
                ]
            } else if contentTypeHeader == nil {
                errorDescription = [
                    "Запрос не выполнен",
                    "Отсутствует MIME-тип"
                ]
            } else if contentTypeHeader != "application/json" {
                errorDescription = [
                    "Запрос не выполнен",
                    "MIME-тип \"\(contentTypeHeader!)\"\nне поддерживается"
                ]
            } else {
                var jsonError : NSError?
                let json = NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers, error: &jsonError) as NSDictionary
                
                if jsonError != nil {
                    errorDescription = [
                        "Ошибка обработки",
                        "Не удалось правильно обработать\nответ сервера"
                    ]
                } else if let error = json["error"] as? NSDictionary {
                    if let errorCode = error["error_code"] as? Int {
                        switch errorCode {
                        case 2: // "The user has no subscription"
                            errorDescription = [
                                "Предупреждение",
                                "Вы не оформили подписку"
                            ]
                            break
                        case 3: // "Too many requests"
                            errorDescription = [
                                "Предупреждение",
                                "Слишком много запросов\nза единицу времени"
                            ]
                            break
                        case 4: // "Invalid access token"
                            // Получение нового маркера доступа с возможностью дальнейшего выполнения запроса
                            self.signIn {
                                self.executeAction(action, urlString: urlString, completionHandler: completionHandler)
                            }
                            break
                        case 5: // "Missing access token"
                            errorDescription = [
                                "Ошибка доступа",
                                "Приложение не отправило\nмаркер доступа"
                            ]
                            break
                        case 6: // "Invalid VK access token"
                            errorDescription = [
                                "Ошибка доступа",
                                "Авторизация через ВКонтакте\nотклонена сервером"
                            ]
                            break
                        case 7: // "Too many requests to creation token"
                            errorDescription = [
                                "Предупреждение",
                                "Слишком много запросов\nна создание маркера доступа"
                            ]
                            break
                        default:
                            errorDescription = [
                                "Неизвестная ошибка",
                                "Cервер вернул ошибку, которую\nприложение не может обработать"
                            ]
                            break
                        }
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        completionHandler(json: json)
                    }
                }
            }
            
            if errorDescription.count == 2 {
                switch action {
                case .Search, .GetPopular, .GetPopularForWeek, .GetCategories:
                    dispatch_async(dispatch_get_main_queue()) {
                        ControllerManager.sharedInstance.searchTableViewController.showInformationView(InformationView(
                            viewController: ControllerManager.sharedInstance.searchTableViewController,
                            title: errorDescription[0],
                            subtitle: errorDescription[1],
                            buttonText: "Повторить попытку") {
                                self.executeAction(action, urlString: urlString, completionHandler: completionHandler)
                            })
                    }
                    break
                case .GetFavorites, .AddBookToFavorites, .DeleteBookFromFavorites, .DeleteAllBooksFromFavorites:
                    dispatch_async(dispatch_get_main_queue()) {
                        AlertBanner(title: "Ошибка", subtitle: "Невозможно выполнить это действие").show()
                    }
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
    
    /// MARK: - Впомогательные методы
    
    /// Возвращает полученные от сервера книги
    ///
    /// :param: items Массив элементов
    /// :returns: Массив книг
    func getReceivedBooksFromItems(items: NSArray) -> [Book] {
        var receivedBooks = [Book]()
        
        for var i = 0; i < items.count; ++i {
            receivedBooks.append(
                Book(
                    bookId: items[i]["id"] as Int,
                    name: items[i]["name"] as String,
                    authors: getFormattedStringWithAuthors(items[i]["authors"] as [String]),
                    category: (items[i]["category"] as NSDictionary)["id"] as Int,
                    fileSize: getFormattedStringWithFileSize(items[i]["size"] as String),
                    smallPhotoUrl: items[i]["photo_small"] as String,
                    bigPhotoUrl: items[i]["photo_big"] as String,
                    downloadUrl: items[i]["download_url"] as String
                )
            )
        }
        
        return receivedBooks
    }
    
    /// Возвращает отформатированную строку с авторами, которые перечислены через запятую, учитывая, что нельзя отделять инициалы
    /// от фамилии или один инициал от другого (используются неразрывные пробелы)
    ///
    /// :param: authors Авторы
    /// :returns: Отформатированная строка с авторами
    func getFormattedStringWithAuthors(authors: [String]) -> String {
        var formattedString = join("|", authors)
        let array1 = [" ", "|", ".", "\u{00a0}\u{00a0}", ".\u{00a0},"]
        let array2 = ["\u{00a0}", ", ", ".\u{00a0}", "\u{00a0}", ".,"]
        
        for var i = 0; i < 5; ++i {
            formattedString = formattedString.stringByReplacingOccurrencesOfString(array1[i], withString: array2[i], options: .LiteralSearch, range: nil)
        }
        
        return formattedString
    }
    
    /// Возвращает отформатированную строку с размером файла, где число отделено от единицы измерения неразрывным пробелом
    ///
    /// :param: fileSize Размер файла
    /// :returns: Отформатированная строка с размером файла
    func getFormattedStringWithFileSize(fileSize: String) -> String {
        var formattedString = fileSize
        let array1 = ["Mb", "Kb"]
        let array2 = ["\u{00a0}МБ", "\u{00a0}КБ"]
        
        for var i = 0; i < 2; ++i {
            formattedString = formattedString.stringByReplacingOccurrencesOfString(array1[i], withString: array2[i], options: .LiteralSearch, range: nil)
        }
        
        return formattedString
    }
    
    /// MARK: - Методы экземпляра класса
    
    /// Выполняет запрос к серверу для получения длинного URL по короткому
    ///
    /// :param: shortUrl Короткий URL
    /// :param: completionHandler Обработчик завершения
    class func getLongUrlFromShortUrl(shortUrl: NSURL, completionHandler: (longUrl: NSURL?) -> Void) {
        let request = NSMutableURLRequest(URL: shortUrl, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 10.0)
        request.HTTPMethod = "HEAD"
        
        NSURLSession.sharedSession().dataTaskWithRequest(request) {
            (data, response, error) -> Void in
            completionHandler(longUrl: error == nil ? (response as NSHTTPURLResponse).URL! : nil)
            }.resume()
    }
    
    /// Выполняет запрос к серверу для получения информации об аккаунте
    ///
    /// :param: accessToken Маркер доступа
    /// :param: completionHandler Обработчик завершения
    class func getAccountInformation(accessToken: String, completionHandler: (json: NSDictionary?) -> Void) {
        let urlString = "http://twosphere.ru/api/account.getInfo?access_token=\(accessToken)"
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 10.0)
        
        NSURLSession.sharedSession().dataTaskWithRequest(request) {
            (data, response, error) -> Void in
            if error == nil {
                var jsonError : NSError?
                let json = NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers, error: &jsonError) as NSDictionary
                
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler(json: jsonError == nil ? json : nil)
                }
            }
            }.resume()
    }
}
