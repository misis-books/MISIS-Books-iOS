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
class MisisBooksApi : NSObject {
    
    /// Объект, хранящий структуру JSON
    var json : NSDictionary!
    
    /// Строка базового URL
    let baseUrlString = "http://twosphere.ru/api"
    
    /// Маркер доступа
    private var accessToken = NSUserDefaults.standardUserDefaults().stringForKey("accessToken")
    
    /// Сессия
    private var session = NSURLSession.sharedSession()
    
    /// Задача для работы с поиском
    private var searchDataTask : NSURLSessionDataTask? = nil
    
    /// Задача для работы с избранным
    private var favoritesDataTask : NSURLSessionDataTask? = nil
    
    /// Задача для работы с аккаунтом
    private var accountDataTask : NSURLSessionDataTask? = nil
    
    
    /// MARK: Методы для работы с поиском
    
    /// Выполненяет запрос к серверу на получение результатов поиска, соотсветствующих поисковому запросу и ряду других параметров: количество возвращаемых результатов, смещение, категория
    func search(#query: String, count: Int, offset: Int, category: Int) {
        if accessToken != nil {
            let action = MisisBooksApiAction.Search
            let urlString = "\(baseUrlString)/materials.search?fields=all&q=\(query.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)&count=\(count)&offset=\(offset)&category=\(category)&access_token=\(accessToken!)"
            executeAction(action, urlString: urlString) { (json) -> Void in
                if let response = json["response"] as? NSDictionary {
                    if let items = response["items"] as? NSArray {
                        if let allItemsCount = response["all_items_count"] as? Int {
                            ControllerManager.instance.searchTableViewController.updateTableWithReceivedBooks(self.getReceivedBooksFromItems(items), allItemsCount: allItemsCount)
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
    func getPopular(#count: Int, category: Int) {
        if accessToken != nil {
            let action = MisisBooksApiAction.GetPopular
            let urlString = "\(baseUrlString)/materials.getPopular?fields=all&count=\(count)&category=\(category)&access_token=\(accessToken!)"
            executeAction(action, urlString: urlString) { (json) -> Void in
                if let response = json["response"] as? NSDictionary {
                    if let items = response["items"] as? NSArray {
                        if let allItemsCount = response["all_items_count"] as? Int {
                            ControllerManager.instance.searchTableViewController.updateTableWithReceivedBooks(self.getReceivedBooksFromItems(items), allItemsCount: allItemsCount)
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
    func getPopularForWeek(#count: Int, category: Int) {
        if accessToken != nil {
            let action = MisisBooksApiAction.GetPopularForWeek
            let urlString = "\(baseUrlString)/materials.getPopularForWeek?fields=all&count=\(count)&category=\(category)&access_token=\(accessToken!)"
            executeAction(action, urlString: urlString) { (json) -> Void in
                if let response = json["response"] as? NSDictionary {
                    if let items = response["items"] as? NSArray {
                        if let allItemsCount = response["all_items_count"] as? Int {
                            ControllerManager.instance.searchTableViewController.updateTableWithReceivedBooks(self.getReceivedBooksFromItems(items), allItemsCount: allItemsCount)
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
    
    /// Выполненяет запрос к серверу на получение списка всех видов документов
    func getCategories() {
        if accessToken != nil {
            let action = MisisBooksApiAction.GetCategories
            let urlString = "\(baseUrlString)/materials.getCategories?access_token=\(accessToken!)"
            executeAction(action, urlString: urlString) { (json) -> Void in
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
    
    func getFavorites() {
        if accessToken != nil {
            let action = MisisBooksApiAction.GetFavorites
            let urlString = "\(baseUrlString)/fave.getDocuments?access_token=\(accessToken!)"
            executeAction(action, urlString: urlString) { (json) -> Void in
                if let response = json["response"] as? NSDictionary {
                    // TODO: Доделать по аналогии с поиском
                }
            }
        } else {
            signIn {
                self.getFavorites()
            }
        }
    }
    
    func addBookToFavorites(#book: Book) {
        if accessToken != nil {
            let action = MisisBooksApiAction.AddBookToFavorites
            let urlString = "\(baseUrlString)/fave.addDocument?edition_id=\(book.bookId!)&access_token=\(accessToken!)"
            executeAction(action, urlString: urlString) { (json) -> Void in
                if let response = json["response"] as? NSDictionary {
                    if let result = response["result"] as? Bool {
                        if result {
                            AlertBanner(title: "Сервер принял запрос", subtitle: "Документ успешно добавлен в избранное").show()
                        } else {
                            AlertBanner(title: "Сервер отклонил запрос", subtitle: "Не удалось добавить документ в избранное").show()
                        }
                    }
                }
            }
        } else {
            signIn {
                self.addBookToFavorites(book: book)
            }
        }
    }
    
    func deleteBookFromFavorites(#book: Book) {
        if accessToken != nil {
            let action = MisisBooksApiAction.DeleteBookFromFavorites
            let urlString = "\(baseUrlString)/fave.deleteDocument?edition_id=\(book.bookId!)&access_token=\(accessToken!)"
            executeAction(action, urlString: urlString) { (json) -> Void in
                if let response = json["response"] as? NSDictionary {
                    if let result = response["result"] as? Bool {
                        if result {
                            AlertBanner(title: "Сервер принял запрос", subtitle: "Документ успешно удален из избранного").show()
                        } else {
                            AlertBanner(title: "Сервер отклонил запрос", subtitle: "Не удалось удалить документ из избранного").show()
                        }
                    }
                }
            }
        } else {
            signIn {
                self.deleteBookFromFavorites(book: book)
            }
        }
    }
    
    func deleteAllBooksFromFavorites() {
        if accessToken != nil {
            let action = MisisBooksApiAction.DeleteAllBooksFromFavorites
            let urlString = "\(baseUrlString)/fave.deleteAllDocuments?access_token=\(accessToken!)"
            executeAction(action, urlString: urlString) { (json) -> Void in
                if let response = json["response"] as? NSDictionary {
                    if let result = response["result"] as? Bool {
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
    
    /// Выполняет запрос к серверу на получение маркера доступа через проихождение регистрации. Метод должен вызываться только в тех случаях, когда приложение в первый раз пытается получить доступ к API, или ранее полученный маркер доступа перестал быть действующим, иными словами, был удалён или заблокирован
    func signIn(completionHandler: () -> Void) {
        if let vkAccessToken = NSUserDefaults.standardUserDefaults().stringForKey("vkAccessToken") {
            let action = MisisBooksApiAction.SignIn
            let urlString = "\(baseUrlString)/auth.signin?vk_access_token=\(vkAccessToken)"
            executeAction(action, urlString: urlString) { (json) -> Void in
                if let response = json["response"] as? NSDictionary {
                    if let accessToken = response["access_token"] as? String {
                        println("Маркер доступа получен и будет записан в пользовательские настройки.")
                        
                        let standardUserDefaults = NSUserDefaults.standardUserDefaults()
                        standardUserDefaults.setObject(accessToken, forKey: "accessToken")
                        standardUserDefaults.synchronize()
                        self.accessToken = accessToken
                        
                        ControllerManager.instance.menuTableViewController.updateTableHeaderView()
                        
                        completionHandler()
                    }
                }
            }
        } else {
            ControllerManager.instance.searchTableViewController.showInformationView(InformationView(viewController: ControllerManager.instance.searchTableViewController, title: "Поиск недоступен", subtitle: "Чтобы искать документы,\nнеобходимо авторизоваться", linkButtonText: "Авторизоваться") {
                ControllerManager.instance.menuTableViewController.logInButtonPressed()
                })
        }
    }
    
    func executeAction(action: MisisBooksApiAction, urlString: String, callback: (json: NSDictionary) -> Void) {
        let request = NSMutableURLRequest(URL: NSURL(string: urlString)!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 10.0)
        let task = self.session.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            let httpResponse = response as NSHTTPURLResponse?
            let contentTypeHeader = httpResponse?.MIMEType
            var errorDescription = [String]()
            
            if let sessionError = error {
                switch sessionError.code {
                case -1009: // NSURLErrorNotConnectedToInternet
                    errorDescription = ["Ошибка соединения", "Не удалось установить связь\nс сервером, так как отсутствует\nподключение к Интернету"]
                    break
                case -1001: // NSURLErrorTimedOut
                    errorDescription = ["Ошибка соединения", "Не удалось установить связь\nс сервером, так как истекло\nвремя ожидания ответа"]
                    break
                default:
                    errorDescription = ["Ошибка соединения", "Не удалось подключиться к серверу"]
                    break
                }
                
                println("Код ошибки соединения: \(sessionError.code)")
            } else if data.length == 0 {
                errorDescription = ["Ошибка обработки", "Сервер не вернул данные"]
            } else if httpResponse?.statusCode != 200 {
                errorDescription = ["Запрос не выполнен", "Код состояния HTTP \"\(httpResponse?.statusCode)\"\nне поддерживается"]
            } else if contentTypeHeader == nil {
                errorDescription = ["Запрос не выполнен", "Отсутствует MIME-тип"]
            } else if contentTypeHeader != "application/json" {
                errorDescription = ["Запрос не выполнен", "MIME-тип \"\(contentTypeHeader!)\"\nне поддерживается"]
            } else {
                var jsonError : NSError?
                let json = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &jsonError) as NSDictionary
                
                if jsonError != nil {
                    errorDescription = ["Ошибка обработки", "Не удалось правильно обработать\nответ сервера"]
                } else if let error = json["error"] as? NSDictionary {
                    if let errorCode = error["error_code"] as? Int {
                        switch errorCode {
                        case 2: // "The user has no subscription"
                            errorDescription = ["Предупреждение", "Вы не оформили подписку"]
                            break
                        case 3: // "Too many requests"
                            errorDescription = ["Предупреждение", "Слишком много запросов\nза единицу времени"]
                            break
                        case 4: // "Invalid access token"
                            self.signIn({ // Получение нового маркера доступа с возможностью дальнейшего выполнения запроса
                                self.executeAction(action, urlString: urlString, callback: callback)
                            })
                            break
                        case 5: // "Missing access token"
                            errorDescription = ["Ошибка доступа", "Приложение не отправило\nмаркер доступа"]
                            break
                        case 6: // "Invalid VK access token"
                            errorDescription = ["Ошибка доступа", "Авторизация через ВКонтакте\nотклонена сервером"]
                            break
                        case 7: // "Too many requests to creation token"
                            errorDescription = ["Предупреждение", "Слишком много запросов\nна создание маркера доступа"]
                            break
                        default:
                            errorDescription = ["Неизвестная ошибка", "Cервер вернул ошибку, которую\nприложение не может обработать"]
                            break
                        }
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        callback(json: json)
                    }
                    // errorDescription = ["Ошибка обработки", "Cервер вернул данные, которые\nприложение не может обработать"]
                }
            }
            
            /// TODO: Не всегда нужно показывать информационный вид
            if errorDescription.count == 2 {
                dispatch_async(dispatch_get_main_queue()) {
                    ControllerManager.instance.searchTableViewController.showInformationView(InformationView(viewController: ControllerManager.instance.searchTableViewController, title: errorDescription[0], subtitle: errorDescription[1], linkButtonText: "Повторить попытку") {
                        self.executeAction(action, urlString: urlString, callback: callback)
                        })
                }
            }
        })
        
        switch action {
        case MisisBooksApiAction.Search, MisisBooksApiAction.GetPopular, MisisBooksApiAction.GetPopularForWeek, MisisBooksApiAction.GetCategories:
            searchDataTask?.cancel()
            searchDataTask = task
            searchDataTask?.resume()
            break
        case MisisBooksApiAction.GetFavorites, MisisBooksApiAction.AddBookToFavorites, MisisBooksApiAction.DeleteBookFromFavorites, MisisBooksApiAction.DeleteAllBooksFromFavorites:
            favoritesDataTask?.cancel()
            favoritesDataTask = task
            favoritesDataTask?.resume()
            break
        case MisisBooksApiAction.SignIn, MisisBooksApiAction.LogOut:
            accountDataTask?.cancel()
            accountDataTask = task
            accountDataTask?.resume()
            break
        default:
            task.resume()
            break
        }
    }
    
    /// MARK: - Впомогательные методы
    
    func getReceivedBooksFromItems(items: NSArray) -> [Book] {
        var receivedBooks = [Book]()
        
        for var i = 0; i < items.count; ++i {
            receivedBooks.append(Book(bookId: items[i]["id"] as Int,
                name: items[i]["name"] as String,
                authors: self.getFormattedStringWithAuthors(items[i]["authors"] as [String]),
                category: (items[i]["category"] as NSDictionary)["id"] as Int,
                fileSize: self.getFormattedStringWithFileSize(items[i]["size"] as String),
                smallPhotoUrl: items[i]["photo_small"] as String,
                bigPhotoUrl: items[i]["photo_big"] as String,
                downloadUrl: items[i]["download_url"] as String))
        }
        
        return receivedBooks
    }
    
    /// Возвращает отформатированную строку с авторами, которые перечислены через запятую, учитывая, что нельзя отделять инициалы от фамилии или один инициал от другого (используются неразрывные пробелы)
    ///
    /// :param: authors Авторы
    /// :returns: Отформатированная строка с авторами
    func getFormattedStringWithAuthors(authors: [String]) -> String {
        var formattedString = join("|", authors)
        let array1 = [" ", "|", ".", "\u{00a0}\u{00a0}", ".\u{00a0},"]
        let array2 = ["\u{00a0}", ", ", ".\u{00a0}", "\u{00a0}", ".,"]
        
        for var i = 0; i < 5; ++i {
            formattedString = formattedString.stringByReplacingOccurrencesOfString(array1[i], withString: array2[i], options: NSStringCompareOptions.LiteralSearch, range: nil)
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
            formattedString = formattedString.stringByReplacingOccurrencesOfString(array1[i], withString: array2[i], options: NSStringCompareOptions.LiteralSearch, range: nil)
        }
        
        return formattedString
    }
    
    /// MARK: - Дополнительнные методы
    
    /// Выполняет асинхронный запрос к серверу для получения длинного URL по короткому
    ///
    /// :param: shortUrl Короткий URL
    /// :param: completionHandler Блок обработчика завершения
    class func getLongUrlFromShortUrl(shortUrl: NSURL, completionHandler: (success: Bool, longUrl: NSURL?) -> Void) {
        println("Короткий URL: \(shortUrl.absoluteString!)")
        
        let request = NSMutableURLRequest(URL: shortUrl, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 10.0)
        request.HTTPMethod = "HEAD"
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {
            response, data, error in
            if error == nil {
                let longUrl = (response as NSHTTPURLResponse).URL!
                completionHandler(success: true, longUrl: longUrl)
                
                println("Длинный URL: \(longUrl.absoluteString!)")
            } else {
                completionHandler(success: false, longUrl: nil)
            }
        }
    }
    
    func getAccountInformation() {
        if let accessToken = NSUserDefaults.standardUserDefaults().stringForKey("accessToken") {
            let urlString = "http://twosphere.ru/api/account.getInfo?access_token=\(accessToken)"
            let request = NSMutableURLRequest(URL: NSURL(string: urlString)!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 10.0)
            
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {
                connectionResponse, connectionData, connectionError in
                if connectionError == nil {
                    var jsonError: NSError?
                    let jsonDictionary = NSJSONSerialization.JSONObjectWithData(connectionData, options: NSJSONReadingOptions.MutableContainers, error: &jsonError) as NSDictionary
                    
                    if jsonError == nil {
                        if let response = jsonDictionary["response"] as? NSDictionary {
                            if let user = response["user"] as? NSDictionary {
                                if let fullName = user["view_name"] as? String {
                                    println(fullName)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}