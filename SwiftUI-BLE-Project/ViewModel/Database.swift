//
//  Database.swift
//  Mifare Toolbox
//
//  Created by Alan Trundle on 18/10/2024.
//
import Foundation
import SQLite3
import SwiftUI

struct cardSecurityKeysTable:Identifiable  {

    var id: UUID
    var dbid: Int
    var name: String
    var sector0A: String
    var sector0B: String
    var sector1A: String
    var sector1B: String
    var sector2A: String
    var sector2B: String
    var sector3A: String
    var sector3B: String
    var sector4A: String
    var sector4B: String
    var sector5A: String
    var sector5B: String
    var sector6A: String
    var sector6B: String
    var sector7A: String
    var sector7B: String
    var sector8A: String
    var sector8B: String
    var sector9A: String
    var sector9B: String
    var sector10A: String
    var sector10B: String
    var sector11A: String
    var sector11B: String
    var sector12A: String
    var sector12B: String
    var sector13A: String
    var sector13B: String
    var sector14A: String
    var sector14B: String
    var sector15A: String
    var sector15B: String
}

struct cardSecurityKeys: Identifiable {
    
    var id: UUID
    var dbid: Int
    var sectorNum: Int
    var keyA: String
    var keyB: String
    
}

class DBManager: NSObject, ObservableObject {
    
    override init() {
        super.init()
    }
    
    @Published var db:OpaquePointer?
    @Published var mykeys:[cardSecurityKeysTable] = [cardSecurityKeysTable]()
    @Published var mykeydata:[cardSecurityKeys] = [cardSecurityKeys]()
    
    @Published var list_keys:[cardSecurityKeys] = [cardSecurityKeys]()
    @Published var generateKeyDataArray: Bool = true
    @Published var isLoading: Bool = false
    
    let dataPath: String = "MifareDB"
    
    func convertKeyDataToArray(thsArray:[cardSecurityKeysTable]) -> [cardSecurityKeys] {
        
        var mykeydata:[cardSecurityKeys] = []
        var newEntry:cardSecurityKeys
            
        for index in 0..<(thsArray.count) {
            
            newEntry = cardSecurityKeys(id: UUID(), dbid: thsArray[index].dbid, sectorNum: 0, keyA: thsArray[index].sector0A, keyB: thsArray[index].sector0B)
            mykeydata.append(newEntry)
            
            newEntry = cardSecurityKeys(id: UUID(), dbid: thsArray[index].dbid, sectorNum: 1, keyA: thsArray[index].sector1A, keyB: thsArray[index].sector1B)
            mykeydata.append(newEntry)
            
            newEntry = cardSecurityKeys(id: UUID(), dbid: thsArray[index].dbid, sectorNum: 2, keyA: thsArray[index].sector2A, keyB: thsArray[index].sector2B)
            mykeydata.append(newEntry)
            
            newEntry = cardSecurityKeys(id: UUID(), dbid: thsArray[index].dbid, sectorNum: 3, keyA: thsArray[index].sector3A, keyB: thsArray[index].sector3B)
            mykeydata.append(newEntry)
            
            newEntry = cardSecurityKeys(id: UUID(), dbid: thsArray[index].dbid, sectorNum: 4, keyA: thsArray[index].sector4A, keyB: thsArray[index].sector4B)
            mykeydata.append(newEntry)
            
            newEntry = cardSecurityKeys(id: UUID(), dbid: thsArray[index].dbid, sectorNum: 5, keyA: thsArray[index].sector5A, keyB: thsArray[index].sector5B)
            mykeydata.append(newEntry)
            
            newEntry = cardSecurityKeys(id: UUID(), dbid: thsArray[index].dbid, sectorNum: 6, keyA: thsArray[index].sector6A, keyB: thsArray[index].sector6B)
            mykeydata.append(newEntry)
            
            newEntry = cardSecurityKeys(id: UUID(), dbid: thsArray[index].dbid, sectorNum: 7, keyA: thsArray[index].sector7A, keyB: thsArray[index].sector7B)
            mykeydata.append(newEntry)
            
            newEntry = cardSecurityKeys(id: UUID(), dbid: thsArray[index].dbid, sectorNum: 8, keyA: thsArray[index].sector8A, keyB: thsArray[index].sector8B)
            mykeydata.append(newEntry)
            
            newEntry = cardSecurityKeys(id: UUID(), dbid: thsArray[index].dbid, sectorNum: 9, keyA: thsArray[index].sector9A, keyB: thsArray[index].sector9B)
            mykeydata.append(newEntry)
            
            newEntry = cardSecurityKeys(id: UUID(), dbid: thsArray[index].dbid, sectorNum: 10, keyA: thsArray[index].sector10A, keyB: thsArray[index].sector10B)
            mykeydata.append(newEntry)
        
            newEntry = cardSecurityKeys(id: UUID(), dbid: thsArray[index].dbid, sectorNum: 11, keyA: thsArray[index].sector11A, keyB: thsArray[index].sector11B)
            mykeydata.append(newEntry)
        
            newEntry = cardSecurityKeys(id: UUID(), dbid: thsArray[index].dbid, sectorNum: 12, keyA: thsArray[index].sector12A, keyB: thsArray[index].sector12B)
            mykeydata.append(newEntry)
            
            newEntry = cardSecurityKeys(id: UUID(), dbid: thsArray[index].dbid, sectorNum: 13, keyA: thsArray[index].sector13A, keyB: thsArray[index].sector13B)
            mykeydata.append(newEntry)
            
            newEntry = cardSecurityKeys(id: UUID(), dbid: thsArray[index].dbid, sectorNum: 14, keyA: thsArray[index].sector14A, keyB: thsArray[index].sector14B)
            mykeydata.append(newEntry)
            
            newEntry = cardSecurityKeys(id: UUID(), dbid: thsArray[index].dbid, sectorNum: 15, keyA: thsArray[index].sector15A, keyB: thsArray[index].sector15B)
            mykeydata.append(newEntry)
        }
        
        return mykeydata
    }

    
    // Create DB
    func openDatabase() -> OpaquePointer?
    {
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent(dataPath)
        var db: OpaquePointer? = nil
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK
        {
            print("error opening database")
            return nil
        }
        else
        {
            print("Successfully opened connection to database at \(dataPath)")
            return db
        }
    }
    
    func dropUserTable() {
        
        let dropTableString = """
                DROP TABLE cardSecurityKeys;
            """
        
        var dropTableStatement: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(db, dropTableString, -1, &dropTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(dropTableStatement) == SQLITE_DONE {
                print("Security table has been deleted successfully.")
            } else {
                print("Security table deletion failed.")
            }
        } else {
            print("Security table deletion failed.")
        }
        
        sqlite3_finalize(dropTableStatement)
        
        sqlite3_close(db)
    }
    
    
    
    
    // Create users table
    // returns true if table is created
    func createUserTable() -> Bool {
        
        let createTableString = """
               CREATE TABLE cardSecurityKeys (
                   id INTEGER PRIMARY KEY AUTOINCREMENT,
                   name TEXT,
                   sector0A TEXT,
                   sector0B TEXT,
                   sector1A TEXT,
                   sector1B TEXT,
                   sector2A TEXT,
                   sector2B TEXT,
                   sector3A TEXT,
                   sector3B TEXT,
                   sector4A TEXT,
                   sector4B TEXT,
                   sector5A TEXT,
                   sector5B TEXT,
                   sector6A TEXT,
                   sector6B TEXT,
                   sector7A TEXT,
                   sector7B TEXT,
                   sector8A TEXT,
                   sector8B TEXT,
                   sector9A TEXT,
                   sector9B TEXT,
                   sector10A TEXT,
                   sector10B TEXT,
                   sector11A TEXT,
                   sector11B TEXT,
                   sector12A TEXT,
                   sector12B TEXT,
                   sector13A TEXT,
                   sector13B TEXT,
                   sector14A TEXT,
                   sector14B TEXT,
                   sector15A TEXT,
                   sector15B TEXT
               );
           """
        
        var createTableStatement: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                print("Security table has been created successfully.")
                return true
            } else {
                print("Security table creation failed.")
                return false
            }
        } else {
            print("Security table creation failed.")
        }
        
        sqlite3_finalize(createTableStatement)
        
        sqlite3_close(db)
        
        return false
    }
    
    
    func insertSecurityKeySet(name: String, sector0A: String, sector0B: String, sector1A: String, sector1B: String, sector2A: String, sector2B: String, sector3A: String, sector3B: String, sector4A: String, sector4B: String, sector5A: String, sector5B: String, sector6A: String, sector6B: String, sector7A: String, sector7B: String, sector8A: String, sector8B: String, sector9A: String, sector9B: String, sector10A: String, sector10B: String, sector11A: String, sector11B: String, sector12A: String, sector12B: String, sector13A: String, sector13B: String, sector14A: String, sector14B: String, sector15A: String, sector15B: String) {
        
        let insertStatementString = "INSERT INTO cardSecurityKeys (name, sector0A, sector0B, sector1A, sector1B, sector2A, sector2B, sector3A, sector3B, sector4A, sector4B, sector5A, sector5B, sector6A, sector6B, sector7A, sector7B, sector8A, sector8B, sector9A, sector9B, sector10A, sector10B, sector11A, sector11B, sector12A, sector12B, sector13A, sector13B, sector14A, sector14B, sector15A, sector15B) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"
        
        var insertStatement: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(insertStatement, 1, (name as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 2, (sector0A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 3, (sector0B as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 4, (sector1A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 5, (sector1B as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 6, (sector2A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 7, (sector2B as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 8, (sector3A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 9, (sector3B as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 10, (sector4A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 11, (sector4B as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 12, (sector5A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 13, (sector5B as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 14, (sector6A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 15, (sector6B as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 16, (sector7A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 17, (sector7B as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 18, (sector8A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 19, (sector8B as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 20, (sector9A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 21, (sector9B as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 22, (sector10A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 23, (sector10B as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 24, (sector11A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 25, (sector11B as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 26, (sector12A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 27, (sector12B as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 28, (sector13A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 29, (sector13B as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 30, (sector14A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 31, (sector14B as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 32, (sector15A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 33, (sector15B as NSString).utf8String, -1, nil)
            
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                print("Card security map has been created successfully.")
                sqlite3_finalize(insertStatement)
                
            } else {
                print("Could not add.")
                
            }
        } else {
            print("INSERT statement is failed.")
        }
        
        sqlite3_close(db)
    }
    
    func read() -> [cardSecurityKeysTable] {
        let queryStatementString = "SELECT * FROM cardSecurityKeys ORDER BY id ASC;"
        var queryStatement: OpaquePointer? = nil
        var mykeys : [cardSecurityKeysTable] = []
        
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let dbid = sqlite3_column_int(queryStatement, 0)
                let name = String(describing: String(cString: sqlite3_column_text(queryStatement, 1)))
                let sector0A = String(describing: String(cString: sqlite3_column_text(queryStatement, 2)))
                let sector0B = String(describing: String(cString: sqlite3_column_text(queryStatement, 3)))
                let sector1A = String(describing: String(cString: sqlite3_column_text(queryStatement, 4)))
                let sector1B = String(describing: String(cString: sqlite3_column_text(queryStatement, 5)))
                let sector2A = String(describing: String(cString: sqlite3_column_text(queryStatement, 6)))
                let sector2B = String(describing: String(cString: sqlite3_column_text(queryStatement, 7)))
                let sector3A = String(describing: String(cString: sqlite3_column_text(queryStatement, 8)))
                let sector3B = String(describing: String(cString: sqlite3_column_text(queryStatement, 9)))
                let sector4A = String(describing: String(cString: sqlite3_column_text(queryStatement, 10)))
                let sector4B = String(describing: String(cString: sqlite3_column_text(queryStatement, 11)))
                let sector5A = String(describing: String(cString: sqlite3_column_text(queryStatement, 12)))
                let sector5B = String(describing: String(cString: sqlite3_column_text(queryStatement, 13)))
                let sector6A = String(describing: String(cString: sqlite3_column_text(queryStatement, 14)))
                let sector6B = String(describing: String(cString: sqlite3_column_text(queryStatement, 15)))
                let sector7A = String(describing: String(cString: sqlite3_column_text(queryStatement, 16)))
                let sector7B = String(describing: String(cString: sqlite3_column_text(queryStatement, 17)))
                let sector8A = String(describing: String(cString: sqlite3_column_text(queryStatement, 18)))
                let sector8B = String(describing: String(cString: sqlite3_column_text(queryStatement, 19)))
                let sector9A = String(describing: String(cString: sqlite3_column_text(queryStatement, 20)))
                let sector9B = String(describing: String(cString: sqlite3_column_text(queryStatement, 21)))
                let sector10A = String(describing: String(cString: sqlite3_column_text(queryStatement, 22)))
                let sector10B = String(describing: String(cString: sqlite3_column_text(queryStatement, 23)))
                let sector11A = String(describing: String(cString: sqlite3_column_text(queryStatement, 24)))
                let sector11B = String(describing: String(cString: sqlite3_column_text(queryStatement, 25)))
                let sector12A = String(describing: String(cString: sqlite3_column_text(queryStatement, 26)))
                let sector12B = String(describing: String(cString: sqlite3_column_text(queryStatement, 27)))
                let sector13A = String(describing: String(cString: sqlite3_column_text(queryStatement, 28)))
                let sector13B = String(describing: String(cString: sqlite3_column_text(queryStatement, 29)))
                let sector14A = String(describing: String(cString: sqlite3_column_text(queryStatement, 30)))
                let sector14B = String(describing: String(cString: sqlite3_column_text(queryStatement, 31)))
                let sector15A = String(describing: String(cString: sqlite3_column_text(queryStatement, 32)))
                let sector15B = String(describing: String(cString: sqlite3_column_text(queryStatement, 33)))
                
                mykeys.append(cardSecurityKeysTable(id: UUID(), dbid: Int(dbid), name: name, sector0A: sector0A, sector0B: sector0B, sector1A: sector1A, sector1B: sector1B, sector2A: sector2A, sector2B: sector2B, sector3A: sector3A, sector3B: sector3B, sector4A: sector4A, sector4B: sector4B, sector5A: sector5A, sector5B: sector5B, sector6A: sector6A, sector6B: sector6B, sector7A: sector7A, sector7B: sector7B, sector8A: sector8A, sector8B: sector8B, sector9A: sector9A, sector9B: sector9B, sector10A: sector10A, sector10B: sector10B, sector11A: sector11A, sector11B: sector11B, sector12A: sector12A, sector12B: sector12B, sector13A: sector13A, sector13B: sector13B, sector14A: sector14A, sector14B: sector14B, sector15A: sector15A, sector15B: sector15B))
            }
        } else {
            print("SELECT statement could not be prepared")
        }
        sqlite3_finalize(queryStatement)
        
        sqlite3_close(db)
        
        return mykeys
    }
    
    func update_keys(row: Int, dbid: Int, master_table:[cardSecurityKeysTable], keys_table:[cardSecurityKeys]) -> Bool {
        
        var result: Bool?
        
        let name:String = master_table[row].name
        
        let sector0_A:String = keys_table[0].keyA
        let sector0_B:String = keys_table[0].keyB
        let sector1_A:String = keys_table[1].keyA
        let sector1_B:String = keys_table[1].keyB
        let sector2_A:String = keys_table[2].keyA
        let sector2_B:String = keys_table[2].keyB
        let sector3_A:String = keys_table[3].keyA
        let sector3_B:String = keys_table[3].keyB
        let sector4_A:String = keys_table[4].keyA
        let sector4_B:String = keys_table[4].keyB
        let sector5_A:String = keys_table[5].keyA
        let sector5_B:String = keys_table[5].keyB
        let sector6_A:String = keys_table[6].keyA
        let sector6_B:String = keys_table[6].keyB
        let sector7_A:String = keys_table[7].keyA
        let sector7_B:String = keys_table[7].keyB
        let sector8_A:String = keys_table[8].keyA
        let sector8_B:String = keys_table[8].keyB
        let sector9_A:String = keys_table[9].keyA
        let sector9_B:String = keys_table[9].keyB
        let sector10_A:String = keys_table[10].keyA
        let sector10_B:String = keys_table[10].keyB
        let sector11_A:String = keys_table[11].keyA
        let sector11_B:String = keys_table[11].keyB
        let sector12_A:String = keys_table[12].keyA
        let sector12_B:String = keys_table[12].keyB
        let sector13_A:String = keys_table[13].keyA
        let sector13_B:String = keys_table[13].keyB
        let sector14_A:String = keys_table[14].keyA
        let sector14_B:String = keys_table[14].keyB
        let sector15_A:String = keys_table[15].keyA
        let sector15_B:String = keys_table[15].keyB
        
        db = openDatabase()
        
        result = UpdateSecurityKeySet(id: dbid, name: name, sector0A: sector0_A, sector0B: sector0_B, sector1A: sector1_A, sector1B: sector1_B, sector2A: sector2_A, sector2B: sector2_B, sector3A: sector3_A, sector3B: sector3_B, sector4A: sector4_A, sector4B: sector4_B, sector5A: sector5_A, sector5B: sector5_B, sector6A: sector6_A, sector6B: sector6_B, sector7A: sector7_A, sector7B: sector7_B, sector8A: sector8_A, sector8B: sector8_B, sector9A: sector9_A, sector9B: sector9_B, sector10A: sector10_A, sector10B: sector10_B, sector11A: sector11_A, sector11B: sector11_B, sector12A: sector12_A, sector12B: sector12_B, sector13A: sector13_A, sector13B: sector13_B, sector14A: sector14_A, sector14B: sector14_B, sector15A: sector15_A, sector15B: sector15_B)
        
        return result ?? false
        
    }
    
    
    func UpdateSecurityKeySet(id: Int, name: String, sector0A: String, sector0B: String, sector1A: String, sector1B: String, sector2A: String, sector2B: String, sector3A: String, sector3B: String, sector4A: String, sector4B: String, sector5A: String, sector5B: String, sector6A: String, sector6B: String, sector7A: String, sector7B: String, sector8A: String, sector8B: String, sector9A: String, sector9B: String, sector10A: String, sector10B: String, sector11A: String, sector11B: String, sector12A: String, sector12B: String, sector13A: String, sector13B: String, sector14A: String, sector14B: String, sector15A: String, sector15B: String) -> Bool {
     
        
        let updateStatementString = "UPDATE cardSecurityKeys SET name=?, sector0A=?, sector0B=?, sector1A=?, sector1B=?, sector2A=?, sector2B=?, sector3A=?, sector3B=?, sector4A=?, sector4B=?, sector5A=?, sector5B=?, sector6A=?, sector6B=?, sector7A=?, sector7B=?, sector8A=?, sector8B=?, sector9A=?, sector9B=?, sector10A=?, sector10B=?, sector11A=?, sector11B=?, sector12A=?, sector12B=?, sector13A=?, sector13B=?, sector14A=?, sector14B=?, sector15A=?, sector15B=? WHERE id=?;"
        
        var updateStatement: OpaquePointer? = nil
        
        var result:Bool?
        
        if sqlite3_prepare_v2(db, updateStatementString, -1, &updateStatement, nil) == SQLITE_OK {
            
            sqlite3_bind_text(updateStatement, 1, (name as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 2, (sector0A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 3, (sector0B as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 4, (sector1A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 5, (sector1B as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 6, (sector2A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 7, (sector2B as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 8, (sector3A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 9, (sector3B as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 10, (sector4A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 11, (sector4B as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 12, (sector5A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 13, (sector5B as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 14, (sector6A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 15, (sector6B as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 16, (sector7A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 17, (sector7B as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 18, (sector8A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 19, (sector8B as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 20, (sector9A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 21, (sector9B as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 22, (sector10A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 23, (sector10B as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 24, (sector11A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 25, (sector11B as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 26, (sector12A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 27, (sector12B as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 28, (sector13A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 29, (sector13B as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 30, (sector14A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 31, (sector14B as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 32, (sector15A as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 33, (sector15B as NSString).utf8String, -1, nil)
            sqlite3_bind_int(updateStatement, 34, Int32(id))
            
            if sqlite3_step(updateStatement) == SQLITE_DONE {
                result = true
                print("Card security map with \(id) has been updated created successfully.")
                sqlite3_finalize(updateStatement)
                
            } else {
                result = false
                print("Could not add.")
                
            }
        } else {
            result = false
            print("UPDATE statement is failed.")
        }
        sqlite3_close(db)
        
        return result ?? false
    }
}
