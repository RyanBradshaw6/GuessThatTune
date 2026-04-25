//
//  Category.swift
//  GuessThatTune
//
//  Created by Ryan Bradshaw on 4/24/26.
//

import Foundation

struct Category: Identifiable {
    let id = UUID()
    let name: String
    let playlistID: String
}
