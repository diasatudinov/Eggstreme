//
//  EAchievementsView.swift
//  Eggstreme
//
//

import SwiftUI

struct EAchievementsView: View {
    @StateObject var user = ZZUser.shared
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject var viewModel = ZZAchievementsViewModel()
    @State private var index = 0
    var body: some View {
        ZStack {
            
            VStack {
                ZStack {
                    
                    
                    HStack(alignment: .top) {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                            
                        } label: {
                            Image(.xmarkE)
                                .resizable()
                                .scaledToFit()
                                .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:60)
                        }
                        
                        Spacer()
                        
                        ZZCoinBg()
                        
                    }.padding(.horizontal)
                }.padding([.top])
                
                Spacer()
                ZStack {
                    Image(.achievementsBgE)
                        .resizable()
                        
                       
                    
                    HStack(spacing: 15) {
                        ForEach(viewModel.achievements, id: \.self) { item in
                            ZStack {
                                VStack {
                                    
                                    Image(.tenCoinsE)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 40:50)
                                        .opacity(item.isAchieved ? 1 : 0)
                                    
                                    
                                    if item.isAchieved {
                                        
                                        Image(item.image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:120)
                                    } else {
                                        Image(.blueBgE)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:120)
                                    }
                                    
                                    if item.isAchieved {
                                        Image(.getBtnE)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 40:50)
                                    } else {
                                        Image(.lockBtnE)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 40:70)
                                    }
                                }.onTapGesture {
                                    if item.isAchieved {
                                        user.updateUserMoney(for: 10)
                                    }
                                    viewModel.achieveToggle(item)
                                }
                            }
                        }
                    }
                }.frame(maxWidth: .infinity)
            }
        }.background(
            ZStack {
                Image(.achievementsViewBgE)
                    .resizable()
                    .ignoresSafeArea()
                    .scaledToFill()
            }
        )
    }
}

#Preview {
    EAchievementsView()
}
