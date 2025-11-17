//
//  CPSettingsViewModel.swift
//  Eggstreme
//
//  Created by Dias Atudinov on 17.11.2025.
//


import SwiftUI

class CPSettingsViewModel: ObservableObject {
    @AppStorage("soundEnabled") var soundEnabled: Bool = true
    @AppStorage("vibraEnabled") var vibraEnabled: Bool = true
}
