//
//  DetailView.swift
//  SwiftUI-BLE-Project
//
//  Created by Alan Trundle on 2024/11/04.
//
import SwiftUI
import UIKit

import SwiftUI

struct HexKeyboard: View {
    @Binding var text: String         // Binding to the text field
    @FocusState var isFocused: Bool    // Track focus state

    private let keys: [String] = [
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
        "A", "B", "C", "D", "E", "F", "⌫"
    ]

    var body: some View {
        VStack {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                ForEach(keys, id: \.self) { key in
                    Button(action: {
                        handleKeyPress(key)
                    }) {
                        Text(key)
                            .font(.title)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
        .padding(.bottom, isFocused ? 0 : 100) // Adjust for keyboard visibility
    }

    private func handleKeyPress(_ key: String) {
        if key == "⌫" {
            // Backspace logic
            if !text.isEmpty {
                text.removeLast()
            }
        } else {
            // Append the key to the text
            text.append(key)
        }
    }
}

enum Field: String {
    case keyA
    case keyB
}





struct DetailView: View {
    @EnvironmentObject var bleManager: CoreBluetoothViewModel
    @State private var showingAlert = false
    
    var body: some View {
        TabView {
            CardSecurityEditorView()
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

// 1st tab
// ToDo
// Switch view to SecurityKeyDetail view passing in id from database
struct CardSecurityEditorView: View {
    @EnvironmentObject var bleManager: CoreBluetoothViewModel
    @State var sql:DBManager = DBManager()
    
    var body: some View {
        VStack {
            
            HStack {
                Text("Mifare Card Security")
            }
            .font(.system(size:20))
            if sql.isLoading {
                ProgressView("loading...")
            }
            else {
                List {
                    SecurityKeyDataCells(sql: sql)
                }
            }
            
            Spacer()
            
        }.task{
            await loadDataMain(sql: sql)
        }
    }
}


// 2nd tab
// Editor View
struct CardDataEditorView: View {
    
    @EnvironmentObject var bleManager: CoreBluetoothViewModel
    @State private var showingAlert = false
    
    var body: some View {
        VStack {
            
            HStack {
                Text("Mifare Card Security")
            }
            .font(.system(size:20))
            
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
            
            VStack {
                
                List {
                    ReaderDataCells()
                }
                .padding(.top, 20)
                
            }
            
        }
        .alert(isPresented: $bleManager.showAlert) {
            Alert(title: Text(bleManager.error_title),
                  message: Text(bleManager.error_msg)
            )}
        
    }
}

// Card Reader Tab
// Cells for Editor View
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

// Cells for Security Key View
// Pass mykeys[num].id as t to SecurityKeyDetail
struct SecurityKeyDataCells: View {
    @State var sql: DBManager
    @EnvironmentObject var bleManager: CoreBluetoothViewModel
    @State var keys:[cardSecurityKeys] = []
    
    var body: some View {
        
        ForEach(0..<(sql.mykeys.count), id: \.self) { num in
            
            NavigationLink(destination: SecurityKeyDetail(sql:sql, row: num, dbid: sql.mykeys[num].dbid)) {
                
                VStack {
                    HStack {
                        Image(systemName: "creditcard.and.123")
                        
                        Text("\(sql.mykeys[num].dbid)")
                            .font(.system(size:14))
                        
                        Text(sql.mykeys[num].name)
                            .font(.system(size:14))
                    }
                }
                .onAppear {
                    sql.list_keys = []
                    sql.generateKeyDataArray = true
                    
                }
            }
        }
    }
}

// Lists Sector Key Data
// Main View
// Debug SecurityKeyDetailCell not refreshing

struct SecurityKeyDetail : View  {
    @EnvironmentObject var bleManager: CoreBluetoothViewModel
    
    @ObservedObject var sql: DBManager
    @State var row: Int
    @State var dbid: Int
    @State var isShowing = false
    @State var keys:[cardSecurityKeys] = []
    @State var showSaveAlert:Bool = false
    @State var showNonSaveAlert:Bool = false
    
    
    var body: some View {
        
        VStack {
            List {
                if sql.isLoading {
                    ProgressView("loading...")
                }
                else {
                    SecurityKeyDetailCell(sql:sql, row: row, dbid:dbid)
                }
            }
            .id(UUID())
        }
        .task {
            await loadData(sql:sql, dbid:dbid)
        }
        
        VStack {
            Button("Save Keys") {
                
                var changed:Bool = true
                
                if changed {
                    showSaveAlert = sql.update_keys(row: row, dbid: dbid, master_table: sql.mykeys, keys_table: sql.list_keys)
                    print("Saved Data")
                }else {
                    showNonSaveAlert = true
                }
            }
            .frame(width: 100, height: 50)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))
        }
        .alert("Save Confirmation", isPresented: $showNonSaveAlert) {
            Button("OK") {
                // Action for OK
                print("Non Confirmed")
            }
        } message: {
            Text("No changes to commit.")
        }
        .alert("Save Confirmation", isPresented: $showSaveAlert) {
            Button("OK") {
                // Action for OK
                print("Data has been saved")
            }
        } message: {
            Text("Keys for \(sql.mykeys[row].name) have been saved")
        }
    }
}

struct SecurityKeyDetailCell : View  {
    
    @ObservedObject var sql:DBManager
    @State var row:Int
    @State var dbid:Int
    
    var body: some View {
        
        ForEach(0..<(sql.list_keys.count), id: \.self) { num in
            
            Section(header: Text("Sector \(sql.list_keys[num].sectorNum) [\(sql.mykeys[row].name)]")) {
                
                NavigationLink(destination: EditSecurityKey(row: num, dbid: dbid, sql: sql)) {
                    
                    HStack {
                        
                        Image(systemName: "key.horizontal")
                        Text("A").font(.system(size:14))
                        Text(sql.list_keys[num].keyA).font(.system(size:14))
                        
                        Image(systemName: "key.horizontal")
                        Text("B").font(.system(size:14))
                        Text(sql.list_keys[num].keyB).font(.system(size:14))
                        
                        Spacer()
                        
                    }
                    .id(UUID())
                }
            }
        }
    }
    
}



struct EditSecurityKey: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State var row:Int
    @State var dbid: Int
    @ObservedObject var sql: DBManager
    @State var selected:Int = 0
    
    @State var temp:String = "1K Mifare"
    
    @FocusState private var focusedField:Field?
    
    private let maxCharacters = 12
    
    var body: some View {

    
        VStack {
            HStack {
                Text("Sector \(sql.list_keys[row].sectorNum)")
                    .font(.system(size:20))
            }
            
            HStack {
                Text("A")
                    .font(Font.system(size: 14))
                
                TextField("sector A key...", text: $sql.list_keys[row].keyA)
                    .background(focusedField == .keyA ? Color.mint : Color.clear)
                    .focused($focusedField, equals: .keyA)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))
                    .font(Font.system(size: 14))
                    .onTapGesture {
                        focusedField = .keyA
                    }
                    .onChange(of: sql.list_keys[row].keyA) { newValue in
                        // Limit the input to maxCharacters
                        if newValue.count > maxCharacters {
                            sql.list_keys[row].keyA = String(newValue.prefix(maxCharacters))
                        }
                    }
            
                Spacer()
            }
            
            .padding(.leading, 15)
            .padding(.trailing, 15)
            
            HStack {
                
                Text ("B")
                    .font(Font.system(size: 14))
         
                TextField("sector B key...", text: $sql.list_keys[row].keyB)
                    .background(focusedField == .keyB ? Color.mint : Color.clear)
                    .focused($focusedField, equals: .keyB)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))
                    .font(Font.system(size: 14))
                    .onTapGesture {
                        focusedField = .keyB
                    }
                    .onChange(of: sql.list_keys[row].keyB) { newValue in
                        // Limit the input to maxCharacters
                        if newValue.count > maxCharacters {
                            sql.list_keys[row].keyB = String(newValue.prefix(maxCharacters))
                        }
                    }
                
                Spacer()
            }
            .padding(.leading, 15)
            .padding(.trailing, 15)
            
            VStack {
                
                HStack {
                    
                    // Custom Hex Keyboard
                    HexKeyboard(text: Binding(
                        get: { focusedField == .keyA ? sql.list_keys[row].keyA : sql.list_keys[row].keyB },
                        set: { if focusedField == .keyA { sql.list_keys[row].keyA = $0 } else { sql.list_keys[row].keyB = $0 } }
                    ))
                    .frame(height: 250)
                    .padding()
                    
                }
                
            }
            .padding(.top, 50)
            .onAppear {
                // Automatically focus the first name field when the view appears
                focusedField = .keyA
            }
        }
        
        Spacer()
        
        VStack {
            HStack {
                Button("Revert") {
    
                    for index in 0..<(sql.mykeydata.count) {
                        
                        // find original values, and replace them
                        if (sql.mykeydata[index].sectorNum == sql.list_keys[row].sectorNum && sql.mykeydata[index].dbid == dbid) {
                            
                            sql.list_keys[row].keyA = sql.mykeydata[index].keyA
                            sql.list_keys[row].keyB = sql.mykeydata[index].keyB
                            
                        }
                    }
                }
                
                .frame(width: 100, height: 50)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))
                
                Button("Done") {
                    print("done pressed")
                    presentationMode.wrappedValue.dismiss()
                }
                .frame(width: 100, height: 50)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))
            }
            
        }
        .navigationBarBackButtonHidden(true)
        
    }
        
}

func loadDataMain(sql: DBManager) async {
    
    DispatchQueue.main.async{
        
        sql.isLoading = true
        
        //bleManager.createDatabase() // creates DB if it doesn't exist
        sql.db = sql.openDatabase()
        sql.mykeys = sql.read()
        // populate row array from main table
        sql.mykeydata = sql.convertKeyDataToArray(thsArray: sql.mykeys)
        sql.isLoading = false
    }
    
}
    

func loadData(sql: DBManager, dbid:Int) async {
    
    DispatchQueue.main.async{
        if (sql.generateKeyDataArray == true) {
            
            sql.generateKeyDataArray = false
            sql.isLoading = true
            
            for index in 0..<(sql.mykeydata.count) {
                if sql.mykeydata[index].dbid == dbid  {
                    let newEntry = cardSecurityKeys(id: sql.mykeydata[index].id, dbid: sql.mykeydata[index].dbid, sectorNum: sql.mykeydata[index].sectorNum, keyA: sql.mykeydata[index].keyA, keyB: sql.mykeydata[index].keyB)
                    sql.list_keys.append(newEntry)
                    
                }
            }
        }
        
        sql.isLoading = false
    }

}

// A SwiftUI preview.
#Preview {
    DetailView().environmentObject(CoreBluetoothViewModel())
    //SecurityKeyDetail(sql:DBManager(), t:0).environmentObject(CoreBluetoothViewModel())
    //EditSecurityKey(row: 0, sql: sql, table: 0)
}

