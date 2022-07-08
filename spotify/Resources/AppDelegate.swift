//
//  AppDelegate.swift
//  spotify
//
//  Created by Zachary Cummins on 7/7/22.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)

//        UserDefaults.standard.set(nil, forKey: "access_token");
//        UserDefaults.standard.set(nil, forKey: "refresh_token");
//        UserDefaults.standard.set(nil, forKey: "expiration_date");

        if AuthManager.shared.isSignedIn {
            AuthManager.shared.refreshIfNeeded(completion: nil)
            window.rootViewController = TabBarViewController()
        } else {
            let navVC = UINavigationController(rootViewController: WelcomeViewController())

            navVC.navigationBar.prefersLargeTitles = true
            navVC.viewControllers.first?.navigationItem.largeTitleDisplayMode = .always

            window.rootViewController = navVC
        }

        window.makeKeyAndVisible()
        self.window = window

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options _: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_: UIApplication, didDiscardSceneSessions _: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}
