//
//  VkLogInViewController.swift
//  misisbooks
//
//  Created by Maxim Loskov on 27.01.15.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit

protocol VkLogInViewControllerDelegate {
    
    func vkLogInViewControllerAuthorizationSucceeded(vkAccessToken: String, vkUserId: String)
    func vkLogInViewControllerAuthorizationFailed()
}

/// Контроллер для авторизации через ВКонтакте
class VkLogInViewController : UIViewController, UIWebViewDelegate {
    
    /// Делегат
    var delegate : VkLogInViewControllerDelegate!
    
    /// Индикатор активности
    var activityIndicatorView : UIActivityIndicatorView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.setRightBarButtonItem(UIBarButtonItem(image: UIImage(named: "Close"), style: UIBarButtonItemStyle.Plain, target: self, action: Selector("closeButtonPressed")), animated: false)
        self.title = "Вход через ВКонтакте"
        
        let webView = UIWebView(frame: self.view.bounds)
        webView.backgroundColor = UIColor(red: 241 / 255.0, green: 239 / 255.0, blue: 237 / 255.0, alpha: 1.0)
        webView.delegate = self
        self.view.addSubview(webView)
        
        activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        activityIndicatorView.center = self.view.center
        self.view.addSubview(activityIndicatorView)
        
        let urlString = "https://oauth.vk.com/authorize?redirect_uri=https://oauth.vk.com/blank.html&display=mobile&response_type=token&client_id=4720039&v=5.27"
        
        webView.loadRequest(NSURLRequest(URL: NSURL(string: urlString)!))
    }
    
    /// MARK: - Вспомогательные методы
    
    /// Обрабатывает событие, когда нажата кнопка закрытия
    func closeButtonPressed() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    /// MARK: - Методы UIWebViewDelegate
    
    func webViewDidStartLoad(webView: UIWebView!) {
        activityIndicatorView.startAnimating()
    }
    
    func webViewDidFinishLoad(webView: UIWebView!) {
        activityIndicatorView.stopAnimating()
        
        let urlString = webView.request!.mainDocumentURL!.absoluteString
        let urlParts = split(urlString!, { $0 == "#" })
        
        if urlParts.count == 2 {
            var parametersDictionary = [String: String]()
            let parameters = split(urlParts[1], { $0 == "&" })
            
            for parameter in parameters {
                let keyAndValue = split(parameter, { $0 == "=" })
                
                if keyAndValue.count == 2 {
                    parametersDictionary[keyAndValue[0]] = keyAndValue[1]
                }
            }
            
            if let vkAccessToken = parametersDictionary["access_token"] {
                if let vkUserId = parametersDictionary["user_id"] {
                    delegate.vkLogInViewControllerAuthorizationSucceeded(vkAccessToken, vkUserId: vkUserId)
                }
            } else {
                delegate.vkLogInViewControllerAuthorizationFailed()
            }
            
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        let errorLabel = UILabel(frame: CGRectZero)
        errorLabel.font = UIFont(name: "HelveticaNeue", size: 14.0)
        errorLabel.text = "Невозможно загрузить страницу"
        errorLabel.textColor = UIColor.blackColor()
        errorLabel.sizeToFit()
        errorLabel.center = self.view.center
        self.view.addSubview(errorLabel)
    }
}