//
//  ChatsView.swift
//  featrrrnew
//
//  Created by Buddie Booking on 8/9/23.
//

import SwiftUI

struct ChatsView: View {
    @State private var messageText = ""
    @State private var isInitialLoad = false
    @ObservedObject var viewModel = ChatsViewModel()

    
    init(user: User) {
        self.viewModel.listen(user: user)
    }
    
    init(userId: String) {
        
        Task { [self] in
            do {
                var user = try await UserService.fetchUser(withUid: userId)
                    DispatchQueue.main.async { [self] in
                        self.viewModel.listen(user: user)
                    }
                
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    
   
   
    var body: some View {
        VStack {
            if let user = self.viewModel.user {
                VStack {
                    ReversedLazyMessageScrollView(messages: $viewModel.messages, user: user)
                    Spacer()
                    MessageInputView(messageText: $messageText, viewModel: viewModel)
                }
                .onDisappear {
                    viewModel.removeChatListener()
                }
                .onChange(of: viewModel.messages, perform: { _ in
                    Task { try await viewModel.updateMessageStatusIfNecessary()}
                })
                .navigationTitle(user.username)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                VStack {
                    ProgressView()
                }
            }
        }
    }
}


struct ChatsView_Previews: PreviewProvider {
    static var previews: some View {
        ChatsView(user: dev.user)
    }
}

