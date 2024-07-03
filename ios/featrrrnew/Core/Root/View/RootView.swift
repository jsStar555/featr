//
//  ContentView.swift
//  featrrrnew
//
//  Created by Buddie Booking on 6/27/23.
//

import SwiftUI

enum Routing: Hashable {
    case messaging(String)
}
class Router: ObservableObject {
    var routes: [Routing] = []
}
struct RootView: View {
    
    @StateObject var viewModel = RootViewModel()
    @State var selectedIndex = 0
    @StateObject var viewRouter = Router()
    
    var body: some View {
        
        Group {
//            NavigationStack(path: $viewRouter.routes) {
                VStack {
                    if viewModel.userSession == nil || viewModel.currentUser == nil {
                        LoginView()
                    } else {
                        if let user = viewModel.currentUser {
                            if let firebaseUser = viewModel.userSession, firebaseUser.isAnonymous {
                                JobView()
                            } else {
                                MainTabView(user: user, selectedIndex: $selectedIndex, unreadMessages: $viewModel.hasUnreadMessages)
                            }
                        } else {
                            ProgressView()
                        }
                        
                    }
                }
            }
            .environmentObject(viewModel)
            // TODO: (joshzbeck) Continue with deep link integration
//            .onOpenURL { incomingURL in
//                       print("App was opened via URL: \(incomingURL)")
////                       handleIncomingURL(incomingURL)
//                viewRouter.routes.append(Routing.messaging("asdfasdfasdf"))
//            }
//            .navigationDestination(for: Routing.self) { route in
//                switch route {
//                case .messaging(let userId):
//                        ChatsView(userId: userId)
//                    
//                }
//            }
//        }
        
    }
    private func handleIncomingURL(_ url: URL) {
            guard url.scheme == "featrrr" else {
                return
            }
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                print("Invalid URL")
                return
            }

        guard let action = components.host, action.hasPrefix("message") else {
                print("Unknown URL, we can't handle this one!")
                return
            }

            guard let messageId = components.queryItems?.first(where: { $0.name == "id" })?.value else {
                print("Message id not found")
                return
            }

//            openedRecipeName = recipeName
        }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
