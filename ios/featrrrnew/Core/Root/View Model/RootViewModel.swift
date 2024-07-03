//
//  RootViewModel.swift
//  featrrrnew
//
//  Created by Buddie Booking on 7/23/23.
//

import Foundation
import Firebase
import Combine


class RootViewModel: ObservableObject {
    
    private let service = AuthService.shared
    private let messageService = InboxService()
    private var cancellables = Set<AnyCancellable>()
    
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var hasUnreadMessages: Bool = false
    var recentMessagesDictionary = [String: Message]()
    @Published var recentMessages = [Message]()
   
   
    private func loadInitialMessages(fromChanges changes: [DocumentChange]) {
        var messages = changes.compactMap({try? $0.document.data(as: Message.self)})
        hasUnreadMessages = false
        
        for i in 0 ..< messages.count {
            UserService.fetchesUser(withUid: messages[i].chatPartnerId) { [weak self] user in
                messages[i].user = user
                if !messages[i].read {
                    self?.hasUnreadMessages = true
                }
                self?.recentMessagesDictionary[user.id] = messages[i]
                
                if let dict =  self?.recentMessagesDictionary {
                    let sorted = Array(dict.values).sorted(by: { $0.timestamp.seconds > $1.timestamp.seconds })
                    self?.recentMessages = sorted
                }
            }
        }
    }
    init() {
        configureSubscribers()
        messageService.observeRecentMessages()
    }
    
    func configureSubscribers() {
        service.$user
            .sink { [weak self] user in
                self?.currentUser = user
            }.store(in: &cancellables)
        
        service.$userSession
            .sink { [weak self] session in
                self?.userSession = session
            }.store(in: &cancellables)
        
        messageService.$documentChanges.sink{[weak self] changes in
            self?.loadInitialMessages(fromChanges: changes)
        }.store(in: &cancellables)
    }
}
