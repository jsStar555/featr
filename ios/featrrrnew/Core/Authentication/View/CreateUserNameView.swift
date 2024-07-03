//
//  CreateUserNameView.swift
//  featrrrnew
//
//  Created by Buddie Booking on 6/29/23.
//

import SwiftUI

struct CreateUsernameView: View {
    @EnvironmentObject var viewModel: RegistrationViewModel
    @State private var showCreatePasswordView = false

    var body: some View {
        VStack(spacing: CGFloat.md) {
            Spacer()
            
            usernameHeading
            usernameSubheading
            usernameField
            usernameFieldValidationMessage
            
            Spacer()
            
            usernameButton

        }
        .padding(.xlg)
        .navigationTitle("Create an Account")
        .onReceive(viewModel.$usernameIsValid, perform: { usernameIsValid in
            if usernameIsValid {
                self.showCreatePasswordView.toggle()
            }
        })
        .navigationDestination(isPresented: $showCreatePasswordView, destination: {
            CreatePasswordView()
                .environmentObject(viewModel)
        })
        .onAppear {
            showCreatePasswordView = false
            viewModel.usernameIsValid = false
        }
    }
    @ViewBuilder
    var usernameFieldValidationMessage: some View {
        if viewModel.usernameValidationFailed {
            Text("This username is already in use. Try another username.")
                .font(Style.font.caption)
                .foregroundColor(Color.warning)
        }
    }
    var usernameButton: some View {
        Button {
            Task {
                try await viewModel.validateUsername()
            }
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
    var usernameSubheading: some View {
        Text("Make a username for your new account. You can always change it later.")
            .font(Style.font.caption)
            .foregroundColor(Color.lightBackground)
            .multilineTextAlignment(.center)
    }
    var usernameHeading: some View {
        Text("Create username")
            .font(Style.font.title2)
            .padding(.top)
    }
    var usernameField: some View {
        
            HStack {
                Image(systemName: "person.circle.fill")
                TextField("Username", text: $viewModel.username)
                    .autocapitalization(.none)
                if viewModel.isLoading {
                    ProgressView()
                }
                
                if viewModel.usernameValidationFailed {
                    Image(systemName: "xmark.circle.fill")
                        .imageScale(.large)
                        .foregroundColor(Color.warning)
                }
            }
            .padding(.md)
            .background(RoundedRectangle(cornerRadius: .cornerS).fill(Color.field))
        
        
          
    }
}

extension CreateUsernameView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        return !viewModel.username.isEmpty
    }
}

struct CreateUsernameView_Previews: PreviewProvider {
    static var previews: some View {
        CreateUsernameView()
            .environmentObject(RegistrationViewModel())
    }
}
