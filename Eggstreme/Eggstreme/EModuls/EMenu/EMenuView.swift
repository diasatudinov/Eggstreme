//
//  EMenuView.swift
//  Eggstreme
//
//

import SwiftUI

struct EMenuView: View {
    @State private var showGame = false
    @State private var showAchievement = false
    @State private var showSettings = false
    @State private var showCalendar = false
    @State private var showDailyReward = false
    @State private var showShop = false
    
    @StateObject var shopVM = EShopViewModel()
    
    var body: some View {
        
        ZStack {
            
            
            HStack {
                Spacer()
                
                VStack(spacing: 10) {
                    Spacer()
                    
                    VStack(spacing: -20) {
                        Button {
                            showGame = true
                        } label: {
                            Image(.playIconE)
                                .resizable()
                                .scaledToFit()
                                .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:140)
                        }
                        
                        Button {
                            showSettings = true
                        } label: {
                            Image(.settingsIconE)
                                .resizable()
                                .scaledToFit()
                                .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:60)
                        }
                    }
                    Button {
                        showAchievement = true
                    } label: {
                        Image(.achievementsIconE)
                            .resizable()
                            .scaledToFit()
                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:60)
                    }
                    
                    Button {
                        showShop = true
                    } label: {
                        Image(.shopIconE)
                            .resizable()
                            .scaledToFit()
                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:60)
                    }
                    Spacer()
                }
            }
            
            
        }
        .background(
            ZStack {
                Image(.menuBgE)
                    .resizable()
                    .edgesIgnoringSafeArea(.all)
                    .scaledToFill()
                
                
            }
        )
        .fullScreenCover(isPresented: $showGame) {
            //                GameRootView()
        }
        .fullScreenCover(isPresented: $showAchievement) {
            EAchievementsView()
        }
        .fullScreenCover(isPresented: $showSettings) {
            ESettingsView()
        }
        .fullScreenCover(isPresented: $showShop) {
            EShopView(viewModel: shopVM)
        }
        
    }
}

#Preview {
    EMenuView()
}
