//
//  featrrrnewApp.swift
//  featrrrnew
//
//  Created by Buddie Booking on 6/27/23.
//

import SwiftUI

import FirebaseCore
import Stripe
import StripePaymentsUI
import FirebaseMessaging
import FirebaseFirestore
import FirebaseAuth

//@UIApplicationMain
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
//    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        Messaging.messaging().apnsToken = deviceToken
//    }
    

 
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        print(userInfo["link"])
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
       
        completionHandler(.list)
        
    }
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      
      //Configure firebase
      FirebaseApp.configure()
      
      UITabBarItem.appearance().badgeColor = UIColor(Color.primary)
      
      //Configure Stripe
      StripeAPI.defaultPublishableKey="sk_test_51NV3D4HPhoixtOLjK1Qij1OP4CXHVfSfOzVI1sg0690oEWt6prVeM68ZNpbU0l7MgGfKAOvhKYvTSW2wk3hEwgOF00zGx31mFr"
      
      
      Messaging.messaging().delegate = self
      
      
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      
      UNUserNotificationCenter.current().requestAuthorization(options: authOptions) {
          (granted, error) in
          guard granted else { return }
          DispatchQueue.main.async {
              application.registerForRemoteNotifications()
          }
      }
      /** Local emulator settings
       
       let settings = Firestore.firestore().settings
       settings.host = "172.20.10.2:8080"
       settings.cacheSettings = MemoryCacheSettings()
       settings.isSSLEnabled = false
       Firestore.firestore().settings = settings
      
       Auth.auth().useEmulator(withHost:"172.20.10.2", port:9099)
       
       */

      
      return true
  }
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
          print("Firebase registration token: \(String(describing: fcmToken))")
        
    }
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Registered for Apple Remote Notifications")
        Messaging.messaging().apnsToken = deviceToken
        
        // When user signs in, save the APNS token to Firebase
        // When the user signs out, delete the APNS token from Firebase (if possible)
        
        // On the backend, read a given user when a message is written and any APNS tokens and send a message
    }
}

@main
struct featrrrnewApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
                RootView()
        }
    }
}
