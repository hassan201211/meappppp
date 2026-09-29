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
		case .home:         return "الرئيسية"
		case .apps:         return "التطبيقات"
		case .signing:      return "التوقيع"
		case .settings:     return "الإعدادات"
		case .certificates: return "الشهادات"
		}
	}
	
	var icon: String {
		switch self {
		case .home:         return "house.fill"
		case .apps:         return "square.grid.2x2.fill" // أيقونة التطبيقات المحدثة
		case .signing:      return "signature"
		case .settings:     return "gearshape.fill" // أيقونة الإعدادات المحدثة
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
