//
//  VkAuthorizationViewController.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 27.01.15.
//  Copyright (c) 2016 Maxim Loskov. All rights reserved.
//

import UIKit

class VkAuthorizationViewController: UIViewController, UIWebViewDelegate {
    private var activityIndicatorView: UIActivityIndicatorView!
    private var webView: UIWebView!
    private var errorLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "Close"),
            style: .plain,
            target: self,
            action: #selector(closeButtonPressed)
        )

        title = "Вход через ВКонтакте"

        webView = UIWebView(frame: view.bounds)
        webView.backgroundColor = UIColor(red: 241 / 255.0, green: 239 / 255.0, blue: 237 / 255.0, alpha: 1)
        webView.delegate = self
        view.addSubview(webView)

        activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityIndicatorView.center = view.center
        view.addSubview(activityIndicatorView)

        let parameters = [
            "client_id=4720039",
            "display=mobile",
            "redirect_uri=https://oauth.vk.com/blank.html",
            "response_type=token",
            "revoke=1",
            "scope=offline"
        ]
        let urlString = "https://oauth.vk.com/authorize?" + parameters.joined(separator: "&")

        webView.loadRequest(URLRequest(url: URL(string: urlString)!))
    }

    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        errorLabel?.center = view.center
        webView.frame = view.bounds
    }

    func closeButtonPressed() {
        ControllerManager.instance.menuTableViewController.vkLogInFailed()
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Методы UIWebViewDelegate

    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        activityIndicatorView.stopAnimating()
        webView.scrollView.isScrollEnabled = false

        errorLabel = UILabel()
        errorLabel.font = UIFont(name: "HelveticaNeue-Light", size: 14)
        errorLabel.lineBreakMode = .byWordWrapping
        errorLabel.numberOfLines = 0
        errorLabel.text = "Невозможно загрузить страницу.\nПроверьте соединение с Интернетом."
        errorLabel.textAlignment = .center
        errorLabel.textColor = .black
        errorLabel.sizeToFit()
        errorLabel.center = view.center
        view.addSubview(errorLabel)
    }

    func webViewDidStartLoad(_ webView: UIWebView) {
        activityIndicatorView.startAnimating()
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        activityIndicatorView.stopAnimating()

        let urlString = webView.request!.mainDocumentURL!.absoluteString
        print("Открыта страница: \(urlString)")

        let urlParts = urlString.characters.split { $0 == "#" }.map { "\($0)" }

        if urlParts.count == 2 {
            var parametersDictionary = [String: String]()
            let parameters = urlParts[1].characters.split { $0 == "&" }.map { "\($0)" }

            for parameter in parameters {
                let parts = parameter.characters.split { $0 == "=" }.map { "\($0)" }

                if parts.count == 2 {
                    parametersDictionary[parts[0]] = parts[1]
                }
            }

            if let vkAccessToken = parametersDictionary["access_token"],
                let vkUserId = parametersDictionary["user_id"] {
                ControllerManager.instance.menuTableViewController
                    .vkLogInSucceededWithVkAccessToken(vkAccessToken, vkUserId: vkUserId)
            } else {
                ControllerManager.instance.menuTableViewController.vkLogInFailed()
            }
            
            dismiss(animated: true, completion: nil)
        }
    }
}
