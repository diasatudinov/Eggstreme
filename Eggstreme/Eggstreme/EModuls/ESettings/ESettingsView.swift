//
//  ESettingsView.swift
//  Eggstreme
//
//

import SwiftUI

struct ESettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var settingsVM = CPSettingsViewModel()
    var body: some View {
        ZStack {
            
            VStack {
                
                
                ZStack {
                    
                    Image(.settingsBgE)
                        .resizable()
                        .scaledToFit()
                    
                    
                    VStack(alignment: .leading, spacing: 30) {
                        
                        HStack(spacing: 30) {
                            
                            Image(.musicTextE)
                                .resizable()
                                .scaledToFit()
                                .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 80:25)
                            
                            Spacer()
                            
                            Button {
                                withAnimation {
                                    settingsVM.soundEnabled.toggle()
                                }
                            } label: {
                                Image(settingsVM.soundEnabled ? .onE:.offE)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 80:40)
                            }
                        }
                        
                        
                        HStack(spacing: 30) {
                            
                            Image(.volumeTextE)
                                .resizable()
                                .scaledToFit()
                                .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 80:25)
                            
                            Spacer()
                            
                            Button {
                                withAnimation {
                                    settingsVM.vibraEnabled.toggle()
                                }
                            } label: {
                                Image(settingsVM.vibraEnabled ? .onE:.offE)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 80:40)
                            }
                        }
                        HStack {
                            Image(.languageTextE)
                                .resizable()
                                .scaledToFit()
                                .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 80:25)
                            
                            Spacer()
                            
                            Image(.englisgTextE)
                                .resizable()
                                .scaledToFit()
                                .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 80:35)
                        }
                        
                    }.frame(width: ZZDeviceManager.shared.deviceType == .pad ? 88:300)
                    
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                presentationMode.wrappedValue.dismiss()
                                
                            } label: {
                                Image(.xmarkE)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:55)
                            }
                        }
                        Spacer()
                    }
                    
                }.frame(width: 390, height: ZZDeviceManager.shared.deviceType == .pad ? 88:300)
                
                
                
            }.padding(.top, 50)
            
            VStack {
                ZStack {
                    HStack {
                        
                        
                    }.padding()
                }
                Spacer()
                
            }
        }.frame(maxWidth: .infinity)
            .background(
                ZStack {
                    Image(.appBgE)
                        .resizable()
                        .ignoresSafeArea()
                        .scaledToFill()
                }
            )
    }
}


#Preview {
    ESettingsView()
}
