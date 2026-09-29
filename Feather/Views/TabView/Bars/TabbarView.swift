//
//  TabbarView.swift
//  SY STORE
//
//  Created by samara on 23.03.2025.
//  Modified for SY STORE.
//

import SwiftUI

struct TabbarView: View {
    @State private var selectedTab: TabEnum = .home
    @State private var showSearch: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // عرض الشاشة المحددة بناءً على التبويب
            TabEnum.view(for: selectedTab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // الشريط السفلي العائم (شكل أبل ستور العصري)
            HStack(spacing: 12) {
                // زر البحث المنفصل الدائري على اليسار
                Button(action: {
                    showSearch = true
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }

                // كبسولة باقي التبويبات
                HStack(spacing: 0) {
                    ForEach(TabEnum.defaultTabs, id: \.self) { tab in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = tab
                            }
                        }) {
                            VStack(spacing: 3) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 16))
                                Text(tab.title)
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(selectedTab == tab ? .blue : .gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(selectedTab == tab ? Color.white.opacity(0.15) : Color.clear)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
                .background(Color.white.opacity(0.12))
                .clipShape(Capsule())
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showSearch) {
            SearchView()
        }
    }
}
