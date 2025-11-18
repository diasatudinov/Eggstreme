//
//  EShopView.swift
//  Eggstreme
//
//

import SwiftUI

struct EShopView: View {
    @StateObject var user = ZZUser.shared
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: EShopViewModel
    @State var category: JGItemCategory = .skin
    var body: some View {
        ZStack {
            
            ZStack {
                
                Image(.achievementsBgE)
                    .resizable()
                    .scaledToFit()
                
                
                VStack {
                    
                    HStack {
                        
                        ForEach(category == .skin ? viewModel.shopSkinItems :viewModel.shopBgItems, id: \.self) { item in
                            achievementItem(item: item, category: category == .skin ? .skin : .background)
                            
                        }
                        
                        
                    }
                    
                }
                
                
            }.frame(height: 270)
            
            
            
            VStack {
                HStack {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                        
                        
                    } label: {
                        Image(.xmarkE)
                            .resizable()
                            .scaledToFit()
                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:50)
                    }
                    
                    Spacer()
                    
                    ZZCoinBg()
                    
                }.padding()
                Spacer()
                
            }
            
            VStack {
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button {
                        category = .skin
                    } label: {
                        Image(.skinIconE)
                            .resizable()
                            .scaledToFit()
                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:80)
                            .offset(y: category == .skin ? 0 : 20)
                    }
                    
                    Button {
                        category = .background
                    } label: {
                        Image(.bgIconE)
                            .resizable()
                            .scaledToFit()
                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:80)
                            .offset(y: category == .background ? 0 : 20)
                    }
                    
                    Spacer()
                }.padding(.leading, 40)
                
            }.ignoresSafeArea()
            
        }.frame(maxWidth: .infinity)
            .background(
                ZStack {
                    Image(.achievementsViewBgE)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                    
                }
            )
    }
    
    @ViewBuilder func achievementItem(item: JGItem, category: JGItemCategory) -> some View {
        ZStack {
            
            Image(item.icon)
                .resizable()
                .scaledToFit()
            VStack {
                
                Image(.twentyCoinsE)
                    .resizable()
                    .scaledToFit()
                    .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 50:42)
                    .opacity(viewModel.isMoneyEnough(item: item, user: user, category: category) ? 1:0.5)
                
                Spacer()
                Button {
                    viewModel.selectOrBuy(item, user: user, category: category)
                } label: {
                    
                    if viewModel.isPurchased(item, category: category) {
                        ZStack {
                            Image(viewModel.isCurrentItem(item: item, category: category) ? .usedBtnBgE : .useBtnBgE)
                                .resizable()
                                .scaledToFit()
                            
                        }.frame(height: ZZDeviceManager.shared.deviceType == .pad ? 50:42)
                        
                    } else {
                        Image(.buyBtnBgE)
                            .resizable()
                            .scaledToFit()
                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 50:42)
                    }
                    
                    
                }
            }.frame(height: ZZDeviceManager.shared.deviceType == .pad ? 300:200)
            
        }.frame(height: ZZDeviceManager.shared.deviceType == .pad ? 300:145)
        
    }
}




#Preview {
    EShopView(viewModel: EShopViewModel())
}
