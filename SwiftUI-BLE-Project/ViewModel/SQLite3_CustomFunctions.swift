//
//  Untitled.swift
//  Mifare Toolbox
//
//  Created by Alan Trundle on 05/11/2024.
//
import Foundation
import SQLite3
import SwiftUI

/* Custom Database Functions*/

func setupDatabase() -> Bool {
    var abort = false
    
    var result_type_0: Int = -1
    var result_type_1: Int = -1
    
    var result_profile_id_0: Int = -1
    var result_profile_id_1: Int = -1
    
    if dropTable(name: "cardTypes") {
        if createCardTypesTable() {
            result_type_0 = insertCardType(name: "Mifare Classic 1K")
            result_type_1 = insertCardType(name: "Mifare Classic 1K")
        } else if result_type_0 > 0 || result_type_1 > 0 {
            abort = true
        }
    }
    else {
        abort = true
    }
    
    if dropTable(name: "cardSecurityProfiles") {
        if createKeyProfileTable() {
            
            print("DB_SETUP: Profile Table Creation OK")
            
            result_profile_id_0 = insertSecurityKeyProfiles(name: "Default Mifare Classic 1K", typeID: Int32(result_type_0))
            
            if result_type_0 > 0 {
                print("DB_SETUP: Default 4K profile created")
            }
            
            result_profile_id_1 = insertSecurityKeyProfiles(name: "Default Mifare Classic 1K", typeID: Int32(result_type_1))
            
            if result_type_1 > 0 {
                print("DB_SETUP: Default 4K profile created")
            }
        }
    }
    else {
        abort = true
    }
    
    if dropTable(name: "cardSecurityKeys") {
        
        if createSecurityKeysTable() {
            // Default 1K Classic Keys
            for index:Int32 in 0..<15 {
                db = openDatabase()
                let insert_id = insertSecurityKeys(profileID: Int32(result_profile_id_0), sectorNum: index, keyA: "FFFFFFFFFFFF", keyB: "FFFFFFFFFFFF", accessPermissions: "FF0780")
                
                print("DB Setup: Insert into Keys completed successfully with id \(insert_id)")
            }
            
            // Test 1K Classic Keys
            for index:Int32 in 0..<15 {
                db = openDatabase()
                let insert_id = insertSecurityKeys(profileID: Int32(result_profile_id_1), sectorNum: index, keyA: "000000000000", keyB: "000000000000", accessPermissions: "FF0780")
                
                print("DB Setup: Insert into Keys completed successfully with id \(insert_id)")
            }
            
            print("DB_SETUP: Profile Table Creation OK")
        }
        else {
            abort = true
        }
        
        if abort == true {
            
            // failed, just delete the database
            deleteFile(file: dataPath)
            return false
        }
    }
    
    return abort
}
}

func update_keys(keys_table:[cardSecurityKeysTable]) -> Bool {
    
    var result: Bool?
    
    for index in 0..<(keys_table.count) {
        
        db = openDatabase()
        result = UpdateSecurityKeySet(id: keys_table[index].keyID, profileID: keys_table[index].profileID, sectorNum: keys_table[index].sectorNum, keyA: keys_table[index].keyA, keyB: keys_table[index].keyB, accessPermissions: keys_table[index].accessPermissions)
        
    }
    
    return result ?? false
    
}
