//
//  ContentView.swift
//  SwiftUI-BLE-Project
//
//  Created by Alan Trundle on 2024/11/04.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            BluetoothDeviceListView()
            //BluetoothMain()
        }
    }
}
    
#Preview {
    ContentView()
}
