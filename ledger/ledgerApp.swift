//
//  ledgerApp.swift
//  ledger
//
//  Created by Pete Pongpeauk on 11/16/24.
//

import SwiftUI
import UserNotifications

@main
struct LedgerApp: App {
    @StateObject private var dataManager = DataManager()
    
    init() {
        requestNotificationPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
}
