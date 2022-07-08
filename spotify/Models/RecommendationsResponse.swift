//
//  RecommendationsResponse.swift
//  spotify
//
//  Created by Zachary Cummins on 7/8/22.
//

import Foundation

struct RecommendationsResponse: Codable {
    let tracks: [AudioTrack]
}
