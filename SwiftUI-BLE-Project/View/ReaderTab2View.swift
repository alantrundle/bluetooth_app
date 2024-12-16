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
    
    @EnvironmentObject var bleManager: BLEManager
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
                        bleManager.readFullResponse = nil
                        bleManager.sendTestReadCard()
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
                    
                    Text(bleManager.isFullRead ? bleManager.readFullResponse?.rfidUID ?? "None" : bleManager.readBasicResponse?.rfidUID ?? "None")
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
                    
                    Text(bleManager.isFullRead ? bleManager.readFullResponse?.cardType ?? "Unknown" :bleManager.readBasicResponse?.cardType ?? "Unknown" )
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
    @EnvironmentObject var bleManager: BLEManager // Pass in the BLEManager as an environment object or property

    var body: some View {
              // Unwrap readFullResponse safely
              if let sectors = bleManager.readFullResponse?.sectors {
                  ForEach(sectors.indices, id: \.self) { sectorIndex in
                      SectorView(sector: sectors[sectorIndex])
                  }
              } else {
                  Text("No data available")
                      .foregroundColor(.gray)
              }
    }
}

struct SectorView: View {
    let sector: ReadFullResponse.Sector

    var body: some View {
        Section(header: Text("Sector \(sector.sector)").font(.headline)) {
            if let blocks = sector.blocks {
                ForEach(blocks.indices, id: \.self) { blockIndex in
                    BlockView(block: blocks[blockIndex])
                }
            } else {
                Text("No blocks available")
                    .foregroundColor(.gray)
            }
        }
    }
}


struct BlockView: View {
    let block: ReadFullResponse.Sector.Block

    var body: some View {
        HStack {
            Text("[\(block.block)] \(block.data ?? "No Data")")
                .font(.system(size: 12))
                .foregroundColor(block.status == "success" ? .primary : .red)
        }
        .padding(.vertical, 4) // Optional: Add spacing between rows
    }
}

