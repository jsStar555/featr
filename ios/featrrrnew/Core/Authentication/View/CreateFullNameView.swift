//
//  CreateUserNameView.swift
//  featrrrnew
//
//  Created by Buddie Booking on 6/29/23.
//

import SwiftUI

struct CreateFullnameView: View {
    @EnvironmentObject var viewModel: RegistrationViewModel
    @State private var showCreatePasswordView = false

    var body: some View {
        VStack(spacing: CGFloat.md) {
            Spacer()
            
            fullnameHeading
            fullnameSubheading
            fullnameField
            
            Spacer()
            
            fullnameButton

        }
        .padding(.xlg)
        .navigationTitle("Create an Account")
        .navigationDestination(isPresented: $showCreatePasswordView, destination: {
            CreatePasswordView()
                .environmentObject(viewModel)
        })
    }
  
    var fullnameButton: some View {
        NavigationLink {
            CompleteSignUpView()
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
    var fullnameSubheading: some View {
        Text("Choose a display name.  Typically we recommend using your full name.")
            .font(Style.font.caption)
            .foregroundColor(Color.lightBackground)
            .multilineTextAlignment(.center)
    }
    var fullnameHeading: some View {
        Text("Add Your Display Name")
            .font(Style.font.title2)
            .padding(.top)
    }
    var fullnameField: some View {
        
            HStack {
                Image(systemName: "pencil.circle.fill")
                TextField("Full Name", text: $viewModel.fullname)
                    .autocapitalization(.none)
                if viewModel.isLoading {
                    ProgressView()
                }
                
            }
            .padding(.md)
            .background(RoundedRectangle(cornerRadius: .cornerS).fill(Color.field))
        
        
          
    }
}

extension CreateFullnameView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        return !viewModel.fullname.isEmpty
    }
}

struct CreateFullnameView_Previews: PreviewProvider {
    static var previews: some View {
        CreateFullnameView()
            .environmentObject(RegistrationViewModel())
    }
}
