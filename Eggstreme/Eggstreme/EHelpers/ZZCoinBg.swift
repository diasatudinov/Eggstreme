//
//  ZZCoinBg.swift
//  Eggstreme
//
//


import SwiftUI

struct ZZCoinBg: View {
    @StateObject var user = ZZUser.shared
    var height: CGFloat = ZZDeviceManager.shared.deviceType == .pad ? 80:60
    var body: some View {
        ZStack {
            Image(.coinsBgE)
                .resizable()
                .scaledToFit()
            
            Text("\(user.money)")
                .font(.system(size: ZZDeviceManager.shared.deviceType == .pad ? 45:19, weight: .black))
                .foregroundStyle(.black)
                .textCase(.uppercase)
                .offset(x: -23)
            
            
            
        }.frame(height: height)
        
    }
}

#Preview {
    ZZCoinBg()
}
