//
//  InboxView.swift
//  featrrrnew
//
//  Created by Buddie Booking on 8/9/23.
//

import SwiftUI
import Kingfisher


struct InboxView: View {
    
    //let user: User
    @EnvironmentObject var viewModel: RootViewModel
    
    @State var previewImageUrl: String?
    private var user: User? {
        return viewModel.currentUser
    }
    
    var body: some View {
        
        NavigationStack{
            
            if(viewModel.recentMessages.isEmpty) {
                VStack{
                    Image(systemName: "ellipsis.message")
                        .resizable()
                        .frame(width: 70, height: 70)
                        
                    Text("No message available")
                        .font(.title)
                    Text("Try to send a request to get started")
                        .font(.caption)
                }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            HStack {
                                CircularProfileImageView(user: user)
                                
                                Text("Featrrr Messages")
                                    .font(Style.font.title)
                                    .foregroundColor(Color.foreground)
                            }
                        }
                    }
            } else {
                
                List {
                    ForEach(viewModel.recentMessages) { message in
                        ZStack {
                            NavigationLink(value: message.id) {
                                EmptyView()
                            }.opacity(0.0)
                            
                            InboxRowView(message: message)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .navigationDestination(for: String.self, destination: { message in
                    
                    ChatsView(userId: message)
                    
                })
                
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        HStack {
                            CircularProfileImageView(user: user)
                            
                            Text("Featrrr Messages")
                                .font(Style.font.title)
                                .foregroundColor(Color.foreground)
                        }
                    }
                }
            }
            
        }
        
    }
    
}


struct InboxView_Previews: PreviewProvider {
    static var previews: some View {
        InboxView()
    }
}
