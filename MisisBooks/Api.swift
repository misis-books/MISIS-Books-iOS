//
//  Api.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 06.12.14.
//  Copyright (c) 2016 Maxim Loskov. All rights reserved.
//

import Foundation

enum ApiAction {

    case addBookToFavorites
    case search
    case deleteAllBooksFromFavorites
    case deleteBookFromFavorites
    case getCategories
    case getFavorites
    case getPopular
    case getPopularForWeek
    case logOut
    case signIn

}

enum ApiError: Error {

    case notConnectedToInternet
    case timedOut
    case notConnected
    case noData
    case statusCodeNotSupported
    case missingMimeType
    case mimeTypeNotSupported
    case noSubscription
    case tooManyRequests
    case missingAccessToken
    case invalidVkAccessToken
    case tooManyRequestsToCreationToken
    case unknownError
    case invalidJson

    func description() -> (title: String, detail: String, short: String) {
        switch self {
        case .notConnectedToInternet:
            return ("Ошибка соединения",
                    "Не удалось установить связь\nс сервером, так как отсутствует\nподключение к Интернету",
                    "Отсутствует подключение к Интернету")
        case .timedOut:
            return ("Ошибка соединения",
                    "Не удалось установить связь\nс сервером, так как истекло\nвремя ожидания ответа",
                    "Истекло время ожидания ответа")
        case .notConnected:
            return ("Ошибка соединения", "Не удалось подключиться к серверу", "Не удалось подключиться к серверу")
        case .noData:
            return ("Ошибка обработки", "Сервер не вернул данные", "Сервер не вернул данные")
        case .statusCodeNotSupported:
            return ("Запрос не выполнен", "Код состояния HTTP не поддерживается",
                    "Код состояния HTTP не поддерживается")
        case .missingMimeType:
            return ("Запрос не выполнен", "Отсутствует MIME-тип", "Отсутствует MIME-тип")
        case .mimeTypeNotSupported:
            return ("Запрос не выполнен", "MIME-тип не поддерживается", "MIME-тип не поддерживается")
        case .noSubscription:
            return ("Предупреждение", "Вы не оформили подписку", "Вы не оформили подписку")
        case .tooManyRequests:
            return ("Предупреждение", "Слишком много запросов\nза единицу времени", "Слишком много запросов")
        case .missingAccessToken:
            return ("Ошибка доступа", "Приложение не отправило\nмаркер доступа", "Нет маркера доступа")
        case .invalidVkAccessToken:
            return ("Ошибка доступа", "Авторизация через ВКонтакте\nотклонена сервером",
                    "Авторизация через ВКонтакте отклонена")
        case .tooManyRequestsToCreationToken:
            return ("Предупреждение", "Слишком много запросов\nна создание маркера доступа",
                    "Слишком много запросов на авторизацию")
        case .unknownError:
            return ("Неизвестная ошибка", "Cервер вернул ошибку, которую\nприложение не может обработать",
                    "Невозможно установить причину")
        case .invalidJson:
            return ("Ошибка обработки", "Не удалось правильно обработать\nответ сервера", "Данные не обработаны")
        }
    }

}

class Api {

    static let instance = Api()
    var accessToken = UserDefaults.standard.string(forKey: "accessToken")
    var vkAccessToken: String!
    private var accountDataTask: URLSessionDataTask?
    private let baseUrlString = "http://twosphere.ru/api"
    private var searchDataTask: URLSessionDataTask?
    private let session = URLSession.shared
    private var favoritesDataTask: URLSessionDataTask?

    func getAccountInformation(_ completionHandler: @escaping (_ json: [String: AnyObject]?) -> ()) {
        let url = URL(string: "\(baseUrlString)/account.getInfo?access_token=\(accessToken!)")!
        let request = NSMutableURLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)

        session.dataTask(with: request as URLRequest) { data, _, error in
            DispatchQueue.main.async {
                if error == nil {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers)
                            as! [String: AnyObject]
                        completionHandler(json)
                    } catch {
                        completionHandler(nil)
                    }
                } else {
                    completionHandler(nil)
                }
            }
            }.resume()
    }

    func getCategories() {
        // TODO: Доделать
    }

    func getPopularBooksByCount(_ count: Int, categoryId: Int) {
        if accessToken != nil {
            let parameters = ["access_token=\(accessToken!)", "category=\(categoryId)", "count=\(count)", "fields=all"]
            let urlString = "\(baseUrlString)/materials.getPopular?" + parameters.joined(separator: "&")

            executeAction(.getPopular, urlString: urlString) { json, error in
                if error != nil {
                    PopUpMessage(title: "Ошибка", subtitle: error!.description().short).show()
                } else if let response = json!["response"] as? [String: AnyObject],
                    let items = response["items"] as? [AnyObject],
                    let totalResults = response["all_items_count"] as? Int {
                    ControllerManager.instance.searchTableViewController.updateTableWithReceivedBooks(
                        self.getReceivedBooksFromItems(items), totalResults: totalResults)
                }
            }
        } else {
            signIn {
                self.getPopularBooksByCount(count, categoryId: categoryId)
            }
        }
    }

    func getPopularBooksForWeekByCount(_ count: Int, categoryId: Int) {
        if accessToken != nil {
            let parameters = ["access_token=\(accessToken!)", "category=\(categoryId)", "count=\(count)", "fields=all"]
            let urlString = "\(baseUrlString)/materials.getPopularForWeek?" + parameters.joined(separator: "&")

            executeAction(.getPopularForWeek, urlString: urlString) { json, error in
                if error != nil {
                    PopUpMessage(title: "Ошибка", subtitle: error!.description().short).show()
                } else if let response = json!["response"] as? [String: AnyObject],
                    let items = response["items"] as? [AnyObject],
                    let totalResults = response["all_items_count"] as? Int {
                    ControllerManager.instance.searchTableViewController.updateTableWithReceivedBooks(
                        self.getReceivedBooksFromItems(items), totalResults: totalResults)
                }
            }
        } else {
            signIn {
                self.getPopularBooksForWeekByCount(count, categoryId: categoryId)
            }
        }
    }

    func searchBooksByQuery(_ query: String, count: Int, offset: Int, categoryId: Int) {
        if accessToken != nil {
            let parameters = [
                "access_token=\(accessToken!)",
                "category=\(categoryId)",
                "count=\(count)",
                "fields=all",
                "offset=\(offset)",
                "q=\(query.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)"
            ]
            let urlString = "\(baseUrlString)/materials.search?" + parameters.joined(separator: "&")

            executeAction(.search, urlString: urlString) { json, error in
                if error != nil {
                    PopUpMessage(title: "Ошибка", subtitle: error!.description().short).show()
                } else if let response = json!["response"] as? [String: AnyObject],
                    let items = response["items"] as? [AnyObject],
                    let totalResults = response["all_items_count"] as? Int {
                    ControllerManager.instance.searchTableViewController.updateTableWithReceivedBooks(
                        self.getReceivedBooksFromItems(items), totalResults: totalResults)
                }
            }
        } else {
            signIn {
                self.searchBooksByQuery(query, count: count, offset: offset, categoryId: categoryId)
            }
        }
    }

    func addBookToFavorites(_ book: Book) {
        if accessToken != nil {
            let urlString = "\(baseUrlString)/fave.addDocument?edition_id=\(book.id)&access_token=\(accessToken!)"

            executeAction(.addBookToFavorites, urlString: urlString) { json, error in
                if error != nil {
                    PopUpMessage(title: "Ошибка", subtitle: error!.description().short).show()
                } else if let response = json!["response"] as? [String: AnyObject],
                    let result = response["result"] as? Bool {
                    if result {
                        ControllerManager.instance.favoritesTableViewController.addBook(book)
                        PopUpMessage(title: "Сервер принял запрос", subtitle:
                            "Документ успешно добавлен в избранное").show()
                    } else {
                        PopUpMessage(title: "Сервер отклонил запрос", subtitle:
                            "Не удалось добавить документ в избранное").show()
                    }
                }
            }
        } else {
            signIn {
                self.addBookToFavorites(book)
            }
        }
    }

    func getFavoritesByCount(_ count: Int, offset: Int) {
        if accessToken != nil {
            let parameters = ["access_token=\(accessToken!)", "count=\(count)", "fields=all", "offset=\(offset)"]
            let urlString = "\(baseUrlString)/fave.getDocuments?" + parameters.joined(separator: "&")

            executeAction(.getFavorites, urlString: urlString) { json, error in
                if error != nil {
                    if error!.description().title != "Ошибка соединения" {
                        PopUpMessage(title: "Ошибка", subtitle: error!.description().short).show()
                    }

                    print("Загружаем избранное из БД")

                    ControllerManager.instance.favoritesTableViewController.loadBooksFromDatabase()
                } else if let response = json!["response"] as? [String: AnyObject],
                    let items = response["items"] as? [AnyObject],
                    let totalResults = response["all_items_count"] as? Int {
                    ControllerManager.instance.favoritesTableViewController.updateTable(
                        self.getReceivedBooksFromItems(items), totalResults: totalResults)
                }
            }
        } else {
            signIn {
                self.getFavoritesByCount(count, offset: offset)
            }
        }
    }

    func deleteAllBooksFromFavorites() {
        if accessToken != nil {
            let urlString = "\(baseUrlString)/fave.deleteAllDocuments?access_token=\(accessToken!)"

            executeAction(.deleteAllBooksFromFavorites, urlString: urlString) { json, error in
                if error != nil {
                    PopUpMessage(title: "Ошибка", subtitle: error!.description().short).show()
                } else if let response = json!["response"] as? [String: AnyObject],
                    let result = response["result"] as? Bool {
                    if result {
                        ControllerManager.instance.favoritesTableViewController.deleteAllBooks()
                        PopUpMessage(title: "Сервер принял запрос", subtitle:
                            "Все документы удалены из избранного").show()
                    } else {
                        PopUpMessage(title: "Сервер отклонил запрос", subtitle:
                            "Не удалось удалить все документы из избранного").show()
                    }
                }
            }
        } else {
            signIn {
                self.deleteAllBooksFromFavorites()
            }
        }
    }

    func deleteBooksFromFavorites(_ books: [Book]) {
        if accessToken != nil {
            let bookIds = books.map { String($0.id) }.joined(separator: ",")
            let urlString = "\(baseUrlString)/fave.deleteDocument?edition_id=\(bookIds)&access_token=\(accessToken!)"

            executeAction(.deleteBookFromFavorites, urlString: urlString) { json, error in
                if error != nil {
                    PopUpMessage(title: "Ошибка", subtitle: error!.description().short).show()
                } else if let response = json!["response"] as? [String: AnyObject],
                    let result = response["result"] as? Bool {
                    if result {
                        ControllerManager.instance.favoritesTableViewController.deleteBooks(books)

                        if books.count == 1 {
                            PopUpMessage(title: "Сервер принял запрос",
                                         subtitle: "Документ успешно удален из избранного").show()
                        } else {
                            PopUpMessage(title: "Сервер принял запрос",
                                         subtitle: "Документы успешно удалены из избранного").show()
                        }
                    } else {
                        if books.count == 1 {
                            PopUpMessage(title: "Сервер отклонил запрос",
                                         subtitle: "Не удалось удалить документ из избранного").show()
                        } else {
                            PopUpMessage(title: "Сервер отклонил запрос",
                                         subtitle: "Не удалось удалить документы из избранного").show()
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

    func signIn(_ completionHandler: @escaping () -> ()) {
        if vkAccessToken != nil {
            let urlString = "\(baseUrlString)/auth.signin?vk_access_token=\(vkAccessToken)"

            executeAction(.signIn, urlString: urlString) { json, _ in
                if let json = json, let response = json["response"] as? [String: AnyObject],
                    let accessToken = response["access_token"] as? String {
                    print("Маркер доступа получен: \(accessToken)")

                    let standardUserDefaults = UserDefaults.standard
                    standardUserDefaults.set(accessToken, forKey: "accessToken")
                    standardUserDefaults.synchronize()
                    self.accessToken = accessToken

                    ControllerManager.instance.menuTableViewController.updateTableHeaderView()
                    completionHandler()
                }
            }
        } else {
            ControllerManager.instance.searchTableViewController.showPlaceholderView(
                PlaceholderView(
                    viewController: ControllerManager.instance.searchTableViewController,
                    title: "Поиск недоступен",
                    subtitle: "Чтобы искать документы,\nнеобходимо авторизоваться",
                    buttonText: "Авторизоваться"
                ) {
                    ControllerManager.instance.menuTableViewController.logInButtonPressed()
                }
            )
            ControllerManager.instance.favoritesTableViewController.showPlaceholderView(
                PlaceholderView(
                    viewController: ControllerManager.instance.favoritesTableViewController,
                    title: "Избранное недоступно",
                    subtitle: "Чтобы работать с избранным,\nнеобходимо авторизоваться",
                    buttonText: "Авторизоваться"
                ) {
                    ControllerManager.instance.menuTableViewController.logInButtonPressed()
                }
            )
        }
    }

    private func executeAction(_ action: ApiAction, urlString: String,
                               completionHandler: @escaping (_ json: [String: AnyObject]?, _ error: ApiError?) -> ()) {
        print("Запрос: \(urlString)")

        let url = URL(string: urlString)!
        let request = NSMutableURLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            do {
                let httpResponse = response as! HTTPURLResponse?
                let mimeType = httpResponse?.mimeType

                if error != nil {
                    print("Код ошибки соединения: \(error!._code)")

                    switch error!._code {
                    case -1009: // NSURLErrorNotConnectedToInternet
                        throw ApiError.notConnectedToInternet
                    case -1001: // NSURLErrorTimedOut
                        throw ApiError.timedOut
                    default:
                        throw ApiError.notConnected
                    }
                } else if data!.count == 0 {
                    throw ApiError.noData
                } else if httpResponse?.statusCode != 200 {
                    throw ApiError.statusCodeNotSupported
                } else if mimeType == nil {
                    throw ApiError.missingMimeType
                } else if mimeType != "application/json" {
                    throw ApiError.mimeTypeNotSupported
                }

                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers)
                        as! [String: AnyObject]

                    if let error = json["error"] as? [String: AnyObject],
                        let errorCode = error["error_code"] as? Int {
                        switch errorCode {
                        case 2: // "The user has no subscription"
                            throw ApiError.noSubscription
                        case 3: // "Too many requests"
                            throw ApiError.tooManyRequests
                        case 4: // "Invalid access token"
                            // Получение нового маркера доступа с возможностью дальнейшего выполнения запроса
                            self.signIn {
                                self.executeAction(action, urlString: urlString, completionHandler:
                                    completionHandler)
                            }
                        case 5: // "Missing access token"
                            throw ApiError.missingAccessToken
                        case 6: // "Invalid VK access token"
                            throw ApiError.invalidVkAccessToken
                        case 7: // "Too many requests to creation token"
                            throw ApiError.tooManyRequestsToCreationToken
                        default:
                            throw ApiError.unknownError
                        }
                    } else {
                        DispatchQueue.main.async {
                            completionHandler(json, nil)
                        }
                    }
                } catch {
                    throw ApiError.invalidJson
                }
            } catch let error {
                let error = error as! ApiError

                switch action {
                case .search, .getPopular, .getPopularForWeek, .getCategories:
                    DispatchQueue.main.async {
                        ControllerManager.instance.searchTableViewController.showPlaceholderView(
                            PlaceholderView(
                                viewController: ControllerManager.instance.searchTableViewController,
                                title: error.description().title,
                                subtitle: error.description().detail,
                                buttonText: "Повторить попытку"
                            ) {
                                self.executeAction(action, urlString: urlString, completionHandler:
                                    completionHandler)
                            }
                        )
                    }
                case .getFavorites, .addBookToFavorites, .deleteBookFromFavorites, .deleteAllBooksFromFavorites:
                    DispatchQueue.main.async {
                        completionHandler(nil, error)
                    }
                case .signIn:
                    ControllerManager.instance.menuTableViewController.vkLogInFailed()
                default:
                    break
                }
            }
        })

        switch action {
        case .search, .getPopular, .getPopularForWeek, .getCategories:
            searchDataTask?.cancel()
            searchDataTask = task
        case .getFavorites, .addBookToFavorites, .deleteBookFromFavorites, .deleteAllBooksFromFavorites:
            favoritesDataTask?.cancel()
            favoritesDataTask = task
        case .signIn, .logOut:
            accountDataTask?.cancel()
            accountDataTask = task
        }

        task.resume()
    }

    private func formattedStringWithAuthors(_ authors: [String]) -> String {
        var result = authors.joined(separator: "|")
        let from = [" ", "|", ".", "\u{00a0}\u{00a0}", ".\u{00a0},"]
        let to = ["\u{00a0}", ", ", ".\u{00a0}", "\u{00a0}", ".,"]

        for i in 0...4 {
            result = result.replacingOccurrences(of: from[i], with: to[i], options: .literal, range: nil)
        }

        return result
    }

    private func formattedStringWithFileSize(_ fileSize: String) -> String {
        var result = fileSize
        let from = ["Mb", "Kb"]
        let to = ["\u{00a0}МБ", "\u{00a0}КБ"]

        for i in 0...1 {
            result = result.replacingOccurrences(of: from[i], with: to[i], options: .literal, range: nil)
        }

        return result
    }

    private func getReceivedBooksFromItems(_ items: [AnyObject]) -> [Book] {
        var receivedBooks = [Book]()

        for item in items {
            if let authors = item["authors"] as? [String],
                let bigPreviewUrl = item["photo_big"] as? String,
                let category = item["category"] as? [String: AnyObject],
                let categoryId = category["id"] as? Int,
                let downloadUrl = item["download_url"] as? String,
                let fileSize = item["size"] as? String,
                let id = item["id"] as? Int,
                let isMarkedAsFavorite = item["fave"] as? Bool,
                let name = item["name"] as? String,
                let smallPreviewUrl = item["photo_small"] as? String {
                receivedBooks.append(
                    Book(authors: formattedStringWithAuthors(authors), bigPreviewUrl: bigPreviewUrl,
                         categoryId: categoryId, downloadUrl: downloadUrl,
                         fileSize: formattedStringWithFileSize(fileSize), id: id,
                         isMarkedAsFavorite: isMarkedAsFavorite, name: name, smallPreviewUrl: smallPreviewUrl)
                )
            }
        }
        
        return receivedBooks
    }
    
}
