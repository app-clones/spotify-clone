//
//  AuthViewController.swift
//  spotify
//
//  Created by Zachary Cummins on 7/7/22.
//

import UIKit
import WebKit

class AuthViewController: UIViewController, WKNavigationDelegate {
    // MARK: - Public Variables

    public var completionHandler: ((Bool) -> Void)?

    // MARK: - Private Variables

    private let webView: WKWebView = {
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true

        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = prefs

        let webView = WKWebView(frame: .zero, configuration: config)

        return webView
    }()

    // MARK: - Private Functions

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sign In"

        view.backgroundColor = .systemBackground
        webView.navigationDelegate = self
        view.addSubview(webView)

        guard let url = AuthManager.shared.signInURL else {
            return
        }
        webView.load(URLRequest(url: url))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        webView.frame = view.bounds
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
        guard let url = webView.url else {
            return
        }
        // Exchange the code for access token
        guard let code = URLComponents(string: url.absoluteString)?.queryItems?.first(where: { $0.name == "code" })?.value else {
            return
        }
        webView.isHidden = true

        print("Code: \(code)")
        AuthManager.shared.exchangeCodeForToken(code: code, completion: { [weak self] success in
            DispatchQueue.main.async {
                self?.navigationController?.popToRootViewController(animated: true)
                self?.completionHandler?(success)
            }
        })
    }
}
