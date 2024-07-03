//
//  CreatePasswordView.swift
//  featrrrnew
//
//  Created by Buddie Booking on 6/29/23.
//

import SwiftUI

struct CreatePasswordView: View {
    @EnvironmentObject var viewModel: RegistrationViewModel
    @State private var hidePassword: Bool = true
    var body: some View {
        VStack(spacing: CGFloat.md) {
            Spacer()
            
            passwordHeading
            passwordSubheading
            passwordField
            
            Spacer()
            passwordButton
            
            
        }
        .padding(.xlg)
        .navigationTitle("Create an Account")
    }
    var passwordButton: some View {
        NavigationLink {
            CreateFullnameView()
                .environmentObject(viewModel)
        } label: {
            HStack {
                Spacer()
                Text("Next")
                Spacer()
            }.modifier(FeatchrButtonModifier())
        }
        .disabled(!formIsValid)
        .opacity(formIsValid ? 1.0 : 0.5)
    }
    var passwordHeading: some View {
        Text("Create a password")
            .font(Style.font.title2)
            .padding(.top)
    }
    var passwordSubheading: some View {
        Text("Your password must be at least 6 characters in length.")
            .font(Style.font.caption)
            .foregroundColor(Color.lightBackground)
            .multilineTextAlignment(.center)
            .padding(.horizontal, .lg)
    }
    var passwordField: some View {
        HStack {
            Image(systemName: "lock.fill")
            if hidePassword {
                SecureField("Password", text: $viewModel.password)
                    .autocapitalization(.none)
            } else {
                TextField("Password", text: $viewModel.password)
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
}

// MARK: - AuthenticationFormProtocol

extension CreatePasswordView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        return !viewModel.password.isEmpty && viewModel.password.count > 5
    }
}

struct CreatePasswordView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePasswordView()
            .environmentObject(RegistrationViewModel())

    }
}
