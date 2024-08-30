//
//  LoginViewModel.swift
//  featrrrnew
//
//  Created by Buddie Booking on 7/23/23.
//

import Foundation
import FirebaseAuth

enum LoginState {
    case initial, loading, success, error
}

class LoginViewModel: ObservableObject {
    //@Published var errorMessage = ""
    @Published var email = ""
    @Published var password = ""
    @Published var showAlert = false
    @Published var authError: AuthError?
    @Published var didSendResetPasswordLink: Bool = false
    @Published var state: LoginState = .initial
    
    @MainActor
    func resetPassword(withEmail email: String) {
        AuthService.shared.resetPassword(withEmail: email) { [weak self] result in
            do {
                var sent = try result.get()
                self?.didSendResetPasswordLink = sent
            } catch {
                self?.authError = .unknown
                self?.showAlert = true
            }
        }
    }
    
    @MainActor
    func login(withEmail email: String, password: String) async throws {
        state = .loading
        do {
            try await AuthService.shared.login(withEmail: email, password: password)
            state = .success
        } catch {
            let authError = AuthErrorCode.Code(rawValue: (error as NSError).code)
            state = .error
            self.showAlert = true
            self.authError = AuthError(authErrorCode: authError ?? .userNotFound)
        }
    }
    
   func signInAnonymous() async throws {
       do {
           try await AuthService.shared.loginAnonymous()
       } catch {
           let authError = AuthErrorCode.Code(rawValue: (error as NSError).code)
           self.showAlert = true
           self.authError = AuthError(authErrorCode: authError ?? .userNotFound)
       }
    }
    
}
