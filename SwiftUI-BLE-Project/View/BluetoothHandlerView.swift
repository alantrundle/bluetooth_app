//
//  ListView.swift
//  SwiftUI-BLE-Project
//
//  Created by Alan Trundle on 2024/11/04.

import SwiftUI

struct BluetoothDeviceListView: View {
    @EnvironmentObject var bleManager: CoreBluetoothViewModel
    @State var isSearching = false

    var body: some View {
        
        ZStack {
            bleManager.navigationToDetailView(isDetailViewLinkActive: $bleManager.isConnected)
            
            VStack {
                if !bleManager.isConnected {
                    Button(action: {
                        if bleManager.isSearching {
                            bleManager.stopScan()
                        } else {
                            bleManager.startScan()
                            bleManager.isSearching = true
                        }
                    }) {
                        Text(bleManager.isSearching ? "Stop Scanning" : "Start Scan")
                    }
                    
                    Text(bleManager.isBlePower ? "" : "Bluetooth setting is Off")
                        .padding(10)
                    
                    List {
                        BluetoothDeviceCells()
                    }
                }
            }
        }
        
        .navigationTitle("Mifare Toolbox")
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            //bleManager.createDatabase()
        }
        
    }
    
}
        
    struct BluetoothDeviceCells: View {
        @EnvironmentObject var bleManager: CoreBluetoothViewModel
        
        var body: some View {
            ForEach(0..<bleManager.foundPeripherals.count, id: \.self) { num in
                Button(action: {
                    bleManager.stopScan()
                    bleManager.connectPeripheral(bleManager.foundPeripherals[num])
                    
                }) {
                    HStack {
                        Text("\(bleManager.foundPeripherals[num].name)")
                        Spacer()
                        Text("\(bleManager.foundPeripherals[num].rssi) dBm")
                    }
                }
            }
        }
    }

