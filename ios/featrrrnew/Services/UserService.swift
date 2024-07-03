//
//  MessageUserService.swift
//  featrrrnew
//
//  Created by Buddie Booking on 8/10/23.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

class UserService {
    
    public static let shared = UserService()
    
    @Published var currentUser: User?
    
    @MainActor
    func fetchCurrentUser() async throws -> User? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
        let user = try snapshot.data(as: User.self)
        self.currentUser = user
        return user
    }
    
    static func buildAnonymousUser(withUid uid: String) -> User {
        return User(uid: uid)
    }
    static func fetchUser(withUid uid: String) async throws -> User {
        print(uid)
        let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
        return try snapshot.data(as: User.self)
    }
    static func addFCMTokenUser(withUid uid: String, fcmToken fcm: String) async throws{
        let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
        let user = try snapshot.data(as: User.self)
        if var tokens = user.fcmTokens {
            let containsFCMToken = tokens.contains(where: { s in
                return s == fcm
            })
            if !containsFCMToken {
                tokens.append(fcm)
            }
            try await Firestore.firestore().collection("users").document(uid).updateData(["fcmTokens": tokens])
        } else {
            try await Firestore.firestore().collection("users").document(uid).updateData(["fcmTokens": [fcm]])
        }
        
    }
    
    static func removeFCMTokenUser(withUid uid: String, fcmToken fcm: String) async throws{
        let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
        let user = try snapshot.data(as: User.self)
        if var tokens = user.fcmTokens {
            for token in tokens.filter({ $0 == fcm }) {
                tokens.remove(token)
            }
            try await Firestore.firestore().collection("users").document(uid).updateData(["fcmTokens": tokens])
        }
        
    }
   static func fetchAllUsers() async throws -> [User] {
        let snapshot = try await Firestore.firestore().collection("users").getDocuments()
       return snapshot.documents.compactMap({try? $0.data(as: User.self)})
    }
    
    static func fetchesUser(withUid uid: String, completion: @escaping(User) -> Void) {
        COLLECTION_USERS.document(uid).getDocument { snapshot, _ in
            guard let user = try? snapshot?.data(as: User.self) else {return}
            completion(user)
        }
    }
}

// VLR2rla8l9hg07o9RF3JPymXQ0I2
//
