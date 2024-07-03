//
//  ResetPasswordView.swift
//  featrrrnew
//
//  Created by Buddie Booking on 7/25/23.
//

import SwiftUI

struct ResetPasswordView: View {
    @EnvironmentObject var viewModel: LoginViewModel
    @Binding private var email: String
    @Environment(\.dismiss) var dismiss
    init(email: Binding<String>) {
        self._email = email
    }

    var body: some View {
        
        ZStack {
           background
            NavigationStack {
                VStack {
              
                    Spacer()
                    
                    VStack(spacing: .sm) {
                        resetPasswordHeading
                        resetPasswordSubheading
                        emailField
                        signUpLink
                    }
                    
                    Spacer()
                    resetButton
                    
                }
                .padding(.xlg)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.backward")
                                .foregroundStyle(Color.background)
                        }
                    }
                }
            }
        }
        .onReceive(viewModel.$didSendResetPasswordLink, perform: { sentPassword in
            if sentPassword {
                dismiss()
            }
        })
    }
    
    var background: some View {
        LinearGradient(gradient: Gradient(colors: [Color.primary, Color.secondary]), startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
    
    var resetButton: some View {
        Button(action: {
            viewModel.resetPassword(withEmail: email)
        }, label: {
            HStack {
                Spacer()
                Text("Reset Password")
                    .font(Style.font.caption)
                    .foregroundColor(Color.background)
                    .padding()
                Spacer()
            }
            .background(Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: .sm))
            
            
        })
        .disabled(!formIsValid)
    }
    var resetPasswordHeading: some View {
        Text("Reset Password")
            .font(Style.font.title)
            .foregroundStyle(Color.background)
    }
    var resetPasswordSubheading: some View {
        Text("Provide an email to send password reset link")
            .font(Style.font.title4)
            .foregroundColor(.background)
    }
    var signUpLink: some View {
        NavigationLink {
            AddEmailView()
        } label: {
            HStack(spacing: CGFloat.xxsm) {
                Spacer()
                Text("Don't have an account?")
                    .font(Style.font.captionLight)
                
                Text("Sign Up")
                    .font(Style.font.caption)
            }.foregroundStyle(Color.background)
        }.padding(.vertical, .sm)
    }
    var emailField: some View {
        HStack {
            Image(systemName: "at")
            TextField("Email ID", text: $viewModel.email)
                .autocapitalization(.none)
        }
        .padding(.md)
        .background(RoundedRectangle(cornerRadius: .cornerS).fill(Color.field))
    }
}

extension ResetPasswordView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        return !viewModel.email.isEmpty
        && viewModel.email.contains("@")
        && viewModel.email.contains(".")
    }
}
