//
//  CoreBluetoothViewModel.swift
//  SwiftUI-BLE-Project
//
//  Created by Alan Trundle on 2024/11/04.
//

import SwiftUI
import CoreBluetooth

extension BLEManager {
    func navigationToDetailView(isDetailViewLinkActive: Binding<Bool>) -> some View {
        let navigationToDetailView =
        NavigationLink("",
                       destination: DetailView(),
                       isActive: isDetailViewLinkActive).frame(width: 0, height: 0)
        
        return navigationToDetailView
    }
}


//MARK: - View Items
extension BLEManager {
    func UIButtonView(proxy: GeometryProxy, text: String) -> some View {
        let UIButtonView =
            VStack {
                Text(text)
                    .frame(width: proxy.size.width / 1.1,
                           height: 50,
                           alignment: .center)
                    .foregroundColor(Color.blue)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue, lineWidth: 2))
            }
        return UIButtonView
    }
}

// MARK: - Response Types
enum ResponseType: String, Codable {
    case readBasic = "READBASIC"
    case readFull = "READFULL"
    case write = "WRITE"
}

// MARK: - Base Response
struct BaseResponse: Codable {
    var responseType: ResponseType
    var overallStatus: String
    var error: String?
}

// MARK: - READBASIC Response
struct ReadBasicResponse: Codable {
    var responseType: ResponseType
    var overallStatus: String
    var rfidUID: String
    var cardType: String
}

// MARK: - READFULL Response
struct ReadFullResponse: Codable {
    var responseType: ResponseType
    var overallStatus: String
    var error: String?
    var rfidUID: String
    var cardType: String
    var sectors: [Sector]
    
    struct Sector: Codable {
        var sector: Int
        var authenticationStatus: String
        var readStatus: String?
        var blocks: [Block]?
        
        struct Block: Codable {
            var block: Int
            var data: String?
            var status: String
        }
    }
}

// MARK: - WRITE Response
struct WriteResponse: Codable {
    var responseType: ResponseType
    var overallStatus: String
    var sectors: [Sector]
    
    struct Sector: Codable {
        var sector: Int
        var authenticationStatus: String
        var writeStatus: String
    }
}

struct BLEPeripheral: Identifiable, Hashable {
    let id: UUID          // Unique identifier (from CBPeripheral)
    let name: String      // Human-readable name
    let peripheral: CBPeripheral // The actual CBPeripheral object
    let rssi: Int
    
    init(peripheral: CBPeripheral, rssi: Int = 0) {
        self.id = peripheral.identifier // Use CBPeripheral's UUID as a unique identifier
        self.name = peripheral.name ?? "Unknown Device"
        self.peripheral = peripheral
        self.rssi = rssi
    }
}

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    // Bluetooth Properties
    
    @Published var foundPeripherals: [BLEPeripheral] = [] // Use BLEPeripheral instead of CBPeripheral
    @Published var connectedPeripheral: CBPeripheral?     // Keep this as CBPeripheral if needed for CoreBluetooth
    
    private var peripheral: CBPeripheral? // Ensure this is retained
    private var characteristic: CBCharacteristic? // Ensure this is retained
    
    @Published var rssi: Int = 0
    
    @Published var isConnected: Bool = false
    @Published var isSearching: Bool = false
    @Published var isBlePower: Bool = false
    
    @Published var showAlert = false
    @Published var error_title = ""
    @Published var error_msg = ""
    
    private var centralManager: CBCentralManager!
    
    @Published var readBasicResponse: ReadBasicResponse? = nil
    @Published var readFullResponse: ReadFullResponse? = nil
    @Published var writeResponse: WriteResponse? = nil
    
    @Published var isFullRead: Bool = false
    
    @Published var jsonBuffer = ""       // Buffer for incoming JSON data
    @Published var receivedData = ""       // Buffer for incoming JSON data
    
    private var totalChunks = 0         // Total number of data chunks
    private var receivedChunks = 0      // Number of chunks received
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            //startScanning()
            foundPeripherals = []
            isBlePower = true
        } else {
            isBlePower = false
        }
    }
    
    func startScanning() {
        isSearching = true
        
        foundPeripherals = []
        
        guard centralManager.state == .poweredOn else {
            print("Bluetooth is not available.")
            return
        }
        
        if centralManager.isScanning {
            print("Already scanning for peripherals.")
            return
        }
        
        print("Scanning for peripherals...")
      
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func stopScanning() {
        isSearching = false;
        centralManager.stopScan()
    }
    func connectPeripheral(_ blePeripheral: BLEPeripheral) {
        centralManager.stopScan()
        self.connectedPeripheral = blePeripheral.peripheral
        self.connectedPeripheral?.delegate = self
        
        print("Attempting to connect to \(blePeripheral.name)")
        centralManager.connect(self.connectedPeripheral!, options: nil)
        
        // Add timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            guard let self = self, self.connectedPeripheral?.state != .connected else {
                return
            }
            print("Connection timeout. Cancelling connection...")
            if let peripheral = self.connectedPeripheral {
                self.centralManager.cancelPeripheralConnection(peripheral)
            }
        }
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        print("Connected to \(peripheral.name ?? "Unknown Device")")
        self.peripheral = peripheral
        isConnected = true
        peripheral.delegate = self
        peripheral.discoverServices(nil) // Discover all services
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        print("Disconnected from \(peripheral.name ?? "Unknown Device")")
        
        // Reset the connection state
        self.isConnected = false
        self.connectedPeripheral = nil
        self.peripheral = nil
        self.characteristic = nil
        
        // Notify the user if needed
        DispatchQueue.main.async {
            self.showAlert = true
            self.error_title = "Disconnected"
            self.error_msg = "\(peripheral.name ?? "Device") has been disconnected."
        }
        
        // Optionally restart scanning
        print("Restarting scanning...")
        startScanning()
    }

    
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        if let error = error {
            print(
                "Error discovering characteristics: \(error.localizedDescription)"
            )
            return
        }
        
        guard let characteristics = service.characteristics else {
            print("No characteristics found.")
            return
        }
        
        for characteristic in characteristics {
            print("Discovered characteristic: \(characteristic.uuid)")
            if characteristic.uuid == CBUUID(
                string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
            ) {
                self.characteristic = characteristic
                print("Characteristic is set: \(characteristic)")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func disconnectPeripheral() {
        guard let connectedPeripheral = connectedPeripheral else {
            print("No connected peripheral to disconnect.")
            return
        }
        
        print(
            "Disconnecting from \(connectedPeripheral.name ?? "Unknown Device")"
        )
        centralManager.cancelPeripheralConnection(connectedPeripheral)
       
        //foundPeripherals = []
        
        // Reset the connection state
        self.isConnected = false
        self.connectedPeripheral = nil
        self.peripheral = nil
        self.characteristic = nil
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        // Initialize BLEPeripheral with RSSI
        let blePeripheral = BLEPeripheral(peripheral: peripheral, rssi: RSSI.intValue)
        
        // Check if the peripheral is already in the list using the unique identifier
        if !foundPeripherals.contains(where: { $0.id == blePeripheral.id }) {
            foundPeripherals.append(blePeripheral)
            print("Discovered peripheral: \(blePeripheral.name) with RSSI: \(blePeripheral.rssi)")
        } else {
            print("Duplicate peripheral ignored: \(blePeripheral.name)")
        }
        
        // Set and retain the discovered peripheral
        self.peripheral = peripheral
        self.peripheral?.delegate = self
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        guard let services = peripheral.services else {
            print("No services found")
            return
        }
        for service in services {
            print("Discovered service: \(service.uuid)")
            // Discover characteristics for each service
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value, let fragment = String(
            data: data,
            encoding: .utf8
        ) {
            jsonBuffer += fragment
                
            // Process complete JSON messages marked by EOT
            while let eotRange = jsonBuffer.range(of: "\u{04}") {
                let completeJson = String(jsonBuffer[..<eotRange.lowerBound])
                jsonBuffer = String(
                    jsonBuffer[eotRange.upperBound...]
                ) // Safe slicing
                    
                processReceivedJSON(completeJson)
            }
        }
            
    }
    
    private func processReceivedJSON(_ json: String) {
        DispatchQueue.main.async {
            self.receivedData = json
            do {
                let jsonData = Data(json.utf8)
                   
                // Decode the base response to determine the type
                let baseResponse = try JSONDecoder().decode(
                    BaseResponse.self,
                    from: jsonData
                )
                   
                switch baseResponse.responseType {
                case .readBasic:
                    self.readBasicResponse = try JSONDecoder()
                        .decode(ReadBasicResponse.self, from: jsonData)
                    self.readFullResponse = nil
                    self.writeResponse = nil
                    self.isFullRead = false
                case .readFull:
                    self.readFullResponse = try JSONDecoder()
                        .decode(ReadFullResponse.self, from: jsonData)
                    self.readBasicResponse = nil
                    self.writeResponse = nil
                    self.isFullRead = true
                case .write:
                    self.writeResponse = try JSONDecoder()
                        .decode(WriteResponse.self, from: jsonData)
                    self.readBasicResponse = nil
                    self.readFullResponse = nil
                    self.isFullRead = false
                }
            } catch {
                print("JSON Parsing Error: \(error)")
            }
        }
    }
    
    private var writeQueue: [Data] = []
    private var isWriting = false
    
    func sendNextChunk() {
        guard !isWriting, let peripheral = self.peripheral, let characteristic = self.characteristic else {
            print("Cannot send chunk. Peripheral or characteristic is nil.")
            return
        }
        
        if writeQueue.isEmpty {
            print("All chunks sent.")
            return
        }
        
        isWriting = true
        let data = writeQueue.removeFirst()
        print("Sending chunk: \(data.count) bytes")
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        isWriting = false
        if let error = error {
            print("Write failed: \(error.localizedDescription)")
        } else {
            print("Chunk sent successfully.")
            sendNextChunk()
        }
    }
    
    func sendTestWriteData() {
        guard let peripheral = self.peripheral, let _ = self.characteristic, peripheral.state == .connected else {
            print("Peripheral: \(String(describing: peripheral))")
            print("Characteristic: \(String(describing: characteristic))")
            print("Peripheral or characteristic is nil. Cannot send data.")
            return
        }
        
        let jsonToSend: String = """
            {
              "command": "WRITE",
              "authentication": {
                "sectors": [
                  {
                    "sector": 1,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYB"
                  },
                  {
                    "sector": 2,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYB"
                  }
                ]
              },
              "data": [
                {
                  "sector": 1,
                  "blocks": [
                    {
                      "block": 0,
                      "data": "AABBCCDDEEFF00112233445566778899"
                    },
                    {
                      "block": 1,
                      "data": "11223344556677889900AABBCCDDEEFF"
                    }
                  ]
                },
                {
                  "sector": 2,
                  "blocks": [
                    {
                      "block": 0,
                      "data": "FFEEDDCCBBAA99887766554433221100"
                    },
                    {
                      "block": 1,
                      "data": "1234567890ABCDEF1234567890ABCDEF"
                    }
                  ]
                }
              ]
            }
            """
        
        // Append <EOT> marker to the JSON
        let jsonWithEOT = jsonToSend + "\u{04}"
        
        let PACKET_SIZE = 128
        var startIndex = jsonWithEOT.startIndex
        while startIndex < jsonWithEOT.endIndex {
            let endIndex = jsonWithEOT.index(
                startIndex,
                offsetBy: PACKET_SIZE,
                limitedBy: jsonWithEOT.endIndex
            ) ?? jsonWithEOT.endIndex
            let chunk = String(jsonWithEOT[startIndex..<endIndex])
            if let data = chunk.data(using: .utf8) {
                writeQueue.append(data)
            }
            startIndex = endIndex
        }
        
        sendNextChunk()
    }
    
    func sendTestReadCard() {
        guard let peripheral = self.peripheral, let _ = self.characteristic, peripheral.state == .connected else {
            print("Peripheral: \(String(describing: peripheral))")
            print("Characteristic: \(String(describing: characteristic))")
            print("Peripheral or characteristic is nil. Cannot send data.")
            return
        }
        
        let jsonToSend: String = """
            {
              "command": "READFULL",
              "authentication": {
                "sectors": [
                  {
                    "sector": 0,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 1,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 2,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYB"
                  },
                  {
                    "sector": 3,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 4,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 5,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 6,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 7,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 8,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 9,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 10,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 11,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 12,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 13,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 14,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 15,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 16,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 17,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 18,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYB"
                  },
                  {
                    "sector": 19,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 20,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 21,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 22,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 23,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 24,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 25,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 26,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 27,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 28,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 29,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 30,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 31,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 32,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 33,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 34,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 35,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 36,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 37,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 38,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  },
                  {
                    "sector": 39,
                    "key_A": "FFFFFFFFFFFF",
                    "key_B": "FFFFFFFFFFFF",
                    "read_key": "KEYA"
                  }
                ]
              }
            }
            """
        
        // Append <EOT> marker to the JSON
        let jsonWithEOT = jsonToSend + "\u{04}"
        
        let PACKET_SIZE = 128
        var startIndex = jsonWithEOT.startIndex
        while startIndex < jsonWithEOT.endIndex {
            let endIndex = jsonWithEOT.index(
                startIndex,
                offsetBy: PACKET_SIZE,
                limitedBy: jsonWithEOT.endIndex
            ) ?? jsonWithEOT.endIndex
            let chunk = String(jsonWithEOT[startIndex..<endIndex])
            if let data = chunk.data(using: .utf8) {
                writeQueue.append(data)
            }
            startIndex = endIndex
        }
        
        sendNextChunk()
    }






}
