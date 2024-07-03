//
//  AddEmailView.swift
//  featrrrnew
//
//  Created by Buddie Booking on 6/29/23.
//

import SwiftUI

struct AddEmailView: View {
    @StateObject var viewModel = RegistrationViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showCreateUsernameView = false

    var body: some View {
        VStack(spacing: CGFloat.md) {
           
            Spacer()
            
            emailHeading
            emailSubheading
            emailField
            
            emailFieldValidationMessage
                    
            Spacer()
            
            validateEmailButton
            
       
        }
        .padding(.xlg)
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Register Now")
        .onReceive(viewModel.$emailIsValid, perform: { emailIsValid in
            if emailIsValid {
                self.showCreateUsernameView.toggle()
            }
        })
        .navigationDestination(isPresented: $showCreateUsernameView, destination: {
            CreateUsernameView()
                .environmentObject(viewModel)
        })
        .onAppear {
            showCreateUsernameView = false
            viewModel.emailIsValid = false
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Image(systemName: "chevron.left")
                    .imageScale(.large)
                    .onTapGesture {
                        dismiss()
                    }
            }
        }
    }
    @ViewBuilder
    var emailFieldValidationMessage: some View {
        if viewModel.emailValidationFailed {
            Text("This email is already in use. Please login or try again.")
                .font(Style.font.caption)
                .foregroundColor(Color.warning)
        }
    }
    var validateEmailButton: some View {
        Button {
            Task {
                try await viewModel.validateEmail()
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
    var emailSubheading: some View {
        Text("You'll use this email to sign in to your account.")
            .font(Style.font.caption)
            .foregroundColor(Color.lightBackground)
            .multilineTextAlignment(.center)
    }
    var emailHeading: some View {
        Text("Add your email")
            .font(Style.font.title2)
            .padding(.top)
    }
    var emailField: some View {
        
            HStack {
                Image(systemName: "at")
                TextField("Email ID", text: $viewModel.email)
                    .autocapitalization(.none)
                if viewModel.isLoading {
                    ProgressView()
                }
                
                if viewModel.emailValidationFailed {
                    Image(systemName: "xmark.circle.fill")
                        .imageScale(.large)
                        .foregroundColor(Color.warning)
                }
            }
            .padding(.md)
            .background(RoundedRectangle(cornerRadius: .cornerS).fill(Color.field))
            
            
        
        
          
    }
}

extension AddEmailView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        return !viewModel.email.isEmpty
        && viewModel.email.contains("@")
        && viewModel.email.contains(".")
    }
}

struct AddEmailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AddEmailView()
                .environmentObject(RegistrationViewModel())
        }
    }
}
