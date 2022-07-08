//
//  Playlist.swift
//  spotify
//
//  Created by Zachary Cummins on 7/7/22.
//

import Foundation

struct Playlist: Codable {
    let description: String
    let external_urls: [String: String]
    let id: String
    let images: [APIImage]
    let name: String
    let owner: PlaylistOwner
}

struct PlaylistOwner: Codable {
    let display_name: String
    let external_urls: [String: String]
    let id: String
}
