//
//  TabViewMain.swift
//  Mifare Toolbox
//
//  Created by Alan Trundle on 05/11/2024.
//
import SwiftUI
import UIKit

struct DetailView: View {
    @EnvironmentObject var bleManager: BLEManager
    @State private var showingAlert = false
    
    var body: some View {
        TabView {
            CardSecurityEntryView()
                .tabItem {
                    Label("Security", systemImage: "list.dash")
                }
            CardDataEditorView()
                .tabItem {
                    Label("Details", systemImage: "filemenu.and.selection")
                }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if (bleManager.isConnected) {
                Button("Disconnect") {
                    bleManager.disconnectPeripheral()
                }
            } else {
                Text("Disconnected")
                    .foregroundColor(.red)
            }
        }
    }
    
    
}
