//
//  InboxViewModel.swift
//  featrrrnew
//
//  Created by Buddie Booking on 8/10/23.
//

import Foundation
import Combine
import Firebase
//
//class InboxViewModel: ObservableObject {
//    @Published var currentUser: User?
//    var recentMessagesDictionary = [String: Message]()
//    @Published var recentMessages = [Message]()
//    
//    private var cancellables = Set<AnyCancellable>()
//    private let service = InboxService()
//    
//    init() {
//        setupSubscribers()
//        service.observeRecentMessages()
//    }
//    
//    private func setupSubscribers() {
//        UserService.shared.$currentUser.sink { [weak self]  user in
//            self?.currentUser = user
//        }.store(in: &cancellables)
//        
//        service.$documentChanges.sink{[weak self] changes in
//            self?.loadInitialMessages(fromChanges: changes)
//        }.store(in: &cancellables)
//    }
//}

