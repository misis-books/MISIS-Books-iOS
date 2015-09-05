//
//  VkAuthorizationViewController.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 27.01.15.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit

/**
    Класс для представления контроллера авторизации через ВКонтакте
*/
class VkAuthorizationViewController: UIViewController, UIWebViewDelegate {
    
    /// Индикатор активности
    private var activityIndicatorView: UIActivityIndicatorView!
    
    /// Веб-страница
    private var webView: UIWebView!

    /// Поле с ошибкой соединения
    private var errorLabel: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Close"), style: .Plain, target: self,
            action: "closeButtonPressed")
        
        title = "Вход через ВКонтакте"
        
        webView = UIWebView(frame: view.bounds)
        webView.backgroundColor = UIColor(red: 241 / 255.0, green: 239 / 255.0, blue: 237 / 255.0, alpha: 1)
        webView.delegate = self
        view.addSubview(webView)
        
        activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        activityIndicatorView.center = view.center
        view.addSubview(activityIndicatorView)
        
        let parameters = ["client_id=4720039", "display=mobile", "redirect_uri=https://oauth.vk.com/blank.html",
            "response_type=token", "revoke=1", "scope=offline"]
        let urlString = "https://oauth.vk.com/authorize?" + "&".join(parameters)

        webView.loadRequest(NSURLRequest(URL: NSURL(string: urlString)!))
    }

    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation,
        duration: NSTimeInterval) {
            errorLabel?.center = view.center
            webView.frame = view.bounds
    }

    /**
        Обрабатывает событие, когда нажата кнопка закрытия
    */
    func closeButtonPressed() {
        ControllerManager.instance.menuTableViewController.vkLogInFailed()
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - Методы UIWebViewDelegate

    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        activityIndicatorView.stopAnimating()
        webView.scrollView.scrollEnabled = false

        errorLabel = UILabel()
        errorLabel!.font = UIFont(name: "HelveticaNeue-Light", size: 14)
        errorLabel!.lineBreakMode = .ByWordWrapping
        errorLabel!.numberOfLines = 0
        errorLabel!.text = "Невозможно загрузить страницу\nПроверьте соединение с Интернетом"
        errorLabel!.textAlignment = .Center
        errorLabel!.textColor = .blackColor()
        errorLabel!.sizeToFit()
        errorLabel!.center = view.center
        view.addSubview(errorLabel!)
    }

    func webViewDidStartLoad(webView: UIWebView) {
        activityIndicatorView.startAnimating()
    }

    func webViewDidFinishLoad(webView: UIWebView) {
        activityIndicatorView.stopAnimating()

        let urlString = webView.request!.mainDocumentURL!.absoluteString
        print("Открыта страница: \(urlString)")

        let urlParts = split(urlString.characters) { $0 == "#" }.map { String($0) }

        if urlParts.count == 2 {
            var parametersDictionary = [String: String]()
            let parameters = split(urlParts[1].characters) { $0 == "&" }.map { String($0) }

            for parameter in parameters {
                let parts = split(parameter.characters) { $0 == "=" }.map { String($0) }
                
                if parts.count == 2 {
                    parametersDictionary[parts[0]] = parts[1]
                }
            }

            if let vkAccessToken = parametersDictionary["access_token"],
                vkUserId = parametersDictionary["user_id"] {
                    ControllerManager.instance.menuTableViewController.vkLogInSucceeded(vkAccessToken: vkAccessToken,
                        vkUserId: vkUserId)
            } else {
                ControllerManager.instance.menuTableViewController.vkLogInFailed()
            }
            
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
}
