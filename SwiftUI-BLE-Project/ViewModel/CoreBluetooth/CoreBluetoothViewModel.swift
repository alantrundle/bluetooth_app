//
//  CoreBluetoothViewModel.swift
//  SwiftUI-BLE-Project
//
//  Created by Alan Trundle on 2024/11/04.
//

import SwiftUI
import CoreBluetooth

// error data
// pre read error information
struct error_struct: Decodable {
    
    let error : info_struct
    
    struct info_struct: Decodable{
        let info: String
    }
    
}

// head data
// contains RFID and Type
struct head_struct: Decodable {
    
    let head: info_struct

    struct info_struct: Decodable {
        let uid: String
        let type: String
    }
}

// card data
// contains sector and block information
struct sector_struct: Decodable {
    
    let sector: sector_head
    
    struct sector_head: Decodable {
        let sectorID: Int
        let auth: String
        let authError: String
        let data: [sector_data]
    }
    
    struct sector_data: Decodable {
        
        let blockID: Int
        let blockReaderr: String
        let blockData: String
    }
}

// packet information
// contains Receiving bluetooth chunk and size info
struct packet_struct: Decodable {
    let packet: packet_data
    
    struct packet_data: Decodable {
        let chunks: Float?
        let size: Float?
    }
}

class CoreBluetoothViewModel: NSObject, ObservableObject, CBPeripheralProtocolDelegate, CBCentralManagerProtocolDelegate {
    
    @Published var isBlePower: Bool = false
    @Published var isConnected: Bool = false
    @Published var isSearching: Bool = false
    @Published var result: String = ""
    
    @Published var progressViewHidden: Bool = true
    @Published var currentRxChunk: Float = 0
    
    @Published var showAlert: Bool = false
    @Published var error_title: String = ""
    @Published var error_msg: String = ""
    
    @Published var decodedHeadString: head_struct?
    @Published var decodedSectorString: [sector_struct]?
    @Published var decodedPacketString: packet_struct?
    
    @Published var foundPeripherals: [Peripheral] = []
    @Published var foundServices: [Service] = []
    @Published var foundCharacteristics: [Characteristic] = []
    
    @Published var sql:DBManager = DBManager()
    
    var isSearchingTimer = Timer().self
    
    private var centralManager: CBCentralManagerProtocol!
    private var connectedPeripheral: Peripheral!
    
    private var dbManager = DBManager()
    
    private let serviceUUID: CBUUID = CBUUID()
    
    var incomingData: String = ""
    
    override init() {
        super.init()
        #if targetEnvironment(simulator)
        centralManager = CBCentralManagerMock(delegate: self, queue: nil)
        #else
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
        #endif
    }
    
    private func runScanTimer() {
        
        isSearchingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { timer in
            self.stopScan()
            print("Scan Timer stopped")
        }
        
    }
    
    private func resetConfigure() {
        withAnimation {
            isConnected = false
            
            foundPeripherals = []
            foundServices = []
            foundCharacteristics = []
        }
    }
    
    
    
    //Control Func
    func startScan() {
        resetConfigure()
        let scanOption = [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        centralManager?.scanForPeripherals(withServices: nil, options: scanOption)
        runScanTimer()
        isSearching = true
        print("# Start Scan")
    }
    
    func stopScan(){
        //disconnectPeripheral()
        centralManager?.stopScan()
        isSearching = false
        print("# Stop Scan")
    }
    
    func connectPeripheral(_ selectPeripheral: Peripheral?) {
        guard let connectPeripheral = selectPeripheral else { return }
        connectedPeripheral = selectPeripheral
        centralManager.connect(connectPeripheral.peripheral, options: nil)
    }
    
    func disconnectPeripheral() {
        guard let connectedPeripheral = connectedPeripheral else { return }
        centralManager.cancelPeripheralConnection(connectedPeripheral.peripheral)
    }
    
    //MARK: CoreBluetooth CentralManager Delegete Func
    func didUpdateState(_ central: CBCentralManagerProtocol) {
        if central.state == .poweredOn {
            startScan()
            isBlePower = true
        } else {
            stopScan()
            isBlePower = false
        }
    }
    
    func didDiscover(_ central: CBCentralManagerProtocol, peripheral: CBPeripheralProtocol, advertisementData: [String : Any], rssi: NSNumber) {
        if rssi.intValue >= 0 { return }
        
        let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? nil
        var _name = "NoName"
        
        if peripheralName != nil {
            _name = String(peripheralName!)
        } else if peripheral.name != nil {
            _name = String(peripheral.name!)
        }
      
        let foundPeripheral: Peripheral = Peripheral(_peripheral: peripheral,
                                                     _name: _name,
                                                     _advData: advertisementData,
                                                     _rssi: rssi,
                                                     _discoverCount: 0)

        
        if let index = foundPeripherals.firstIndex(where: { $0.peripheral.identifier.uuidString == peripheral.identifier.uuidString }) {
            if foundPeripherals[index].discoverCount % 50 == 0 {
                foundPeripherals[index].name = _name
                foundPeripherals[index].rssi = rssi.intValue
                foundPeripherals[index].discoverCount += 1
            } else {
                foundPeripherals[index].discoverCount += 1
            }
        } else {
            foundPeripherals.append(foundPeripheral)
            //resetScanTimer()
        }
    }
    
    
    func didConnect(_ central: CBCentralManagerProtocol, peripheral: CBPeripheralProtocol) {
        guard let connectedPeripheral = connectedPeripheral else { return }
        isConnected = true
        connectedPeripheral.peripheral.delegate = self
        connectedPeripheral.peripheral.discoverServices(nil)
        
        // zero JSON arrays
        incomingData = ""
        decodedHeadString = nil
        decodedPacketString = nil
        decodedSectorString = []
    }
    
    func didFailToConnect(_ central: CBCentralManagerProtocol, peripheral: CBPeripheralProtocol, error: Error?) {
        disconnectPeripheral()
    }
    
    func didDisconnect(_ central: CBCentralManagerProtocol, peripheral: CBPeripheralProtocol, error: Error?) {
        print("disconnect")
        resetConfigure()
    }
    
    func connectionEventDidOccur(_ central: CBCentralManagerProtocol, event: CBConnectionEvent, peripheral: CBPeripheralProtocol) {
        
    }
    
    func willRestoreState(_ central: CBCentralManagerProtocol, dict: [String : Any]) {
        
    }
    
    func didUpdateANCSAuthorization(_ central: CBCentralManagerProtocol, peripheral: CBPeripheralProtocol) {
        
    }
    
    //MARK: CoreBluetooth Peripheral Delegate Func
    func didDiscoverServices(_ peripheral: CBPeripheralProtocol, error: Error?) {
        peripheral.services?.forEach { service in
            let setService = Service(_uuid: service.uuid, _service: service)
            
            foundServices.append(setService)
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func didDiscoverCharacteristics(_ peripheral: CBPeripheralProtocol, service: CBService, error: Error?) {
        service.characteristics?.forEach { characteristic in
            let setCharacteristic: Characteristic = Characteristic(_characteristic: characteristic,
                                                                   _description: "",
                                                                   _uuid: characteristic.uuid,
                                                                   _readValue: "",
                                                                   _service: characteristic.service!)
            foundCharacteristics.append(setCharacteristic)
            
            for characteristic in service.characteristics ?? [] {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    
    
    func didUpdateValue(_ peripheral: CBPeripheralProtocol, characteristic: CBCharacteristic, error: Error?) {
        guard let characteristicValue = characteristic.value else { return }
        
        if let index = foundCharacteristics.firstIndex(where: { $0.uuid.uuidString == characteristic.uuid.uuidString }) {
            
            foundCharacteristics[index].readValue = characteristicValue.map({ String(format:"%02x", $0) }).joined()
        }
        
        // read data from ESP32 chunks by chunk, and concatenate it
        incomingData = incomingData + String(decoding: characteristicValue, as: UTF8.self)
        
        if (currentRxChunk == 0) {
            decodedSectorString = []
        }
        

        
        // complete JSON datbase has been read from the ESP32
        if incomingData.hasSuffix("\n") {
            
            showAlert = false
            let raw_json = incomingData
    
            incomingData = ""
            let chunk = currentRxChunk
            currentRxChunk = 0.0
            
            
            let json: Data? = raw_json.data(using: .utf8)
            
            do {
                decodedHeadString = try JSONDecoder().decode(head_struct.self, from: json!)
            } catch {
                //print("Decoded Error Message ", error)
            }
            
            do {
                decodedSectorString = try JSONDecoder().decode([sector_struct].self, from: json!)
            } catch {
                //print("Decoded Error Message ", error)
            }
            
            do {
                decodedPacketString = try JSONDecoder().decode(packet_struct.self, from: json!)
            } catch {
                //print("Decoded Error Message ", error)
            }
            
            if (decodedSectorString?.count == 16 && chunk == decodedPacketString?.packet.chunks ?? 0) {
                currentRxChunk = 0
                error_msg = "A new card/tag has been read.\r\n\r\n\(decodedHeadString?.head.uid ?? "<error>")"
                error_title = "Read Request Complete"
                showAlert = true
            }
            
        } else {
            // increment chunk for Progress View
            currentRxChunk+=1
        }
    }
    
    func didWriteValue(_ peripheral: CBPeripheralProtocol, descriptor: CBDescriptor, error: Error?) {
        
    }
}
