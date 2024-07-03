//
//  LoginView.swift
//  featrrrnew
//
//  Created by Buddie Booking on 6/29/23.
//

import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isGuest: Bool = false
    @State private var hidePassword: Bool = true
    @StateObject var viewModel = LoginViewModel()
    @StateObject var registrationViewModel = RegistrationViewModel()
    
    /*func continueAsGuest(){
        isGuest = true
    }*/
    
    var body: some View {
        NavigationStack{
            VStack {
                Spacer()
                
                logoImage
                
                Spacer()

                VStack(alignment: .leading, spacing: CGFloat.md) {
                    loginHeading
                    emailField
                    passwordField
                    errorMessage
                    forgotPasswordLink
                   
                }
                
                Spacer()
                
                VStack(spacing: .sm) {
                    loginButton
                    orDivider
                    continueAsGuestButton
                }.padding(.bottom, .md)
                
                signUpLink
            }
            .padding(.xlg)
        }
        
        
    }
    @ViewBuilder
    var errorMessage: some View {
        if viewModel.showAlert {
                Text(getErrorMessage(error: viewModel.authError ?? .unknown))
                    .font(Style.font.caption)
                    .foregroundColor(Color.warning)
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)
        }
    }
    func getErrorMessage(error: AuthError) -> String {
        switch (viewModel.authError) {
        case .invalidEmail, .invalidPassword, .userNotFound, .weakPassword:
            return "The email or password you provided is incorrect"
        default:
            return "An internal error occured - contact support or try again later"
        }
    }
    var logoImage: some View {
        Image("featrlogo")
            .resizable()
            .scaledToFit()
            .frame(width: 200, height: 200)
    }
    var loginHeading: some View {
        Text("Login")
            .font(Style.font.title)
    }
    var emailField: some View {
        HStack {
            Image(systemName: "at")
            TextField("Email ID", text: $email)
                .autocapitalization(.none)
        }
        .padding(.md)
        .background(RoundedRectangle(cornerRadius: .cornerS).fill(Color.field))
          
    }
    var passwordField: some View {
        HStack {
            Image(systemName: "lock.fill")
            if hidePassword {
                SecureField("Password", text: $password)
                    .autocapitalization(.none)
            } else {
                TextField("Password", text: $password)
                    .autocapitalization(.none)
            }
            Button {
                hidePassword.toggle()
            } label: {
                hidePassword ? Image(systemName: "eye.slash.fill") : Image(systemName: "eye.fill")
            }.foregroundStyle(Color.foreground)
        }
        .padding(.md)
        .background(RoundedRectangle(cornerRadius: .cornerS).fill(Color.field))
    }
    var forgotPasswordLink: some View {
        HStack {
            Spacer()
            NavigationLink(
                destination: ResetPasswordView(email: $email).environmentObject(viewModel),
                label: {
                    Text("Forgot Password?")
                        .font(Style.font.caption)
                })
           
        }.padding(.bottom, .xxlg)
    }
    var orDivider: some View {
        HStack {
            VStack {
                Divider()
            }
            
            Text("OR")
                .foregroundColor(Color.lightBackground)
                .font(Style.font.caption)
            
            VStack {
                Divider()
            }
        }
    }
    var loginButton: some View {
        Button(action: {
            Task { try await viewModel.login(withEmail: email, password: password) }
        }, label: {
            HStack {
                Spacer()
                Text("Log In")
                    .font(Style.font.caption)
                    .foregroundColor(Color.background)
                    .padding()
                Spacer()
            }
            .background(formIsValid ? Color.primary : Color.lightBackground)
            .clipShape(RoundedRectangle(cornerRadius: .sm))
            
            
        })
        .disabled(!formIsValid)
    }
    var continueAsGuestButton: some View {
        Button {
            
            Task {
                try await  viewModel.signInAnonymous()
            }
        } label: {
            HStack {
                Spacer()
                Text("Continue As Guest")
                    .font(Style.font.caption)
                    .foregroundColor(Color.primary)
                    .padding()
                Spacer()
            }
            .background(
                RoundedRectangle(cornerRadius: .sm).stroke(Color.primary, lineWidth: 4)
                )
            .clipShape(RoundedRectangle(cornerRadius: .sm))
        }
    }
    var signUpLink: some View {
        NavigationLink {
            AddEmailView()
        } label: {
            HStack(spacing: CGFloat.xxsm) {
                Spacer()
                Text("Don't have an account?")
                    .foregroundStyle(Color.lightBackground)
                    .font(Style.font.captionLight)
                
                Text("Sign Up")
                    .font(Style.font.caption)
            }
        }.padding(.vertical, .sm)
    }
}


extension LoginView: AuthenticationFormProtocol {
   
    var formIsValid: Bool {
        
        return !email.isEmpty
        && email.contains("@")
        && email.contains(".")
        && !password.isEmpty
        && password.count > 5 
            
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(RegistrationViewModel())
    }
}
