//
//  Database.swift
//  Mifare Toolbox
//
//  Created by Alan Trundle on 18/10/2024.
//
import Foundation
import SQLite3
import SwiftUI

struct cardSecurityKeyProfileTable:Identifiable  {
    
    var id: Int
    var profileName: String
    var typeName: String
}

struct cardSecurityKeysTable: Identifiable {
    
    var id: Int
    var profileID: Int
    var sectorNum: Int
    var keyA: String
    var keyB: String
    var accessPermissions: String
    
}

struct cardTypes: Identifiable {
    var id:Int
    var name:String
}

class DBManager: ObservableObject {
    
    @Published var db:OpaquePointer?
    @Published var keyProfileTable:[cardSecurityKeyProfileTable] = []
    @Published var keysTable:[cardSecurityKeysTable] = []
    @Published var cardTypesTable: [cardTypes] = []
    
    @Published var list_keys:[cardSecurityKeysTable] = []
    
    @Published var generateKeyDataArray: Bool = true
    @Published var isLoading: Bool = false
    
    @Published var scrollToIndex:Int = -1
    
    let dataPath: String = "MifareDB"
    
    
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
            //print("Successfully opened connection to database at \(dataPath)")
            return db
        }
    }
    
    func closeDB(db: OpaquePointer?) -> Bool
    {
        return (sqlite3_close(db) != 0)
    }
    
    /* Database Admin functions*/
    func dropAllTables() {
        
        deleteFile(file: dataPath)
    }
    
    func  checkDatabaseExists() -> Bool {
        return ifFileExists(file: dataPath)
    }
    
    func ifFileExists(file: String) -> Bool {
        // Get the URL for the Documents directory
        let fileManager = FileManager.default
        if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            // Path for the SQLite database
            let dbPath = documentsDirectory.appendingPathComponent(file).path
            
            // Check if the file exists
            if FileManager.default.fileExists(atPath: dbPath) {
                print("Database already exists at: \(dbPath)")
                return true
            }
        }
        return false
    }
        
    func deleteFile(file: String) {
        // Path to the file you want to delete
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let filePath = documentsDirectory?.appendingPathComponent(file)
        
        guard let filePath = filePath else {
            print("File path is nil")
            return
        }
        
        // Attempt to delete the file
        do {
            if fileManager.fileExists(atPath: filePath.path) {
                try fileManager.removeItem(at: filePath)
                print("File deleted successfully.")
            } else {
                print("File does not exist.")
            }
        } catch {
            print("Error deleting file: \(error.localizedDescription)")
        }
    }
    
    func dropTable(name: String) -> Bool {
        
        let dropTableString = """
                DROP TABLE IF EXISTS \(name);
            """
        
        var dropTableStatement: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(db, dropTableString, -1, &dropTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(dropTableStatement) == SQLITE_DONE {
                print("Security table has been deleted successfully.")
            } else {
                print("Security table deletion failed.")
                return false
            }
        } else {
            print("Security table deletion failed.")
            return false
        }
        
        sqlite3_finalize(dropTableStatement)
        return true
    }
    
    func getLastInsertID() -> Int {
        let queryStatementString = "SELECT last_insert_rowid();"
        var queryStatement: OpaquePointer? = nil
        var insert_id: Int = -1
        
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                insert_id = Int(sqlite3_column_int(queryStatement, 0))
            }
            
            print("SELECT statement completed successfully")
            
        } else {
            print("SELECT statement could not be prepared")
            return insert_id
        }
        
        sqlite3_finalize(queryStatement)
        
        return insert_id
    }
    
    
    
    
    /* Database Table Creation Functions*/
    
    func createKeyProfileTable() -> Bool {
        
        let createTableString = """
           CREATE TABLE cardSecurityProfiles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            typeID INTEGER
            );
           """
        
        var createTableStatement: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                print("Security Profile table has been created successfully.")
                sqlite3_finalize(createTableStatement)
                return true
            } else {
                print("Security Profile table creation failed.")
                return false
            }
        } else {
            print("Security Profile table creation failed.")
            return false
        }
    }
    
    func createSecurityKeysTable() -> Bool {
        
        let createTableString = """
               CREATE TABLE cardSecurityKeys (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                profileID INTEGER,
                sectorNum INTEGER,
                keyA TEXT,
                keyB TEXT,
                accessPermissions INTEGER
               );
           """
        
        var createTableStatement: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                print("Security Keys table has been created successfully.")
                return true
            } else {
                print("Security Keys table creation failed.")
                return false
            }
        } else {
            print("Security Keys table creation failed.")
        }
        
        sqlite3_finalize(createTableStatement)
        return false
    }
    
    
    
    
    // returns true if table is created
    func createCardTypesTable() -> Bool {
        
        let createTableString = """
               CREATE TABLE cardTypes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT
               );
           """
        
        var createTableStatement: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                print("Card Types table has been created successfully.")
                sqlite3_finalize(createTableStatement)
                return true
            } else {
                print("Card Types table creation failed.")
                return false
            }
        } else {
            print("Card Types table creation failed.")
            return false
        }
    }
    
    
    
    
    /* Database Table INSERT Functions*/
    
    func insertSecurityKeyProfiles(name: String, typeID: Int32) -> Int {
        
        let insertStatementString = "INSERT INTO cardSecurityProfiles (name, typeID) VALUES (?, ?);"
        
        var insertStatement: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(insertStatement, 1, (name as NSString).utf8String, -1, nil)
            sqlite3_bind_int(insertStatement, 2, Int32(typeID))
            
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                print("Insert into Profile table has been successfully entered")
                sqlite3_finalize(insertStatement)
            } else {
                print("Could not add.")
                return -1
                
            }
        } else {
            print("INSERT statement is failed.")
            return -1
        }
        
        // get LAST_INSERT_ID
        let insert_id = getLastInsertID()
        return Int(Int32(insert_id))
    }
    
    func insertCardType(name: String) -> Int {
        
        let insertStatementString = "INSERT INTO cardTypes (name) VALUES (?);"
        
        var insertStatement: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(insertStatement, 1, (name as NSString).utf8String, -1, nil)
            
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                print("Insert into Card Types table has been successfully entered")
                sqlite3_finalize(insertStatement)
            } else {
                print("Could not add.")
                return -1
                
            }
        } else {
            print("INSERT statement is failed.")
            return -1
        }
        
        // get LAST_INSERT_ID
        let insert_id = getLastInsertID()
        return insert_id
    }
    
    func insertSecurityKeys(profileID: Int32, sectorNum: Int32, keyA: String, keyB: String, accessPermissions: String) -> Int32 {
        
        let insertStatementString = "INSERT INTO cardSecurityKeys (profileID, sectorNum, keyA, keyB, accessPermissions) VALUES (?, ?, ?, ?, ?);"
        
        var insertStatement: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(insertStatement, 1, Int32(profileID))
            sqlite3_bind_int(insertStatement, 2, Int32(sectorNum))
            sqlite3_bind_text(insertStatement, 3, (keyA as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 4, (keyB as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 5, (accessPermissions as NSString).utf8String, -1, nil)
            
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                print("Insert into Profile table has been successfully entered")
                sqlite3_finalize(insertStatement)
            } else {
                print("Could not add.")
                return -1
                
            }
        } else {
            print("INSERT statement is failed.")
            return -1
        }
        
        // get LAST_INSERT_ID
        let insert_id = getLastInsertID()
        return Int32(insert_id)
    }
    
    /* Database Table SELECT functions*/
    
    func readProfileTable() -> [cardSecurityKeyProfileTable] {
        let queryStatementString = "SELECT a.id, a.name, b.name FROM cardSecurityProfiles as a INNER JOIN cardTypes as b ON a.typeID = b.id ORDER BY a.id ASC;"
        var queryStatement: OpaquePointer? = nil
        var profileTable: [cardSecurityKeyProfileTable] = []
        
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let profile_id = sqlite3_column_int(queryStatement, 0)
                let profile_name = String(describing: String(cString: sqlite3_column_text(queryStatement, 1)))
                let type_name = String(describing: String(cString: sqlite3_column_text(queryStatement, 2)))
                
                profileTable.append((cardSecurityKeyProfileTable)(id: Int(profile_id), profileName: profile_name, typeName: type_name))
                
            }
        } else {
            print("SELECT statement profiles could not be prepared")
            return []
        }
        
        sqlite3_finalize(queryStatement)
        return profileTable
    }
    
    func readKeysTable() -> [cardSecurityKeysTable] {
        let queryStatementString = "SELECT * FROM cardSecurityKeys ORDER BY id ASC;"
        var queryStatement: OpaquePointer? = nil
        var keysTable : [cardSecurityKeysTable] = []
        
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let keys_id: Int32 = sqlite3_column_int(queryStatement, 0)
                let profile_id:Int32 = sqlite3_column_int(queryStatement, 1)
                let sector_num:Int32 = sqlite3_column_int(queryStatement, 2)
                let keyA = String(describing: String(cString: sqlite3_column_text(queryStatement, 3)))
                let keyB = String(describing: String(cString: sqlite3_column_text(queryStatement, 4)))
                let accessPermissions = String(describing: String(cString: sqlite3_column_text(queryStatement, 5)))
                
                keysTable.append((cardSecurityKeysTable)(id: Int(keys_id), profileID: Int(profile_id), sectorNum: Int(sector_num), keyA: keyA, keyB: keyB, accessPermissions: accessPermissions))
            }
        } else {
            print("SELECT statement keys could not be prepared")
            return []
        }
        
        sqlite3_finalize(queryStatement)
        return keysTable
    }
    
    func readKeysTableByProfileID(profileID: Int) -> [cardSecurityKeysTable] {
        let queryStatementString = "SELECT * FROM cardSecurityKeys WHERE profileID = \(profileID) ORDER BY id ASC;"
        var queryStatement: OpaquePointer? = nil
        var keysTable : [cardSecurityKeysTable] = []
        
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let keys_id: Int32 = sqlite3_column_int(queryStatement, 0)
                let profile_id:Int32 = sqlite3_column_int(queryStatement, 1)
                let sector_num:Int32 = sqlite3_column_int(queryStatement, 2)
                let keyA = String(describing: String(cString: sqlite3_column_text(queryStatement, 3)))
                let keyB = String(describing: String(cString: sqlite3_column_text(queryStatement, 4)))
                let accessPermissions = String(describing: String(cString: sqlite3_column_text(queryStatement, 5)))
                
                keysTable.append((cardSecurityKeysTable)(id: Int(keys_id), profileID: Int(profile_id), sectorNum: Int(sector_num), keyA: keyA, keyB: keyB, accessPermissions: accessPermissions))
            }
        } else {
            print("SELECT statement keys could not be prepared")
            return []
        }
        
        sqlite3_finalize(queryStatement)
        return keysTable
    }
    
    func readcardTypesTable() -> [cardTypes] {
        let queryStatementString = "SELECT * FROM cardTypes ORDER BY id ASC;"
        var queryStatement: OpaquePointer? = nil
        var keysTable : [cardTypes] = []
        
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let card_id:Int32 = sqlite3_column_int(queryStatement, 0)
                let name = String(describing: String(cString: sqlite3_column_text(queryStatement, 1)))
                
                keysTable.append((cardTypes)(id: Int(card_id), name: name))
            }
        } else {
            print("SELECT statement types could not be prepared")
        }
        
        sqlite3_finalize(queryStatement)
        return keysTable
    }
    
    /* Database Table UPDATE Functions*/
    
    
    
    func UpdateSecurityKeySet(id: Int, profileID: Int, sectorNum: Int, keyA: String, keyB:String, accessPermissions: String) -> Bool {
        
        let updateStatementString = "UPDATE cardSecurityKeys SET profileID=?, sectorNum=?, keyA=?, keyB=?, accessPermissions=? WHERE id=?;"
        var updateStatement: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(db, updateStatementString, -1, &updateStatement, nil) == SQLITE_OK {
            
            sqlite3_bind_int(updateStatement, 1, Int32(profileID))
            sqlite3_bind_int(updateStatement, 2, Int32(sectorNum))
            sqlite3_bind_text(updateStatement, 3, (keyA as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 4, (keyB as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 5, (accessPermissions as NSString).utf8String, -1, nil)
            sqlite3_bind_int(updateStatement, 6, Int32(id))
            
            if sqlite3_step(updateStatement) == SQLITE_DONE {
                print("cardSecurityKeys has been updated with \(id) has been updated created successfully.")
                sqlite3_finalize(updateStatement)
                return true
                
            } else {
                print("Could not add.")
                return false
                
            }
        } else {
            print("UPDATE statement is failed.")
            return false
        }
    }
    
    func UpdateCardSecurityProfiles(id: Int, profileName: String) -> Bool {
        
        let updateStatementString = "UPDATE cardSecurityProfiles SET name=? WHERE id=?;"
        var updateStatement: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(db, updateStatementString, -1, &updateStatement, nil) == SQLITE_OK {
            
            sqlite3_bind_text(updateStatement, 1, (profileName as NSString).utf8String, -1, nil)
            sqlite3_bind_int(updateStatement, 2, Int32(id))
            
            if sqlite3_step(updateStatement) == SQLITE_DONE {
                print("cardSecurityKeys has been updated with \(id) has been updated created successfully.")
                sqlite3_finalize(updateStatement)
                return true
                
            } else {
                print("Could not add.")
                return false
                
            }
        } else {
            print("UPDATE statement is failed.")
            return false
        }
    }
    
}
