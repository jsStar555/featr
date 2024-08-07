//
//  Constants.swift
//  featrrrnew
//
//  Created by Buddie Booking on 7/25/23.
//

import Foundation

import Firebase

let COLLECTION_USERS = Firestore.firestore().collection("users")
let COLLECTION_JOBS = Firestore.firestore().collection("jobs")
let COLLECTION_NOTIFICATIONS = Firestore.firestore().collection("notifications")
let COLLECTION_MESSAGES = Firestore.firestore().collection("messages")

let COLLECTION_JOB_BID = Firestore.firestore().collection("job_proposal")

struct FirestoreConstants {
    static let Root = Firestore.firestore()
    static let UsersCollection = Root.collection("users")
    static let MessagesCollection = Root.collection("messages")
    static let JobProposalCollection = Root.collection("job_proposal")
}

struct FirebaseFunctions {
    
    static let CONFIRM_REFUND_REQUEST = "https://confirmrefundrequest-7tciwcgjna-uc.a.run.app"
    static let CREATE_PAYMENT_INTENT = "https://createpaymentintent-7tciwcgjna-uc.a.run.app"
    static let CREATE_PENDING_PAYMENT_REQUEST = "https://creatependingpaymentrequest-7tciwcgjna-uc.a.run.app"
    static let CREATE_SETUP_INTENT = "https://createsetupintent-7tciwcgjna-uc.a.run.app"
    static let FETCH_EPHEMERIAL = "https://customer-7tciwcgjna-uc.a.run.app"
    static let GET_ALL_PENDING_PAYMENTS = "https://getallpendingpayments-7tciwcgjna-uc.a.run.app"
    static let FETCH_DEFAULT_PAYMENT_METHODS = "https://fetchdefaultpaymentmethod-7tciwcgjna-uc.a.run.app"
    static let GET_BUYER_REFUND_REQUESTS = "https://getbuyerrefundrequests-7tciwcgjna-uc.a.run.app"
    static let STRIPE_WEBHOOK = "https://stripewebhook-7tciwcgjna-uc.a.run.app"
    static let UPDATE_DEFAULT_PAYMENT_METHOD = "https://updatedefaultpaymentmethod-7tciwcgjna-uc.a.run.app"
    static let UPDATE_PAYMENT_STATUS = "https://updatepaymentstatus-7tciwcgjna-uc.a.run.app"
    static let DEFAULT_PAYMENT = "https://defaultpayment-7tciwcgjna-uc.a.run.app"
    static let CREATE_CONNECT_ACCOUNT = "https://createconnectaccount-7tciwcgjna-uc.a.run.app"
    static let CREATE_ACCOUNT_LINK = "https://createaccountlink-7tciwcgjna-uc.a.run.app"
    static let FETCH_CONNECT_ACCOUNT = "https://fetchconnectaccount-7tciwcgjna-uc.a.run.app"
    static let TRANSFER_TO_CONNECT_ACCOUNT = "https://transfertoconnectaccount-7tciwcgjna-uc.a.run.app"
    static let CREATE_LOGIN_LINK = "https://createloginlink-7tciwcgjna-uc.a.run.app"
    static let GET_CONNECT_ACCOUNT_BALANCE = "https://getconnectaccountbalance-7tciwcgjna-uc.a.run.app"
    static let REQUEST_PAYOUT = "https://requestpayout-7tciwcgjna-uc.a.run.app"
    
}

// Media selection parameters
let MAX_PHOTOS = 10
let MAX_AUDIO_DURATION: CGFloat = 10
let DURATION_WARNING_OFFSET: CGFloat = 5
