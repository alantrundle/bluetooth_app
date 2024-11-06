//
//  DetailView.swift
//  SwiftUI-BLE-Project
//
//  Created by Alan Trundle on 2024/11/04.
//
import SwiftUI
import UIKit

/* Custom HEX Keyboard */

enum Field: String {
    case keyA
    case keyB
}

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


/* Custom HEX Keyboard */


struct CardSecurityEditorView: View {

    @EnvironmentObject var bleManager: CoreBluetoothViewModel
    @State var sql:DBManager = DBManager()
    
    var body: some View {
        VStack {
            
            HStack {
                Text("Mifare Card Authentication Admin")
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


// Cells for Security Key View
// Pass mykeys[num].id as t to SecurityKeyDetail
struct SecurityKeyDataCells: View {
    @State var sql: DBManager
    @EnvironmentObject var bleManager: CoreBluetoothViewModel
    @State var keys:[cardSecurityKeysTable] = []
    @State var showAlert: Bool = false
    
    var body: some View {
        
        VStack(alignment: .center) {
            HStack {
                Button("Setup Database") {
                    showAlert = true
                }
                .frame(width: 150, height: 60)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))
            
            }
        }
        .padding(.bottom, 20)
        .alert("Setup Confirmation", isPresented: $showAlert) {
            Button("Cancel") {
                // Action for OK
                print("Setup aborted")
            }
            Button("Continue") {
                sql.db = sql.openDatabase()
                sql.setupDatabase()
                
                sql.keyProfileTable = sql.readProfileTable()
                sql.closeDB(db: sql.db)
                print("Setup done")
            }
        } message: {
            Text("You are about to delete the database (if one exists), and create a new one\nPlease confirm to contiune?")
                .multilineTextAlignment(.leading)
        }
        
        ForEach(0..<(sql.keyProfileTable.count), id: \.self) { num in
            
            NavigationLink(destination: SecurityKeyDetail(sql:sql, row: num, dbid: sql.keyProfileTable[num].profileID)) {
                
                VStack {
                    HStack {
                        Image(systemName: "creditcard.and.123")
                        
                        Text("\(sql.keyProfileTable[num].profileID)")
                            .font(.system(size:14))

                        Text(sql.keyProfileTable[num].profileName)
                                    .font(.system(size:14))
                        
                    }
                }
                .onAppear {
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
    @State var keys:[cardSecurityKeysTable] = []
    @State var showSaveAlert:Bool = false
    @State var showNonSaveAlert:Bool = false
    
    //@Binding var listKeys:cardSecurityKeysTable?
    
    
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
                
                let changed:Bool = true
                
                if changed {
                    print(sql.list_keys)
                    showSaveAlert = sql.update_keys(keys_table: sql.list_keys)
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
            Text("Keys for \(sql.keyProfileTable[row].profileName) have been saved")
        }
    }
}

struct SecurityKeyDetailCell : View  {
    
    @ObservedObject var sql:DBManager
    @State var row:Int
    @State var dbid:Int
    
    //@Binding var listKeys:cardSecurityKeysTable?
    
    var body: some View {
        
        ForEach(0..<(sql.list_keys.count), id: \.self) { num in
            
            Section(header: Text("Sector \(sql.list_keys[num].sectorNum) [\(sql.keyProfileTable[row].profileName)]")) {
                
                NavigationLink(destination: EditSecurityKey(row: num, dbid: dbid, sql: sql)) {
                    
                    HStack {
                        
                        Image(systemName: "key.horizontal")
                        Text("A").font(.system(size:12))
                        Text(sql.list_keys[num].keyA).font(.system(size:12))
                        
                        Image(systemName: "key.horizontal")
                        Text("B").font(.system(size:12))
                        Text(sql.list_keys[num].keyB).font(.system(size:12))
                        
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
                        
                        if sql.list_keys[row].keyA.count >= maxCharacters {
                            print("should be highlighted")
                        }
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
                        
                        if sql.list_keys[row].keyB.count >= maxCharacters {
                            print("should be highlighted")
                        }
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
            .onAppear {
                UITextField.appearance().inputView = UIView()
            }
            
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
    
                    for index in 0..<(sql.keysTable.count) {
                        
                        // find original values, and replace them
                        if (sql.keysTable[index].sectorNum == sql.list_keys[row].sectorNum && sql.keysTable[index].keyID == dbid) {
                            
                            sql.list_keys[row].keyA = sql.keysTable[index].keyA
                            sql.list_keys[row].keyB = sql.keysTable[index].keyB
                            
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
        
        //sql.setupDatabase() // creates DB if it doesn't exist
        
        sql.db = sql.openDatabase()
        sql.keyProfileTable = sql.readProfileTable()
        
        sql.db = sql.openDatabase()
        sql.keysTable = sql.readKeysTable()
        
        sql.db = sql.openDatabase()
        sql.cardTypesTable = sql.readcardTypesTable()
        
        sql.isLoading = false
    }
    
}
    

func loadData(sql: DBManager, dbid:Int) async {
    
    DispatchQueue.main.async{
        if (sql.generateKeyDataArray == true) {
            
            sql.generateKeyDataArray = false
            sql.isLoading = true
            
            sql.db = sql.openDatabase()
            sql.list_keys = sql.readKeysTableByProfileID(profileID: dbid)
        }
        
        sql.isLoading = false
    }

}
