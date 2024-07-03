//
//  CompleteSignUpVIew.swift
//  featrrrnew
//
//  Created by Buddie Booking on 6/29/23.
//

import SwiftUI

struct CompleteSignUpView: View {
    @EnvironmentObject var viewModel: RegistrationViewModel

    var body: some View {
        VStack(spacing: CGFloat.md) {
            Spacer()

            completeHeading
            completeSubheading
            
            Spacer()
            
            completeButton
        }.navigationTitle("Account Created")
            .padding(.xlg)
    }
    var completeButton: some View {
        Button {
            Task { try await viewModel.createUser() }
        } label: {
            HStack {
                Spacer()
                Text("Complete Sign Up")
                Spacer()
            }.modifier(FeatchrButtonModifier())
        }
    }
    var completeHeading: some View {
        Text("Welcome to \(String.appName), \(viewModel.username)")
            .font(Style.font.title2)
            .padding(.top)
            .multilineTextAlignment(.center)
    }
    var completeSubheading: some View {
        Text("Click below to complete registration and start using Featrrr.")
            .font(Style.font.caption)
            .multilineTextAlignment(.center)
            .padding(.horizontal, .lg)
    }
}

struct CompleteSignUpView_Previews: PreviewProvider {
    static var previews: some View {
        CompleteSignUpView()
            .environmentObject(RegistrationViewModel())
    }
}
