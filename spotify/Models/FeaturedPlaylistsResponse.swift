//
//  FeaturedPlaylistResponse.swift
//  spotify
//
//  Created by Zachary Cummins on 7/8/22.
//

import Foundation

struct FeaturedPlaylistsResponse: Codable {
    let playlists: PlaylistResponse
}

struct PlaylistResponse: Codable {
    let items: [Playlist]
}
