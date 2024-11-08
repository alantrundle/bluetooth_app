//
//  Mock.swift
//  factory-tourguide-iOS
//
//  Created by Alan Trundle on 2024/11/04.
//

import Foundation

protocol Mock {}

extension Mock {
    var className: String {
        return String(describing: type(of: self))
    }
    
    func log(_ message: String? = nil) {
        print("Mocked -", className, message ?? "")
    }
}
