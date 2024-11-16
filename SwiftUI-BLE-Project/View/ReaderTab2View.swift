//
//  Untitled.swift
//  Mifare Toolbox
//
//  Created by Alan Trundle on 05/11/2024.
//
import SwiftUI
import UIKit

// 2nd tab

struct test: View {
    
    var body: some View {
        Text("Hi")
    }
    
}

// Main View
struct CardDataEditorView: View {
    
    @EnvironmentObject var bleManager: CoreBluetoothViewModel
    @State private var showingAlert = false
    
    var body: some View {
        VStack { // This combines both sections into one vertical layout
            
            // First Section
            VStack {
                HStack {
                    Text("Mifare Card Read/ Writer")
                        .font(.system(size: 20))
                }
               
                HStack {
                    Button("Read") {
                        print("Read tapped!")
                    }
                    .frame(width: 100, height: 50)
                    .background(Color.yellow)
                    .padding(.leading, 15)
                    .padding(.bottom, 15)
                    
                    Spacer()
                }
                
                HStack {
                    Text("Card ID")
                        .padding(.leading, 20)
                        .font(Font.subheadline)
                        .frame(width: 100, alignment: .leading)
                        .multilineTextAlignment(.leading)
                    
                    Text(bleManager.decodedHeadString?.head.uid ?? "None")
                        .font(Font.subheadline)
                        .frame(width: 100, alignment: .leading)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                
                HStack {
                    Text("Card Type")
                        .padding(.leading, 20)
                        .font(Font.subheadline)
                        .frame(width: 100, alignment: .leading)
                    
                    Text(bleManager.decodedHeadString?.head.type ?? "Unknown")
                        .font(Font.subheadline)
                        .frame(width: 100, alignment: .leading)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
            }
            .alert(isPresented: $bleManager.showAlert) {
                Alert(title: Text(bleManager.error_title),
                      message: Text(bleManager.error_msg))
            }
           
            // Second Section
            VStack {
                List {
                    ReaderDataCells()
                }
                .padding(.top, 20)
            }
            
            Spacer()
        }
    }
}


// Cells for Reader/Writer View
struct ReaderDataCells: View {
    @EnvironmentObject var bleManager: CoreBluetoothViewModel
    
    var body: some View {
        ForEach(0..<(bleManager.decodedSectorString?.count ?? 0), id: \.self) { num in
            Section(header: Text("Sector \(bleManager.decodedSectorString![num].sector.sectorID)")) {
                ForEach(0..<bleManager.decodedSectorString![num].sector.data.count, id: \.self) { j in
                    
                    VStack {
                        if (bleManager.decodedSectorString![num].sector.data[j].blockReaderr.isEmpty) {
                            Text("[\(bleManager.decodedSectorString![num].sector.data[j].blockID)] \(bleManager.decodedSectorString![num].sector.data[j].blockData)")
                                .font(.system(size:12))
                        } else {
                            Text("[\(bleManager.decodedSectorString![num].sector.data[j].blockID)] \(bleManager.decodedSectorString![num].sector.data[j].blockReaderr)")
                                .font(.system(size:12))
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
    }
}
