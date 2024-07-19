//
//  UploadJobViewModel.swift
//  featrrrnew
//
//  Created by Buddie Booking on 7/10/23.
//

//import Foundation
import PhotosUI
import SwiftUI
import Firebase
import StripePaymentSheet

@MainActor
class ModifyJobViewModel: ObservableObject {
    @Published private(set)var isUploading = false
    @Published var error: Error?
    @Published var selectedImages: [PhotosPickerItem] = [] {
        didSet {
            
                Task {
                    imageItems = await ImageCarouselItem.arrayWithItems(selectedImages)
                } //TODO: Will upload duplicates
            
        }
    }
    @Published var imageItems: [ImageCarouselItem] = [] {
        didSet {
            updateSubmissionEnabled()
        }
    }
    @Published var hr: Int?  {
        didSet {
            updateSubmissionEnabled()
        }
    }
    @Published var hrString: String = ""
    @Published var task: Int?  {
        didSet {
            updateSubmissionEnabled()
        }
    }
    @Published var taskString: String = ""
    @Published var storyPost: Int?  {
        didSet {
            updateSubmissionEnabled()
        }
    }
    @Published var storyPostString: String = ""
    @Published var city = ""  {
        didSet {
            updateSubmissionEnabled()
        }
    }
    @Published var state = ""  {
        didSet {
            updateSubmissionEnabled()
        }
    }
    @Published var country = ""  {
        didSet {
            updateSubmissionEnabled()
        }
    }
    @Published var category = ""  {
        didSet {
            updateSubmissionEnabled()
        }
    }
    @Published var jobBio = "" {
        didSet {
            updateSubmissionEnabled()
        }
    }
    @Published var submissionEnabled = false
    @Published var paymentState: PaymentState = .paymentLoading
    @Published var customerSheet: CustomerSheet?
    @Published var connectAccountState: ConnectAccountState = .accountInitial
    @Published var connectedAccountState: ConnectedAccountState = .connectLoading
    @Published var connectAccount: ConnectAccountResponse?
    
    func setIsUploading(_ val: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.isUploading = val
        }
    }
    init() {
        getCustomerSheet()
        getConnectAccount()
        updateSubmissionEnabled()
    }
    
    var messageError: String = ""
    @Published var showMessageError = false
    func sendErrorAlert() {
        messageError = ""

        if imageItems.isEmpty {
            messageError += "• Select 1+ Image(s)\n"
        }

        if !allFieldsIncluded() {
            messageError += "• Fill all fields\n"
        }

        if paymentState != .paymentOnFile {
            messageError += "• Provide a default payment method\n"
        }
        
        if connectAccountState != .accountSuccess {
            messageError += "• Provide a payout account\n"
        }

        messageError += "\nPlease resolve these issues before proceeding"
        showMessageError = true
    }
    func getCustomerSheet() {
        
        if let user = AuthService.shared.user {
            PaymentService.standard.prepareSetupIntent(user: user) { [weak self] result in
                
                do {
                    let sheet = try result.get()
                    self?.customerSheet = sheet
                } catch let error as PaymentErrorType  {
                        self?.showAlert(error.localizedDescription())
              
                } catch {
                    self?.showAlert("An internal error occured.  Try again in a few minutes or contact support")
                }
            }
        } else {
            self.showAlert("Your user account seems to be missing information.  Try to log out and log back in or contact support for further assistance")
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
    
    @Published var accountCompleted = false
    func getConnectAccount() {
        connectedAccountState = .connectLoading
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
    
    private func showAlert(_ msg: String) {
        messageError = msg
        showMessageError = true
    }
      func onCompletion(result: CustomerSheet.CustomerSheetResult) {
          switch (result){
          case .canceled(let selection), .selected(let selection):
              if selection == nil {
                  paymentState = .noPaymentMethod
              } else {
                  paymentState = .paymentOnFile
              }
          case .error(_):
              paymentState = .paymentError
          }
      }
    
    private func allFieldsIncluded() -> Bool {
        return !jobBio.isEmpty && hr != nil && task != nil && storyPost != nil && !city.isEmpty && !state.isEmpty && !country.isEmpty && !category.isEmpty
    }
    func updateSubmissionEnabled() {
        let imagesIncluded = imageItems.count > 0
        let allFieldsIncluded = allFieldsIncluded()
        let paymentIncluded = paymentState == .paymentOnFile
        submissionEnabled = imagesIncluded && allFieldsIncluded && paymentIncluded
    }
    
    @Published var lastFourDigitsPayment: String?
    func getDefaultPayment() {
        if let user = AuthService.shared.user {
            PaymentService.standard.getDefaultPayment(user:user) {[weak self] result in
                do {
                    let result = try result.get()
                    if result == nil {
                        self?.paymentState = .noPaymentMethod
                    } else {
                        self?.lastFourDigitsPayment = result?.last4
                        self?.paymentState = .paymentOnFile
                    }
                } catch {
                    self?.paymentState = .paymentError
                }
                
            }
        }
        
    }
    
    func clearData() {
        jobBio = ""
        hr = nil
        task = nil
        storyPost = nil
        category = ""
        city = ""
        state = ""
        country = ""
        selectedImages = []
    }
    
    
    func loadImages(withItems items: [PhotosPickerItem]) async {
        var imageI: [ImageCarouselItem] = []
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self) else { return }
            guard let image = UIImage(data: data) else { return }
            let imageCarouselItem = ImageCarouselItem(image: image)
            imageI.append(imageCarouselItem)
        }
        self.imageItems = imageI
        
    }
    

}
