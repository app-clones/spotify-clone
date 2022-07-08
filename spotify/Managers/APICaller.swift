//
//  APICaller.swift
//  spotify
//
//  Created by Zachary Cummins on 7/7/22.
//

import Foundation

final class APICaller {
    static let shared = APICaller()

    enum Constants {
        static let baseAPIUrl = "https://api.spotify.com/v1"
    }

    enum APIError: Error {
        case failedToGetData
    }

    private init() {}

    public func getCurrentUserProfile(completion: @escaping (Result<UserProfile, Error>) -> Void) {
        createRequest(
            with: URL(string: Constants.baseAPIUrl + "/me"),
            type: .GET
        ) { baseRequest in
            let task = URLSession.shared.dataTask(with: baseRequest) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }

                do {
                    let result = try JSONDecoder().decode(UserProfile.self, from: data)
                    completion(.success(result))
                } catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }

    // MARK: - Private

    enum HTTPMethod: String {
        case GET
        case POST
    }

    private func createRequest(
        with url: URL?,
        type: HTTPMethod,
        completion: @escaping (URLRequest) -> Void
    ) {
        AuthManager.shared.withValidToken { token in
            guard let apiURL = url else {
                return
            }

            var request = URLRequest(url: apiURL)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpMethod = type.rawValue
            request.timeoutInterval = 03
            completion(request)
        }
    }
}
