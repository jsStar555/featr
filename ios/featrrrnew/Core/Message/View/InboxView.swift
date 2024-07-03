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


struct InboxView_Previews: PreviewProvider {
    static var previews: some View {
        InboxView()
    }
}
