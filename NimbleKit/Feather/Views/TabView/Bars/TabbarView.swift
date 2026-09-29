//
//  TabbarView.swift
//  SY STORE
//
//  Created by samara on 23.03.2025.
//  Modified for SY STORE.
//

import SwiftUI

struct TabbarView: View {
	// تم التصحيح: تغيير القيمة الافتراضية من .sources (الملغية) إلى .home
	@State private var selectedTab: TabEnum = .home 

	var body: some View {
		TabView(selection: $selectedTab) {
			// تم التصحيح: استخدام \.self بدلاً من .hashValue لحل خطأ SelectionValue
			ForEach(TabEnum.defaultTabs, id: \.self) { tab in
				TabEnum.view(for: tab)
					.tabItem {
						Label(tab.title, systemImage: tab.icon)
					}
					.tag(tab)
			}
		}
	}
}
