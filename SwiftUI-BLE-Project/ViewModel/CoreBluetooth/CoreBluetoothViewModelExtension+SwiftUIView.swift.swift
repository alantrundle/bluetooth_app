//
//  CoreBluetoothViewModelExtension+SwiftUIView.swift.swift
//  SwiftUI-BLE-Project
//
//  CCreated by Alan Trundle on 2024/11/04.
//

import SwiftUI
import CoreBluetooth

//MARK: - Navigation Items
//extension CoreBluetoothViewModel {
//    func navigationToDetailView(isDetailViewLinkActive: Binding<Bool>) -> some View {
//        let navigationToDetailView =
//            NavigationLink("",
//                           destination: DetailView().navigationBarBackButtonHidden(true),
//                           isActive: isDetailViewLinkActive).frame(width: 0, height: 0)
//
//        return navigationToDetailView
//    }
//}
extension CoreBluetoothViewModel {
    func navigationToDetailView(isDetailViewLinkActive: Binding<Bool>) -> some View {
        let navigationToDetailView =
        NavigationLink("",
                       destination: DetailView(),
                       isActive: isDetailViewLinkActive).frame(width: 0, height: 0)
        
        return navigationToDetailView
    }
}


//MARK: - View Items
extension CoreBluetoothViewModel {
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
