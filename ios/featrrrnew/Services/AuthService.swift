//
//  AuthService.swift
//  featrrrnew
//
//  Created by Buddie Booking on 7/25/23.
//

import Foundation
import Firebase


class AuthService: ObservableObject {
    @Published var user: User?
    @Published var userSession: FirebaseAuth.User?
    @Published var errorMessage = ""
    
    static let shared = AuthService()
    
    init() {
        Task { try await loadUserData() }

    }
    
    @MainActor
    func loginAnonymous() async throws {
        
            let result = try await Auth.auth().signInAnonymously()
            self.userSession = result.user
            self.user = UserService.buildAnonymousUser(withUid: result.user.uid)
       
    }
    @MainActor
    func login(withEmail email: String, password: String) async throws {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            self.user = try await UserService.fetchUser(withUid: result.user.uid)
        // Write the FCM token to Firebase on login
        
        if let token = Messaging.messaging().fcmToken {
            try await UserService.addFCMTokenUser(withUid: result.user.uid, fcmToken: token)
        } else {
            //TODO: Catch error
        }
       
            await try loadUserData()
    }
    
    @MainActor
    func createUser(email: String, password: String, username: String, fullname: String, connectAccountId: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user
            
            
            let data: [String: Any] = [
                "email": email,
                "username": username,
                "fullname": fullname,
                "connectAccountId": connectAccountId,
                "id": result.user.uid
            ]
            
            try await COLLECTION_USERS.document(result.user.uid).setData(data)
            self.user = try await UserService.fetchUser(withUid: result.user.uid)
            try await self.loadUserData()
        } catch {
            Log.d("Failed to create user with error: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func loadUserData() async throws {
        userSession = Auth.auth().currentUser
        do {
            if let session = userSession {
                self.user = try await UserService.fetchUser(withUid: session.uid)
            }
        } catch {
            print(error)
        }
    }
    
    func signout() async throws {
        if let token = Messaging.messaging().fcmToken, let uid = Auth.auth().currentUser?.uid {
            try await UserService.removeFCMTokenUser(withUid: uid, fcmToken: token)
        } else {
            //TODO: catch and output error
        }
        
        self.userSession = nil
        self.user = nil
        try Auth.auth().signOut()
        InboxService.shared.reset()
        
        try await Messaging.messaging().deleteToken()
        try await Messaging.messaging().token()

    }
    
    func resetPassword(withEmail email: String, completion: @escaping (Result<Bool, Error>) -> ()) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                Log.d("Failed to send link with error \(error.localizedDescription)")
                completion(.failure(error))
            }
            completion(.success(true))
           
        }
    }
   
}

