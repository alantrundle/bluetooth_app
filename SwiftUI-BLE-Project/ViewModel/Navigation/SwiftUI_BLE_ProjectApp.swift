//
//  SwiftUI_BLE_ProjectApp.swift
//  SwiftUI-BLE-Project
//
//  Created by Alan Trundle on 2021/02/02.
//

import SwiftUI

@main
struct SwiftUI_BLE_ProjectApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(BLEManager())
                .environmentObject(DBManager())
        }
    }
}
