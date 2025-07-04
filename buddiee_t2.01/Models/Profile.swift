//
//  Profile.swift
//  buddiee_t2.01
//
//  Created by 欧柔成 on 04/07/2025.
//

import Foundation

struct Profile: Identifiable, Codable {
    let id: UUID
    let username: String
    let profilePicture: String?
    var bio: String?
    var location: String?
    // Add other properties as needed
}
