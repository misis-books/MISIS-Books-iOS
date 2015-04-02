//
//  VkAuthorizationViewController.swift
//  misisbooks
//
//  Created by Maxim Loskov on 27.01.15.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit

protocol VkAuthorizationViewControllerDelegate {
    
    func vkAuthorizationViewControllerLogInSucceeded(vkAccessToken: String, vkUserId: String)
    func vkAuthorizationViewControllerLogInFailed()
}

/// Контроллер для авторизации через ВКонтакте
class VkAuthorizationViewController : UIViewController, UIWebViewDelegate {
    
    /// Делегат
    var delegate : VkAuthorizationViewControllerDelegate!
    
    /// Индикатор активности
    var activityIndicatorView : UIActivityIndicatorView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let closeBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "Close"),
            style: .Plain,
            target: self,
            action: Selector("closeButtonPressed")
        )
        navigationItem.setRightBarButtonItem(closeBarButtonItem, animated: false)
        
        title = "Вход через ВКонтакте"
        
        let webView = UIWebView(frame: view.bounds)
        webView.backgroundColor = UIColor(red: 241 / 255.0, green: 239 / 255.0, blue: 237 / 255.0, alpha: 1.0)
        webView.delegate = self
        view.addSubview(webView)
        
        activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        activityIndicatorView.center = view.center
        view.addSubview(activityIndicatorView)
        
        let parameters = [
            "client_id=4720039",
            "display=mobile",
            "redirect_uri=https://oauth.vk.com/blank.html",
            "response_type=token",
            "revoke=1",
            "v=5.29"
        ]
        let urlString = "https://oauth.vk.com/authorize?" + join("&", parameters)
        
        webView.loadRequest(NSURLRequest(URL: NSURL(string: urlString)!))
    }
    
    /// MARK: - Вспомогательные методы
    
    /// Обрабатывает событие, когда нажата кнопка закрытия
    func closeButtonPressed() {
        delegate.vkAuthorizationViewControllerLogInFailed()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    /// MARK: - Методы UIWebViewDelegate
    
    func webViewDidStartLoad(webView: UIWebView!) {
        activityIndicatorView.startAnimating()
    }
    
    func webViewDidFinishLoad(webView: UIWebView!) {
        activityIndicatorView.stopAnimating()
        
        let urlString = webView.request!.mainDocumentURL!.absoluteString!
        let urlParts = split(urlString) { $0 == "#" }
        
        if urlParts.count == 2 {
            var parametersDictionary = [String: String]()
            let parameters = split(urlParts[1]) { $0 == "&" }
            
            for parameter in parameters {
                let keyAndValue = split(parameter) { $0 == "=" }
                
                if keyAndValue.count == 2 {
                    parametersDictionary[keyAndValue[0]] = keyAndValue[1]
                }
            }
            
            if let vkAccessToken = parametersDictionary["access_token"] {
                if let vkUserId = parametersDictionary["user_id"] {
                    delegate.vkAuthorizationViewControllerLogInSucceeded(vkAccessToken, vkUserId: vkUserId)
                } else {
                    delegate.vkAuthorizationViewControllerLogInFailed()
                }
            } else {
                delegate.vkAuthorizationViewControllerLogInFailed()
            }
            
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        activityIndicatorView.stopAnimating()
        
        let errorLabel = UILabel(frame: CGRectZero)
        errorLabel.font = UIFont(name: "HelveticaNeue", size: 14.0)
        errorLabel.text = "Невозможно загрузить страницу"
        errorLabel.textColor = UIColor.blackColor()
        errorLabel.sizeToFit()
        errorLabel.center = view.center
        view.addSubview(errorLabel)
    }
}
