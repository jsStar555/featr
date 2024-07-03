//
//  PaymentService.swift
//  featrrrnew
//
//  Created by Josh Beck on 3/18/24.
//

import Foundation
import StripePaymentSheet
import StripePaymentsUI


protocol PaymentServiceDelegate {
    func preparePaymentSheet(payment:Double, job:JobPost, fromUser: User, toUser: User, completion: @escaping (Result<PaymentSheet, PaymentErrorType>) -> ())
//    func requstRefund(jobID: String) async -> Result<String, PaymentErrorType>
    
}

struct StripeCustomer {
    var customerID: String
    var ephemerialKey: String
}

struct CardInfo {
    var id: String
    var last4: String
}

enum PaymentErrorType: Error {
    case invalidUrl, missingEmail, missingFullname, alreadyPaidError, serverError, jsonError, internalError

    func localizedDescription() -> String {
        switch (self){
        case .internalError, .serverError:
            return "An internal error occured.  Try again later"
        case .invalidUrl:
            return "We were unable to contact our servers.  Contact support for assistance."
        case .jsonError:
            return "We were unable to contact our servers.  Contact support for assistance."
        case .missingEmail, .missingFullname:
            return "Your user account seems to be missing information.  Try to log out and log back in or contact support for further assistance"
        case .alreadyPaidError:
            return "You have already paid for this job.  Thank you!"
            
        }
    }
}
//TODO: Needs a lot of work to abstract away enviornment variables
class PaymentService: PaymentServiceDelegate {
    
    public static let standard = PaymentService()
    
    private func fetchRefreshToken(completion: @escaping (String) -> ()){
        Task {
            completion((try? await AuthService.shared.userSession?.getIDToken()) ?? "")
        }
    }
    
    func getDefaultPayment(user: User, completion: @escaping (Result<CardInfo?, PaymentErrorType>) -> ()) {
        
        guard let url = URL(string: FirebaseFunctions.DEFAULT_PAYMENT) else {
            completion(.failure(.invalidUrl))
            return
        }
        
        guard let email = user.email else {
            completion(.failure(.missingEmail))
            return
        }
        
        guard let fullname = user.fullname else {
            completion(.failure(.missingFullname))
            return
        }
        
        let json = """
        {
            "email": "\(email)",
            "name": "\(fullname)"
        }
        """
        
        // Formulate the job data
        let parameters = json.data(using: .utf8)
        
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = parameters
    
        var task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else {
                completion(.failure(.serverError))
                return
            }
            
           
            guard let paymentId = json["id"] as? String, let last4 = json["last_4"] as? String else {
                completion(.failure(.jsonError))
                return
            }
            
            guard let  self = self else {
                completion(.failure(.internalError))
                return
            }
            completion(.success(CardInfo(id: paymentId, last4: last4)))

        })
        task.resume()
        
    }
    func updateDefaultPaymentMethod(completion: @escaping (Result<Bool, PaymentErrorType>) -> ()) {
        
        fetchRefreshToken { token in
            let tokenID = "Bearer \(token)"
            var request = URLRequest(url: URL(string: FirebaseFunctions.FETCH_DEFAULT_PAYMENT_METHODS)!)
            request.allHTTPHeaderFields = ["Authorization": tokenID,"Content-Type":"application/json"]
            request.httpMethod = "get"
            
            
            let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else {
                    completion(.failure(.jsonError))
                    return
                }
                print(json)
                guard let self = self else {
                    completion(.failure(.internalError))
                    return
                }
                
                if let success = json["success"] as? Int {
                    DispatchQueue.main.async {
                        completion(.success(success == 1))
                    }
                } else {
                    completion(.failure(.serverError))
                }
            })
            task.resume()
        }
        
    }
    
    func fetchDefaultPaymentMethod(completion: @escaping (Result<Bool, PaymentErrorType>) -> ()) {
        fetchRefreshToken { token in
            let tokenID = "Bearer \(token)"
            var request = URLRequest(url: URL(string: FirebaseFunctions.FETCH_DEFAULT_PAYMENT_METHODS)!)
            request.allHTTPHeaderFields = ["Authorization": tokenID,"Content-Type":"application/json"]
            request.httpMethod = "get"
            
            
            let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else {
                    completion(.failure(.jsonError))
                    return
                }
                print(json)
                guard let self = self else {
                    completion(.failure(.internalError))
                    return
                }
                
                if let success = json["success"] as? Int {
                    DispatchQueue.main.async {
                        completion(.success(success == 1))
                    }
                } else {
                    completion(.failure(.serverError))
                }
            })
            task.resume()
        }
        
    }
    func prepareSetupIntent(user: User, completion: @escaping (Result<CustomerSheet, PaymentErrorType>) -> ()) {
        
        guard let url = URL(string: FirebaseFunctions.CREATE_SETUP_INTENT) else {
            completion(.failure(.invalidUrl))
            return
        }
        
        guard let email = user.email else { 
            completion(.failure(.missingEmail))
            return
        }
        guard let fullname = user.fullname else {
            completion(.failure(.missingFullname))
            return
        }
        
        let json = """
        {
            "name": "\(fullname)",
            "email": "\(email)",
            "userId": "\(user.id)"
        }
        """
        // Formulate the job data
        let parameters = json.data(using: .utf8)
        
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = parameters
        
        print("Sending data")
        var task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else {
                completion(.failure(.serverError))
                return
            }
            
            guard let customerId = json["customer"] as? String,
                  let customerEphemeralKeySecret = json["ephemeralKey"] as? String,
                  let setupIntentDictionary = json["setupIntent"] as? [String: Any],
                  let paymentIntentClientSecret = setupIntentDictionary["client_secret"] as? String,
                  let publishableKey = json["publishableKey"] as? String else {
                completion(.failure(.internalError))
                return
            }
            
            guard let  self = self else {
                completion(.failure(.internalError))
                return
            }
            
            STPAPIClient.shared.publishableKey = publishableKey
            // Create a PaymentSheet instance
            var configuration = CustomerSheet.Configuration()

            // Configure settings for the CustomerSheet here. For example:
            configuration.headerTextForSelectionScreen = "Manage your payment method"
            
            let customerAdapter = StripeCustomerAdapter(customerEphemeralKeyProvider: {
                return CustomerEphemeralKey(customerId: customerId, ephemeralKeySecret: customerEphemeralKeySecret)
            }, setupIntentClientSecretProvider: {
                return paymentIntentClientSecret
            })
            
            let customerSheet = CustomerSheet(configuration: configuration, customer: customerAdapter)
            
            DispatchQueue.main.async {
                completion(.success(customerSheet))
            }
        })
        task.resume()
        
    }
    func preparePaymentSheet(payment:Double, job:JobPost, fromUser currentUser: User, toUser user:User, completion: @escaping (Result<PaymentSheet, PaymentErrorType>) -> ())  {
        let _id: String = job.id!
        guard let email = user.email else {
            completion(.failure(.missingEmail))
            return
        }
        // MARK: Fetch the PaymentIntent and Customer information from the backend
        var parameters = "{\n"
        if let fullname = user.fullname {
            parameters += "\"name\": \"\(fullname)\",\n"
        } else {
            // If fullname is nil, you can provide a default name or handle it as needed.
            parameters += "\"name\": \"Default Name\",\n"
        }
        parameters += """
            "amount": \(payment),
            "email": "\(email)",
            "jobId": "\(_id)",
            "userId": "\(currentUser.id)"
        }
        """
        
        Log.i("Job ID: \(parameters)")
        
        // Formulate the job data
        let jobData = parameters.data(using: .utf8)
        
        if let url = URL(string: FirebaseFunctions.CREATE_PAYMENT_INTENT) {
            var request = URLRequest(url: url)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = jobData
            
            let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else {
                    completion(.failure(.jsonError))
                    return
                }
                if let message = json["message"] as? String, let success = json["success"] as? Int, success == 0 {
                    // There was already a successful charge no need to prepare the payment sheet
                    completion(.failure(.alreadyPaidError))
                    return
                }
                
                guard let customerId = json["customer"] as? String,
                      let customerEphemeralKeySecret = json["ephemeralKey"] as? String,
                      let paymentIntentDict = json["paymentIntent"] as? [String: Any],
                      let paymentIntentClientSecret = paymentIntentDict["client_secret"] as? String,
                      let publishableKey = json["publishableKey"] as? String,
                      let self = self else {
                    
                    completion(.failure(.jsonError))
                    return
                }
                
                STPAPIClient.shared.publishableKey = publishableKey
                // Create a PaymentSheet instance
                var configuration = PaymentSheet.Configuration()
                configuration.merchantDisplayName = "Example, Inc." //TODO: Include the actual name of the company
                configuration.customer = .init(id: customerId, ephemeralKeySecret: customerEphemeralKeySecret)
                // Set `allowsDelayedPaymentMethods` to true if your business handles
                // delayed notification payment methods like US bank accounts.
                configuration.allowsDelayedPaymentMethods = true
                
                DispatchQueue.main.async {
                    completion(.success(PaymentSheet(paymentIntentClientSecret: paymentIntentClientSecret, configuration: configuration)))
                }
            })
            task.resume()
        } else {
            completion(.failure(.invalidUrl))
        }
    }
    
//    func requstRefund(jobID: String) async -> Result<String, PaymentErrorType> {
//       
//        guard let refreshToken = try? await AuthService.shared.userSession?.getIDToken()
//        else{ return .failure(.serverError) }
//        
//        let url = URL(string: FirebaseFunctions.REQUEST_REFUND_PAYMENTS)
//        let params: [String:String] = ["jobId":jobID]
//      
//        var request = URLRequest(url: url!)
//        request.httpBody = try? JSONSerialization.data(withJSONObject: params)
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.addValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")
//        request.httpMethod = "POST"
//        request.httpBody = try? JSONSerialization.data(withJSONObject: params)
//        
//        let session = URLSession.shared
//        do {
//            let response = try await session.data(for: request)
//            return .success("A refund was successfully posted")
//        } catch {
//            return .failure(.serverError)
//        }
//        
//    }
    
}
