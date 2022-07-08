//
//  Artist.swift
//  spotify
//
//  Created by Zachary Cummins on 7/7/22.
//

import Foundation

struct Artist: Codable {
    let id: String
    let name: String
    let type: String
    let external_urls: [String: String]
}
