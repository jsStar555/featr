//
//  User.swift
//  featrrrnew
//
//  Created by Buddie Booking on 6/29/23.
//

import Foundation
import FirebaseFirestoreSwift
import Firebase


// Regenerated with help from ChatGPT 3.5
struct User: Identifiable, Codable {
    
    @DocumentID var uid: String?
    
    // Allow anonymous users
    private var optionalUsername: String?
    var username: String {
        get {
            return optionalUsername ?? "anonymous"
        }
    }
    let email: String?
    var profileImageUrls: [String] = []
    var fullname: String?
    var bio: String?
    var isFollowed: Bool? = false
    var fcmTokens: [String]?
    
    var isCurrentUser: Bool { return Auth.auth().currentUser?.uid == id }
    var id: String { return uid ?? UUID().uuidString }

    enum CodingKeys: String, CodingKey {
        case uid
        case username
        case email
        case profileImageUrls
        case profileImageUrl //Backwards compatability with single image
        case fullname
        case bio
        case isFollowed
        case fcmTokens
    }
    
    init(uid: String?,
         username: String? = nil,
         email: String? = nil,
         profileImageUrls: [String] = [],
         fullname: String? = nil,
         bio: String? = nil,
         isFollowed: Bool? = nil) {
        
        self.uid = uid
        self.optionalUsername = username
        self.email = email
        self.profileImageUrls = profileImageUrls
        self.fullname = fullname
        self.bio = bio
        self.isFollowed = isFollowed
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _uid = try container.decode(DocumentID<String>.self, forKey: .uid)
        optionalUsername = try container.decode(String.self, forKey: .username)
        email = try container.decode(String.self, forKey: .email)
        
        // Read the image URL!s! first instead of the image URL if it's in use
        if let imageUrls = try container.decodeIfPresent([String].self, forKey: .profileImageUrls) {
            profileImageUrls = imageUrls
        } else if let imageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl) {
            profileImageUrls = [imageUrl]
        } else {
            profileImageUrls = []
        }
        fullname = try container.decodeIfPresent(String.self, forKey: .fullname)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        isFollowed = try container.decodeIfPresent(Bool.self, forKey: .isFollowed) ?? false
        fcmTokens = try container.decodeIfPresent([String].self, forKey: .fcmTokens)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(uid, forKey: .uid)
        try container.encodeIfPresent(username, forKey: .username)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(profileImageUrls, forKey: .profileImageUrls)
        try container.encodeIfPresent(fullname, forKey: .fullname)
        try container.encodeIfPresent(bio, forKey: .bio)
        try container.encodeIfPresent(isFollowed, forKey: .isFollowed)
        try container.encodeIfPresent(fcmTokens, forKey: .fcmTokens)
    }
}

extension User: Hashable {
    var identifier: String { return id }
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(identifier)
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}
