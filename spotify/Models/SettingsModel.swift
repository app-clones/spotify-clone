//
//  SettingsModel.swift
//  spotify
//
//  Created by Zachary Cummins on 7/7/22.
//

import Foundation

struct Section {
    let title: String
    let options: [Option]
}

struct Option {
    let title: String
    let handler: () -> Void
}
