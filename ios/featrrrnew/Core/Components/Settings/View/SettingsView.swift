//
//  SettingsView.swift
//  featrrrnew
//
//  Created by Buddie Booking on 7/11/23.
//

import SwiftUI
import StripePaymentSheet

enum SettingsItemModel: Int, Identifiable, Hashable, CaseIterable {
    case settings
    case saved
    case logout
    
    var title: String {
        switch self {
        case .settings:
            return "Settings"
        case .saved:
            return "Saved"
        case .logout:
            return "Logout"
        }
    }
    
    var imageName: String {
        switch self {
        case .settings:
            return "gear"
        case .saved:
            return "bookmark"
        case .logout:
            return "arrow.left.square"
        }
    }
    
    var id: Int { return self.rawValue }
}

enum PaymentState {
    case noPaymentMethod, paymentOnFile, paymentError, paymentLoading
}

enum ConnectAccountState {
    case accountInitial, accountSuccess, accountError, accountLoading
}

enum ConnectedAccountState {
    case connected, noAccountConnected, connectError, connectLoading
}

enum RequestPayoutState {
    case loading, error, success, disabled
}
class SettingsViewModel: ObservableObject {
    @Published var customerSheet: CustomerSheet?
    @Published var paymentState: PaymentState = .paymentLoading
    @Published var connectAccountState: ConnectAccountState = .accountInitial
    @Published var connectAccount: ConnectAccountResponse?
    var messageError: String = ""
    @Published var showMessageError = false
    @Published var accountCompleted = false
    @Published var connectedAccountState: ConnectedAccountState = .connectLoading
    @Published var showMyAccount: Bool = false
    @Published var userBalance: UserBalance?
    @Published var payoutMessage: String?
    @Published var requestPayoutState: RequestPayoutState?
    @Published var displayPopoverOpacity = 0.0
    @Published var isSellerAccount = false

    init() {
        checkAccountId()
        getCustomerSheet()
        getDefaultPayment() //Load the initial payment method to populate with "default" (no payment, error, payment)
        getConnectAccount()
        Task {
            await getBalance()
            await checkUserJobs()

        }
    }
    
    func checkAccountId() {
        if let user = AuthService.shared.user {
            showMyAccount = user.connectAccountId != nil
        } else {
            showMyAccount = false
        }
    }
    
    func getLoginLink() async -> String? {
        if let user = AuthService.shared.user {
          let result = await PaymentService.standard.createLoginLink(user: user)
            do {
                let loginLink =  try result.get()
                return loginLink
            } catch let error as PayoutAccoutErrorType {
                self.showAlert(error.localizedDescription())
            } catch {
                self.showAlert("An internal error occured.  Try again in a few minutes or contact support")
            }
        }
        return nil
    }
    
    func getBalance() async {
        if let user = AuthService.shared.user {
            let result = await PaymentService.standard.getConnectAccountBalance(user: user)
            do {
                let balance =  try result.get()
                userBalance = balance
            } catch let error as PayoutAccoutErrorType {
                self.showAlert(error.localizedDescription())
            } catch {
                self.showAlert("An internal error occured.  Try again in a few minutes or contact support")
            }
        }
    }
    
    func checkUserJobs() async {
        if let user = AuthService.shared.user {
            do {
                let jobs = try await JobService.standard.fetchUserJobs(user: user)
                
                self.isSellerAccount = jobs.count > 0
            } catch {
                isSellerAccount = false
            }
        } else {
            isSellerAccount = false
        }
    }
    
    func requestPayout() async {
        requestPayoutState = .loading
        if let user = AuthService.shared.user {
            let result = await PaymentService.standard.requestPayout(user: user)
            do {
                let message =  try result.get()
                displayPopoverOpacity = 1.0
                requestPayoutState = .success
                payoutMessage = message
                await getBalance()
            } catch let error as PayoutAccoutErrorType {
                requestPayoutState = .error
                self.showAlert(error.localizedDescription())
            } catch {
                requestPayoutState = .error
                self.showAlert("An internal error occured.  Try again in a few minutes or contact support")
            }
        }
    }
    
    func getCustomerSheet() {
        if let user = AuthService.shared.user {
            PaymentService.standard.prepareSetupIntent(user: user) { result in
                
                do {
                    let sheet = try result.get()
                    self.customerSheet = sheet
                } catch {
                    print("ERROR \(error)")
                    //TODO: Display error in model
                }
                
            }
        } else {
            print("no user")
        }
    }
      func onCompletion(result: CustomerSheet.CustomerSheetResult) {
          switch (result){
          case .canceled(let selection), .selected(let selection):
              if selection == nil {
                  paymentState = .noPaymentMethod
              } else {
                  paymentState = .paymentOnFile
              }
          case .error(let error):
              paymentState = .paymentError
          }
      }
    
   
    func getConnectAccount() {
        if let user = AuthService.shared.user {
            PaymentService.standard.getConnectAccount(user:user) {[weak self] result in
                do {
                    let result = try result.get()
                    if result == nil || result == false {
                        self?.connectedAccountState = .noAccountConnected
                    } else {
                        self?.accountCompleted = result ?? false
                        self?.connectedAccountState = .connected
                    }
                } catch {
                    self?.connectedAccountState = .connectError
                }
                
            }
        }
        
    }
    
    
    func getDefaultPayment() {
        if let user = AuthService.shared.user {
            PaymentService.standard.getDefaultPayment(user:user) {[weak self] result in
                do {
                    let result = try result.get()
                    if result == nil {
                        self?.paymentState = .noPaymentMethod
                    } else {
                        self?.paymentState = .paymentOnFile
                    }
                } catch {
                    self?.paymentState = .paymentError
                }
                
            }
        }
        
    }
    
    func createPayoutAccount() async -> String? {
        self.connectAccountState = .accountLoading
        if let user = AuthService.shared.user {
            let result = await PaymentService.standard.createAccountLink(user: user)
            do {
                let linkUrl = try result.get()
                self.connectAccountState = .accountSuccess
                return linkUrl
            } catch let error as PayoutAccoutErrorType {
                self.connectAccountState = .accountError
                self.showAlert(error.localizedDescription())
            } catch {
                self.connectAccountState = .accountError
                self.showAlert("An internal error occured.  Try again in a few minutes or contact support")
            }
        } else {
            self.showAlert("Your user account seems to be missing information.  Try to log out and log back in or contact support for further assistance")
        }
        return nil
    }
    
    private func showAlert(_ msg: String) {
        messageError = msg
        showMessageError = true
    }
      
    
}
struct SettingsView: View {
    
    @Environment(\.dismiss) var dismiss
    @State private var showingCustomerSheet = false
    @ObservedObject var viewModel = SettingsViewModel()
    @State private var linkUrl: URL?
    @State private var loginUrl: URL?
    
    var body: some View {
        VStack {
            
            Divider()
            
            List {
                    
                if viewModel.showMyAccount && viewModel.isSellerAccount {
                    Button {
                        Task {
                           let loginLink = await viewModel.getLoginLink()
                            if let loginLink = loginLink {
                                linkUrl = URL(string: loginLink)
                            }
                        }
                        
                    } label: {
                        HStack {
                            Image(systemName: "dollarsign")
                            Text("My Account")
                            Spacer()
                            if let balance = viewModel.userBalance {
                                Text((balance.amount/100) .formatted(.currency(code: balance.currency)))
                            }
                            
                            
                        }
                    }
                    
                    if  let balance = viewModel.userBalance  {
                        if(balance.amount > 0) {
                            Button {
                                Task {
                                   await viewModel.requestPayout()
                                }
                                
                            } label: {
                                HStack {
                                    Image(systemName: "line.diagonal.arrow")
                                    Text("Request Payout")
                                    Spacer()
                                    switch (viewModel.requestPayoutState) {
                                        case .loading:
                                            ProgressView()
                                        case .error:
                                            Chip(text: "Error", style: .cancel)
                                        default:
                                            EmptyView()
                                    }
                                    
                                }
                            }
                        }
                    }
                    
                   
                }
               
                    Button {
                        viewModel.getDefaultPayment()
                        showingCustomerSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "creditcard.fill")
                            Text("Payment Settings")
                            
                                Spacer()
                                switch (viewModel.paymentState) {
                                case .paymentLoading:
                                    ProgressView()
                                case .paymentError:
                                    Chip(text: "Error", style: .cancel)
                                case .noPaymentMethod:
                                    Chip(text: "No Payment Method", style: .information)
                                case .paymentOnFile:
                                    Chip(text: "Payment On File", style: .success)
                                }
                            
                        }
                    }
                
                Button {
                    if(viewModel.connectedAccountState == .connected) {
                        return
                    }
                    viewModel.getConnectAccount()
                    Task {
                        let response = await viewModel.createPayoutAccount()
                        if let response = response {
                            linkUrl = URL(string: response)
                        }
                    }
                } label: {
                    HStack {
                        switch(viewModel.connectAccountState) {
                            case .accountLoading:
                                ProgressView()
                            default:
                                Image(systemName: "person.crop.circle.fill")
                        }
                        Text("Payout Settings")
                        
                        
                        Spacer()
                        switch (viewModel.connectedAccountState) {
                            case .connectLoading:
                                ProgressView()
                            case .connectError:
                                Chip(text: "Error", style: .cancel)
                            case .noAccountConnected:
                                Chip(text: "No Account Connected", style: .cancel)
                            case .connected:
                                Chip(text: "Account Connected", style: .success)
                        }
                        
                    }
                }

                Button {
                    print("Toggle the Dark Mode")
                } label: {
                    HStack {
                        Image(systemName: "circle.lefthalf.filled")
                        Text("Toggle Dark Mode")
                    }
                }
                
                Button {
                    Task {
                        do {
                            try await AuthService.shared.signout()
                        } catch {
                            //TODO: Output error saying we couldn't sign out (maybe to do with invalidating the token
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.left.square")
                        Text("Logout")
                    }
                }

               
            }
            .listStyle(PlainListStyle())
            
            if let message = viewModel.payoutMessage {
                VStack {
                    Text(message)
                }
                .frame(width: 250, height: 150)
                .background(.ultraThinMaterial)
                .mask(RoundedRectangle(cornerRadius: .cornerM))
                .opacity(viewModel.displayPopoverOpacity)
                .animation(.easeIn(duration: 0.25), value: viewModel.displayPopoverOpacity)
            }
            
            if let sheet = viewModel.customerSheet {
                VStack{}.customerSheet(
                    isPresented: $showingCustomerSheet,
                    customerSheet: sheet,
                    onCompletion: viewModel.onCompletion
                )
            }
            
        }
        .navigationTitle("Settings")
        .refreshable {
            viewModel.getConnectAccount()
            viewModel.getDefaultPayment()
            Task {
                
                await viewModel.getBalance()
            }
        }
        .sheet(isPresented: $linkUrl.mappedToBool(), onDismiss: {
            linkUrl = nil
        }) {
            SafariWebView(url: linkUrl!)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $loginUrl.mappedToBool(), onDismiss: {
            loginUrl = nil
        }) {
            SafariWebView(url: loginUrl!)
                .ignoresSafeArea()
        }
        .onChange(of: viewModel.displayPopoverOpacity) { value in
            if value == 1.0 {
                //Fade out after a specified duration
                DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: { // possibly a risk for a strong reference cycle
                    self.viewModel.displayPopoverOpacity = 0.0
                })
            }
        }
        .onAppear {
            viewModel.getConnectAccount()
        }
        .alert("Validation Error", isPresented: $viewModel.showMessageError) {
                Button("Dismiss") {
                    viewModel.showMessageError = false
                }
            } message: {
                HStack {
                    Text(viewModel.messageError)
                    Spacer()
                }
            }
    }
}

struct SettingsRowView: View {
    let model: SettingsItemModel
    
    var body: some View {
        HStack(spacing: CGFloat.sm) {
            Image(systemName: model.imageName)
                .imageScale(.medium)
            
            Text(model.title)
                .font(Style.font.title2)
                .foregroundColor(.background)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
