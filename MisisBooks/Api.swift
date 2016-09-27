//
//  Api.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 06.12.14.
//  Copyright (c) 2016 Maxim Loskov. All rights reserved.
//

import Foundation

enum ApiError: Error {
    case jsonDataNotParsed
    case invalidServerResponse
    case serverError(statusCode: Int)
    case invalidJsonData
    case notConnectedToInternet
    case timedOut
    case notConnected
    case noSubscription
    case tooManyRequests
    case missingAccessToken
    case invalidVkAccessToken
    case tooManyAuthorizationRequests
    case unknownError

    var description: String {
        switch self {
        case .jsonDataNotParsed:
            return "Не удалось разобрать данные JSON."
        case .invalidServerResponse:
            return "Неправильный ответ сервера."
        case .serverError(let statusCode):
            return "Ошибка сервера: \(statusCode)."
        case .invalidJsonData:
            return "Неправильные данные JSON."
        case .notConnectedToInternet:
            return "Отсутствует подключение к Интернету."
        case .timedOut:
            return "Истекло время ожидания ответа сервера."
        case .notConnected:
            return "Не удалось подлючиться к серверу."
        case .noSubscription:
            return "Вы не оформили подписку."
        case .tooManyRequests:
            return "Слишком много запросов."
        case .missingAccessToken:
            return "Отсутствует маркер доступа."
        case .invalidVkAccessToken:
            return "Авторизация через ВКонтакте отклонена."
        case .tooManyAuthorizationRequests:
            return "Слишком много запросов на авторизацию."
        case .unknownError:
            return "Неизвестная приложению ошибка."
        }
    }
}

enum ApiResult {
    case success([String: AnyObject])
    case failure(ApiError)
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

    func getPopularBooks(byCategoryId categoryId: Int, count: Int, failure: @escaping (_ error: ApiError) -> (),
                         success: @escaping (_ receivedBooks: [Book], _ totalResults: Int) -> ()) {
        guard let accessToken = Api.instance.accessToken else {
            signIn {
                self.getPopularBooks(byCategoryId: categoryId, count: count, failure: failure, success: success)
            }

            return
        }

        let parameters = [
            "access_token=\(accessToken)",
            "category=\(categoryId)",
            "count=\(count)",
            "fields=all"
        ]
        let urlString = "\(baseUrlString)/materials.getPopular?" + parameters.joined(separator: "&")
        executeTask(withUrlString: urlString) { result in
            switch result {
            case .success(let json):
                if let response = json["response"] as? [String: AnyObject],
                    let items = response["items"] as? [AnyObject],
                    let totalResults = response["all_items_count"] as? Int {
                    success(self.extractBooks(fromItems: items), totalResults)
                } else {
                    failure(.jsonDataNotParsed)
                }
            case .failure(let error):
                failure(error)
            }
        }
    }

    func getPopularBooksForWeek(byCategoryId categoryId: Int, count: Int, failure: @escaping (_ error: ApiError) -> (),
                                success: @escaping (_ receivedBooks: [Book], _ totalResults: Int) -> ()) {
        guard let accessToken = Api.instance.accessToken else {
            signIn {
                self.getPopularBooksForWeek(byCategoryId: categoryId, count: count, failure: failure, success: success)
            }

            return
        }

        let parameters = [
            "access_token=\(accessToken)",
            "category=\(categoryId)",
            "count=\(count)",
            "fields=all"
        ]
        let urlString = "\(baseUrlString)/materials.getPopularForWeek?" + parameters.joined(separator: "&")
        executeTask(withUrlString: urlString) { result in
            switch result {
            case .success(let json):
                if let response = json["response"] as? [String: AnyObject],
                    let items = response["items"] as? [AnyObject],
                    let totalResults = response["all_items_count"] as? Int {
                    success(self.extractBooks(fromItems: items), totalResults)
                } else {
                    failure(.jsonDataNotParsed)
                }
            case .failure(let error):
                failure(error)
            }
        }
    }

    func searchBooks(byQuery query: String, count: Int, offset: Int, categoryId: Int,
                     failure: @escaping (_ error: ApiError) -> (),
                     success: @escaping (_ receivedBooks: [Book], _ totalResults: Int) -> ()) {
        guard let accessToken = Api.instance.accessToken else {
            signIn {
                self.searchBooks(byQuery: query, count: count, offset: offset, categoryId: categoryId, failure: failure,
                                 success: success)
            }

            return
        }

        let parameters = [
            "access_token=\(accessToken)",
            "category=\(categoryId)",
            "count=\(count)",
            "fields=all",
            "offset=\(offset)",
            "q=\(query.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)"
        ]
        let urlString = "\(baseUrlString)/materials.search?" + parameters.joined(separator: "&")
        executeTask(withUrlString: urlString) { result in
            switch result {
            case .success(let json):
                if let response = json["response"] as? [String: AnyObject],
                    let items = response["items"] as? [AnyObject],
                    let totalResults = response["all_items_count"] as? Int {
                    success(self.extractBooks(fromItems: items), totalResults)
                } else {
                    failure(.jsonDataNotParsed)
                }
            case .failure(let error):
                failure(error)
            }
        }
    }

    func addBookToFavorites(_ book: Book, failure: @escaping (_ error: ApiError) -> (),
                            success: @escaping (_ result: Bool) -> ()) {
        guard let accessToken = Api.instance.accessToken else {
            signIn {
                self.addBookToFavorites(book, failure: failure, success: success)
            }

            return
        }

        let parameters = [
            "access_token=\(accessToken)",
            "edition_id=\(book.id)"
        ]
        let urlString = "\(baseUrlString)/fave.addDocument?" + parameters.joined(separator: "&")
        executeTask(withUrlString: urlString) { result in
            switch result {
            case .success(let json):
                if let response = json["response"] as? [String: AnyObject],
                    let result = response["result"] as? Bool {
                    success(result)
                } else {
                    failure(.jsonDataNotParsed)
                }
            case .failure(let error):
                failure(error)
            }
        }
    }

    func getFavorites(byCount count: Int, offset: Int, failure: @escaping (_ error: ApiError) -> (),
                      success: @escaping (_ receivedBooks: [Book], _ totalResults: Int) -> ()) {
        guard let accessToken = Api.instance.accessToken else {
            signIn {
                self.getFavorites(byCount: count, offset: offset, failure: failure, success: success)
            }

            return
        }

        let parameters = [
            "access_token=\(accessToken)",
            "count=\(count)",
            "fields=all",
            "offset=\(offset)"
        ]
        let urlString = "\(baseUrlString)/fave.getDocuments?" + parameters.joined(separator: "&")
        executeTask(withUrlString: urlString) { result in
            switch result {
            case .success(let json):
                if let response = json["response"] as? [String: AnyObject],
                    let items = response["items"] as? [AnyObject],
                    let totalResults = response["all_items_count"] as? Int {
                    success(self.extractBooks(fromItems: items), totalResults)
                } else {
                    failure(.jsonDataNotParsed)
                }
            case .failure(let error):
                failure(error)
            }
        }
    }

    func deleteAllBooksFromFavorites(failure: @escaping (_ error: ApiError) -> (),
                                     success: @escaping (_ result: Bool) -> ()) {
        guard let accessToken = Api.instance.accessToken else {
            signIn {
                self.deleteAllBooksFromFavorites(failure: failure, success: success)
            }

            return
        }

        let urlString = "\(baseUrlString)/fave.deleteAllDocuments?access_token=\(accessToken)"
        executeTask(withUrlString: urlString) { result in
            switch result {
            case .success(let json):
                if let response = json["response"] as? [String: AnyObject],
                    let result = response["result"] as? Bool {
                    success(result)
                } else {
                    failure(.jsonDataNotParsed)
                }
            case .failure(let error):
                failure(error)
            }
        }
    }

    func deleteBooksFromFavorites(_ books: [Book], failure: @escaping (_ error: ApiError) -> (),
                                  success: @escaping (_ result: Bool) -> ()) {
        guard let accessToken = Api.instance.accessToken else {
            signIn {
                self.deleteBooksFromFavorites(books, failure: failure, success: success)
            }

            return
        }

        let parameters = [
            "access_token=\(accessToken)",
            "edition_id=\(books.map { "\($0.id)" }.joined(separator: ","))"
        ]
        let urlString = "\(baseUrlString)/fave.deleteDocument?" + parameters.joined(separator: "&")
        executeTask(withUrlString: urlString) { result in
            switch result {
            case .success(let json):
                if let response = json["response"] as? [String: AnyObject],
                    let result = response["result"] as? Bool {
                    success(result)
                } else {
                    failure(.jsonDataNotParsed)
                }
            case .failure(let error):
                failure(error)
            }
        }
    }

    func signIn(_ completion: @escaping () -> ()) {
        guard let vkAccessToken = vkAccessToken else {
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

            return
        }

        let urlString = "\(baseUrlString)/auth.signin?vk_access_token=\(vkAccessToken)"
        executeTask(withUrlString: urlString) { result in
            var apiError: ApiError? = nil

            switch result {
            case .success(let json):
                if let response = json["response"] as? [String: AnyObject],
                    let accessToken = response["access_token"] as? String {
                    print("Маркер доступа получен: \(accessToken)")

                    let standardUserDefaults = UserDefaults.standard
                    standardUserDefaults.set(accessToken, forKey: "accessToken")
                    standardUserDefaults.synchronize()
                    self.accessToken = accessToken

                    ControllerManager.instance.menuTableViewController.updateTableHeaderView()

                    completion()
                } else {
                    apiError = .jsonDataNotParsed
                }
            case .failure(let error):
                apiError = error
            }

            if let apiError = apiError {
                PopUpMessage(title: "Ошибка", subtitle: apiError.description).show()
                ControllerManager.instance.menuTableViewController.vkLogInFailed()
            }
        }
    }

    private func executeTask(withUrlString urlString: String, completion: @escaping (_ result: ApiResult) -> ()) {
        print("Запрос по URL: \(urlString)")

        let url = URL(string: urlString)!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                let apiError: ApiError

                switch error._code {
                case -1009: // NSURLErrorNotConnectedToInternet
                    apiError = .notConnectedToInternet
                case -1001: // NSURLErrorTimedOut
                    apiError = .timedOut
                default:
                    apiError = .notConnected
                }

                DispatchQueue.main.async {
                    completion(.failure(apiError))
                }

                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidServerResponse))
                }

                return
            }

            guard 200...299 ~= httpResponse.statusCode else {
                DispatchQueue.main.async {
                    completion(.failure(.serverError(statusCode: httpResponse.statusCode)))
                }

                return
            }

            guard let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                    as! [String: AnyObject] else {
                        DispatchQueue.main.async {
                            completion(.failure(.invalidJsonData))
                        }

                        return
            }

            if let error = json["error"] as? [String: AnyObject],
                let errorCode = error["error_code"] as? Int {
                var apiError: ApiError? = nil

                switch errorCode {
                case 2:
                    apiError = .noSubscription
                case 3:
                    apiError = .tooManyRequests
                case 4:
                    self.signIn {
                        self.executeTask(withUrlString: urlString, completion: completion)
                    }
                case 5:
                    apiError = .missingAccessToken
                case 6:
                    apiError = .invalidVkAccessToken
                case 7:
                    apiError = .tooManyAuthorizationRequests
                default:
                    apiError = .unknownError
                }

                if let apiError = apiError {
                    DispatchQueue.main.async {
                        completion(.failure(apiError))
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(.success(json))
                }
            }
        }
        task.resume()
    }



    private func formattedString(withAuthors authors: [String]) -> String {
        var result = authors.joined(separator: "|")
        let from = [" ", "|", ".", "\u{00a0}\u{00a0}", ".\u{00a0},"]
        let to = ["\u{00a0}", ", ", ".\u{00a0}", "\u{00a0}", ".,"]

        for i in 0...4 {
            result = result.replacingOccurrences(of: from[i], with: to[i], options: .literal, range: nil)
        }

        return result
    }

    private func formattedString(withFileSize fileSize: String) -> String {
        var result = fileSize
        let from = ["Mb", "Kb"]
        let to = ["\u{00a0}МБ", "\u{00a0}КБ"]

        for i in 0...1 {
            result = result.replacingOccurrences(of: from[i], with: to[i], options: .literal, range: nil)
        }

        return result
    }

    private func extractBooks(fromItems items: [AnyObject]) -> [Book] {
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
                    Book(
                        authors: formattedString(withAuthors: authors),
                        bigPreviewUrl: bigPreviewUrl,
                        categoryId: categoryId,
                        downloadUrl: downloadUrl,
                        fileSize: formattedString(withFileSize: fileSize),
                        id: id,
                        isMarkedAsFavorite: isMarkedAsFavorite,
                        name: name,
                        smallPreviewUrl: smallPreviewUrl
                    )
                )
            }
        }
        
        return receivedBooks
    }
}
