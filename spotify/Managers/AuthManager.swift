//
//  Auth.swift
//  spotify
//
//  Created by Zachary Cummins on 7/7/22.
//

import Foundation

final class AuthManager {
    // MARK: - Public Variables

    static let shared = AuthManager()

    enum Constants {
        static let clientId = "487fd136ed604a66af0f91a5cb21f369"
        static let clientSecret = "b6f89965129c4a0ba0ada25a93b1a00e"
        static let tokenAPIUrl = "https://accounts.spotify.com/api/token"
        static let redirectURI = "https://iosacademy.io"
        static let scopes = "user-read-private%20playlist-modify-public%20playlist-modify-private%20playlist-read-private%20user-follow-read%20user-library-modify%20user-library-read%20user-read-email"
    }

    public var signInURL: URL? {
        let base = "https://accounts.spotify.com/authorize"

        let string = "\(base)?response_type=code&client_id=\(Constants.clientId)&scope=\(Constants.scopes)&redirect_uri=\(Constants.redirectURI)&show_dialog=TRUE"

        return URL(string: string)
    }

    // MARK: - Private Variables

    private var refreshingToken = false

    private var onRefreshBlocks = [(String) -> Void]()

    var isSignedIn: Bool {
        return accessToken != nil
    }

    private var accessToken: String? {
        return UserDefaults.standard.string(forKey: "access_token")
    }

    private var refreshToken: String? {
        return UserDefaults.standard.string(forKey: "refresh_token")
    }

    private var tokenExpirationDate: Date? {
        return UserDefaults.standard.object(forKey: "expiration_date") as? Date
    }

    private init() {}

    // MARK: - Public

    public func exchangeCodeForToken(code: String, completion: @escaping ((Bool) -> Void)) {
        // Get token
        guard let url = URL(string: Constants.tokenAPIUrl) else {
            return
        }

        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type",
                         value: "authorization_code"),
            URLQueryItem(name: "code",
                         value: code),
            URLQueryItem(name: "redirect_uri",
                         value: Constants.redirectURI),
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = components.query?.data(using: .utf8)

        let basicToken = Constants.clientId + ":" + Constants.clientSecret
        let data = basicToken.data(using: .utf8)
        guard let base64String = data?.base64EncodedString() else {
            print("Failed to get Base64")
            completion(false)
            return
        }

        request.setValue("Basic \(base64String)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                completion(false)
                return
            }

            do {
                let result = try JSONDecoder().decode(AuthResponse.self, from: data)
                self?.cacheToken(result: result)

                completion(true)
            } catch {
                print(error.localizedDescription)
                completion(false)
            }
        }
        task.resume()
    }

    /// Supplies valid token to be used with API Calls
    public func withValidToken(completion: @escaping (String) -> Void) {
        guard !refreshingToken else {
            // Append the completion
            onRefreshBlocks.append(completion)
            return
        }

        if shouldRefreshToken {
            refreshIfNeeded { [weak self] success in
                if let token = self?.accessToken, success {
                    completion(token)
                }
            }
        } else if let token = accessToken {
            completion(token)
        }
    }

    public func refreshIfNeeded(completion: @escaping (Bool) -> Void) {
        guard !refreshingToken else {
            return
        }

        guard shouldRefreshToken else {
            completion(true)
            return
        }

        guard let refreshToken = refreshToken else {
            return
        }

        // Refresh the token
        guard let url = URL(string: Constants.tokenAPIUrl) else {
            return
        }

        refreshingToken = true

        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type",
                         value: "refresh_token"),
            URLQueryItem(name: "refresh_token",
                         value: refreshToken),
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = components.query?.data(using: .utf8)

        let basicToken = Constants.clientId + ":" + Constants.clientSecret
        let data = basicToken.data(using: .utf8)
        guard let base64String = data?.base64EncodedString() else {
            print("Failed to get Base64")
            completion(false)
            return
        }

        request.setValue("Basic \(base64String)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            self?.refreshingToken = false
            guard let data = data, error == nil else {
                completion(false)
                return
            }

            do {
                let result = try JSONDecoder().decode(AuthResponse.self, from: data)

                self?.onRefreshBlocks.forEach { $0(result.access_token) }
                self?.onRefreshBlocks.removeAll()
                self?.cacheToken(result: result)

                completion(true)
            } catch {
                print(error.localizedDescription)
                completion(false)
            }
        }
        task.resume()
    }

    // MARK: - Private Functions

    private func cacheToken(result: AuthResponse) {
        UserDefaults.standard.setValue(result.access_token, forKey: "access_token")

        if let refresh_token = result.refresh_token {
            UserDefaults.standard.setValue(refresh_token, forKey: "refresh_token")
        }

        UserDefaults.standard.setValue(Date().addingTimeInterval(TimeInterval(result.expires_in)),
                                       forKey: "expiration_date")
    }

    private var shouldRefreshToken: Bool {
        guard let expirationDate = tokenExpirationDate else {
            return false
        }

        let currentDate = Date()
        let fiveMinutes: TimeInterval = 300

        return currentDate.addingTimeInterval(fiveMinutes) >= expirationDate
    }
}
