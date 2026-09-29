//
//  TabEnum.swift
//  SY STORE
//
//  Created by samara on 22.03.2025.
//  Modified for SY STORE.
//

import SwiftUI
import NimbleViews

enum TabEnum: String, CaseIterable, Hashable {
    case home
    case apps
    case signing
    case settings
    case certificates
    
    var title: String {
        switch self {
        case .home:         return "اليوم"
        case .apps:         return "المصادر"
        case .signing:      return "التطبيقات"
        case .settings:     return "الإعدادات"
        case .certificates: return "الشهادات"
        }
    }
    
    var icon: String {
        switch self {
        case .home:         return "macwindow"
        case .apps:         return "cart.fill"
        case .signing:      return "square.stack.3d.up.fill"
        case .settings:     return "gearshape.fill"
        case .certificates: return "checkmark.seal.fill"
        }
    }
    
    @ViewBuilder
    static func view(for tab: TabEnum) -> some View {
        switch tab {
        case .home: HomeView() 
        case .apps: SourcesView() 
        case .signing: LibraryView()
        case .settings: SettingsView()
        case .certificates: NBNavigationView("الشهادات") { CertificatesView() }
        }
    }
    
    static var defaultTabs: [TabEnum] {
        return [
            .home,
            .apps,
            .signing,
            .settings
        ]
    }
    
    static var customizableTabs: [TabEnum] {
        return [
            .certificates
        ]
    }
}
