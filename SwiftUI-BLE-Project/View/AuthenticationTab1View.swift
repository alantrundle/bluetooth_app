//
//  DetailView.swift
//  SwiftUI-BLE-Project
//
//  Created by Alan Trundle on 2024/11/04.
//
import SwiftUI
import UIKit

enum Field: String {
    case keyA
    case keyB
}

func loadDataMain(sql: DBManager) async {
    
    DispatchQueue.main.async{
        
        sql.isLoading = true
        
        sql.db = sql.openDatabase()
        sql.keyProfileTable = sql.readProfileTable()
        sql.keysTable = sql.readKeysTable()
        sql.cardTypesTable = sql.readcardTypesTable()
        let close = sql.closeDB(db: sql.db)
        
        print(sql.keyProfileTable[1].profileName)
        
        sql.isLoading = false
    }
}
    
func loadDataListKeys(sql: DBManager, dbid:Int) async {
    
    DispatchQueue.main.async{

        if (sql.generateKeyDataArray == true) {
            
            sql.generateKeyDataArray = false
            sql.isLoading = true
            
            sql.db = sql.openDatabase()
            sql.list_keys = sql.readKeysTableByProfileID(profileID: dbid)
            let close = sql.closeDB(db: sql.db)
 
        }
        
        sql.isLoading = false
    }
}
   
struct FocusableTextEditor: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.text = text

        // Disable the keyboard
        textView.inputView = UIView()
        textView.delegate = context.coordinator

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: FocusableTextEditor

        init(_ parent: FocusableTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}

/* Custom HEX Keyboard */
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


struct CardSecurityEntryView: View {
    
    @EnvironmentObject var bleManager: CoreBluetoothViewModel
    @EnvironmentObject var sql: DBManager
    @State var showAlert: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Mifare Card Authentication Admin")
                    .font(.system(size: 20))
            }
            
            HStack {
                Spacer()
                
                Button("Setup Database") {
                    showAlert = true
                }
                .frame(width: 150, height: 60)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))
                .animation(.easeInOut, value: showAlert)
                
                Spacer()
            }
            .padding(.bottom, 20)
           
            List {
                CardSecurityEntryCells()
            }
            .task {
                do {
                    if sql.checkDatabaseExists() {
                       try? await loadDataMain(sql: sql)
                    }
                } catch {
                    print("Error loading data: \(error)")
                }
            }
        }
        .onAppear {
            sql.generateKeyDataArray = true
            print("DEBUG \(sql.checkDatabaseExists())")
        }
        .alert("Setup Confirmation", isPresented: $showAlert) {
            Button("Cancel") {
                print("Setup aborted")
            }
            Button("Continue") {
                performDatabaseSetup()
            }
        } message: {
            Text("You are about to delete the database (if one exists), and create a new one.\nPlease confirm to continue?")
                .multilineTextAlignment(.leading)
        }
    }
    
    func performDatabaseSetup() {
        sql.db = sql.openDatabase()
        sql.setupDatabase()
        sql.keyProfileTable = sql.readProfileTable()
        sql.closeDB(db: sql.db)
        print("Setup done")
    }
}



// Cells for Security Key View
// Pass mykeys[num].id as t to SecurityKeyDetail
struct CardSecurityEntryCells: View {
    @EnvironmentObject var bleManager: CoreBluetoothViewModel
    @EnvironmentObject var sql: DBManager
    @State var keys:[cardSecurityKeysTable] = []
    @State var showAlert: Bool = false
    
    var body: some View {
        
        ForEach(0..<(sql.keyProfileTable.count), id: \.self) { profile_index in
            
            NavigationLink(destination: SecurityKeyDetailView(varTableRow: profile_index, varProfileID: sql.keyProfileTable[profile_index].id)) {
                VStack {
                    HStack {
                        
                        Image(systemName: "creditcard.and.123")
                        
                        Text("\(sql.keyProfileTable[profile_index].id)")
                            .font(.system(size:14))
                        
                        Text(sql.keyProfileTable[profile_index].profileName)
                            .font(.system(size:14))
                        
                    }
                }
            }
        }
    }
}

// Lists Sector Key Data
struct SecurityKeyDetailView : View  {
    @EnvironmentObject var bleManager: CoreBluetoothViewModel
    @EnvironmentObject var sql: DBManager
    
    @State var varTableRow: Int?
    @State var varProfileID: Int?
    @State var varKeysTable:[cardSecurityKeysTable] = []
    
    @State var isShowing = false
    @State var showSaveAlert:Bool = false
    @State var showNonSaveAlert:Bool = false
    //@State var proxy: ScrollViewProxy?
    @State var scrollVal:Int?
    
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        
        VStack {
            
            HStack {
                
                Text("\(sql.keyProfileTable[varTableRow ?? 0].typeName)")
                    .font(Font.system(size: 30))
            }
            .padding(.bottom, 30)
            .padding(.top, 15)
            
            HStack {
                TextField((sql.keyProfileTable[varTableRow ?? 0].profileName), text: $sql.keyProfileTable[varTableRow ?? 0].profileName)
                    .frame(width:300, height:40)
                    .padding(.leading, 15)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.teal))
                    .background(Color.clear)
                    .cornerRadius(8)
                    .font(Font.system(size: 14))
                    
                    
                Spacer()
            }
            
        }
        .padding(.trailing, 10)
        .padding(.leading, 15)
        .navigationTitle("Key Management")
        
        Divider()
        
        VStack {
            
            if sql.isLoading {
                ProgressView("loading...")
            }
            else {
                ScrollViewReader { proxy in
                    
                    List {
                        SecurityKeyDetailCells(varTableRow: varTableRow ?? 0, varProfileID: varProfileID ?? 0)
                    }
                    .onChange(of: scrollVal) { newIndex in
                        // Trigger scroll when `scrollToIndex` changes
                        if let index = newIndex {
                            withAnimation {
                                proxy.scrollTo(index, anchor: .center)
                            }
                        }
                    }
                    .onAppear() {
                        DispatchQueue.main.async {
                            if (!sql.isLoading) {
                                scrollVal = sql.scrollToIndex
                                print("Scrolling to index \(scrollVal ?? 0)")
                            }
                        }
                    }
                }
            }
        }
        .task {
            await loadDataListKeys(sql:sql, dbid: varProfileID ?? 0)
        }
        .onAppear {
            sql.isLoading = true
            isTextFieldFocused = true
        }
        .onDisappear {
            sql.scrollToIndex = -1
            scrollVal = -1
        }
        
        VStack {
            Button("Save Keys") {
                
                let changed:Bool = true
                
                if changed {
                    sql.db = sql.openDatabase()
                    
                    showSaveAlert = sql.update_keys(keys_table: sql.list_keys)
                    let result = sql.UpdateCardSecurityProfiles(id: varProfileID ?? 0, profileName: sql.keyProfileTable[varTableRow ?? 0].profileName)
                    print(sql.closeDB(db: sql.db))
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
                sql.isHighlighted = false
                print("Data has been saved")
            }
        } message: {
            Text("Keys for \(sql.keyProfileTable[varTableRow ?? 0].profileName) have been saved")
        }
    }
}

struct SecurityKeyDetailCells : View  {
    
    @EnvironmentObject var sql:DBManager
    @State var varTableRow:Int
    @State var varProfileID:Int
    
    var body: some View {
    
        ForEach(0..<(sql.list_keys.count), id: \.self) { key_num in
            
            Section(header: Text("Sector \((sql.list_keys[key_num].sectorNum)) [\(sql.keyProfileTable[varTableRow].profileName)]")) {
                
                NavigationLink(destination: EditSecurityKey(varTableRow: key_num, varProfileID: varProfileID)) {
                    
                    HStack {
                        
                        Image(systemName: "key.horizontal")
                        Text("A").font(.system(size:12))
                        Text((sql.list_keys[key_num].keyA)).font(.system(size:12))
                        
                        Image(systemName: "key.horizontal")
                        Text("B").font(.system(size:12))
                        Text(sql.list_keys[key_num].keyB).font(.system(size:12))
                        
                        Spacer()
                        
                    }
                    .padding(4)
                    .border(key_num == sql.scrollToIndex && sql.isHighlighted ? Color.red : Color.clear)
                    .id(key_num)
                }
            }
        }
    }
}

struct EditSecurityKey: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var sql: DBManager
    
    @State var varTableRow:Int
    @State var varProfileID: Int
    
    @State var selected:Int = 0
    
    @FocusState private var focusedField:Field?
    
    private let maxCharacters = 12
    
    var body: some View {

        VStack {
            HStack {
                Text("Sector \(sql.list_keys[varTableRow].sectorNum)")
                    .font(.system(size:20))
            }
            
            HStack {
                Text("A")
                    .font(Font.system(size: 14))
                
                FocusableTextEditor(text: $sql.list_keys[varTableRow].keyA)
                    .frame(width: 300, height: 40)
                    .padding(.leading, 15)
                    .background(Color.clear)
                    .focused($focusedField, equals: .keyA)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(focusedField == .keyA ? Color.red : Color.gray))
                    .font(Font.system(size: 14))
                    .onTapGesture {
                        
                        focusedField = .keyA
                        
                        if sql.list_keys[varTableRow].keyA.count >= maxCharacters {
                            print("A should be highlighted")
                        }
                    }
                    .onChange(of: sql.list_keys[varTableRow].keyA) { newValue in
                        // Limit the input to maxCharacters
                        if newValue.count > maxCharacters {
                            sql.list_keys[varTableRow].keyA = String(newValue.prefix(maxCharacters))
                        }
                    }
                
                Spacer()
            }
            
            .padding(.leading, 15)
            .padding(.trailing, 15)
            
            HStack {
                
                Text ("B")
                    .font(Font.system(size: 14))
                
                FocusableTextEditor(text: $sql.list_keys[varTableRow].keyB)
                    .frame(width: 300, height: 40)
                    .padding(.leading, 15)
                    .background(Color.clear)
                    .focused($focusedField, equals: .keyB)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(focusedField == .keyB ? Color.red : Color.gray))
                    .font(Font.system(size: 14))
                    .onTapGesture {
                        focusedField = .keyB
                        print("No keyboard")
                        
                        if sql.list_keys[varTableRow].keyB.count >= maxCharacters {
                            print("B should be highlighted")
                        }
                    }
                    .onChange(of: sql.list_keys[varTableRow].keyB) { newValue in
                        // Limit the input to maxCharacters
                        if newValue.count > maxCharacters {
                            sql.list_keys[varTableRow].keyB = String(newValue.prefix(maxCharacters))
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
                        get: { focusedField == .keyA ? sql.list_keys[varTableRow].keyA : sql.list_keys[varTableRow].keyB },
                        set: { if focusedField == .keyA { sql.list_keys[varTableRow].keyA = $0 } else { sql.list_keys[varTableRow].keyB = $0 } }
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
                        if (sql.keysTable[index].sectorNum == sql.list_keys[varTableRow].sectorNum && sql.keysTable[index].id == varProfileID) {
                            
                            sql.list_keys[varTableRow].keyA = sql.keysTable[index].keyA
                            sql.list_keys[varTableRow].keyB = sql.keysTable[index].keyB
                            
                        }
                    }
                }
                
                .frame(width: 100, height: 50)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))
                
                Button("Done") {
                    print("done pressed")
                    sql.scrollToIndex = varTableRow
                    sql.isHighlighted = true
                    print(sql.scrollToIndex)
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

#Preview {
    SecurityKeyDetailView()
}
