//
//  SearchView.swift
//  SY STORE
//

import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText: String = ""
    
    // بيانات وهمية للتجربة
    @State private var allApps = MockApp.dummyData
    
    var filteredApps: [MockApp] {
        if searchText.isEmpty {
            return []
        } else {
            return allApps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    let trendingSearches = ["WhatsApp Plus", "Spotify Premium", "Instagram Dark", "TikTok", "PUBG Hack"]

    var body: some View {
        // استخدام NavigationView لدعم إصدارات iOS القديمة والحديثة معاً
        NavigationView {
            List {
                if searchText.isEmpty {
                    Section {
                        ForEach(trendingSearches, id: \.self) { term in
                            Button(action: {
                                searchText = term
                            }) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.accentColor)
                                    Text(term)
                                        .foregroundColor(.primary)
                                        .font(.system(size: 18, weight: .regular))
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    } header: {
                        Text("اكتشف")
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                            .textCase(nil)
                            .padding(.bottom, 5)
                    }
                    .listRowSeparator(.hidden)
                    
                } else {
                    if filteredApps.isEmpty {
                        // حماية لدعم إصدارات ما قبل iOS 17
                        if #available(iOS 17.0, *) {
                            ContentUnavailableView.search(text: searchText)
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "magnifyingglass").font(.largeTitle)
                                Text("لا توجد نتائج")
                                    .font(.headline)
                                Text("لم نعثر على نتائج لـ '\(searchText)'")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                        }
                    } else {
                        ForEach(filteredApps) { app in
                            AppSearchRowView(app: app)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("البحث")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "الألعاب، التطبيقات، والمزيد")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("تم") {
                        dismiss()
                    }
                    .font(.headline)
                }
            }
        }
        .navigationViewStyle(.stack) // يمنع الانقسام الخاطئ للشاشة في الآيباد
        .environment(\.layoutDirection, .rightToLeft)
    }
}

// MARK: - تصميم خلية التطبيق في نتائج البحث (App Row)
struct AppSearchRowView: View {
    let app: MockApp
    
    var body: some View {
        HStack(spacing: 15) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 60, height: 60)
                .cornerRadius(14)
                .overlay(
                    Image(systemName: "app.fill")
                        .resizable()
                        .padding(15)
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(app.developer)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: {
                // أمر التثبيت
            }) {
                Text("تثبيت")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - بيانات وهمية للتجربة (المودل الخاص بواجهة البحث)
struct MockApp: Identifiable {
    let id = UUID()
    let name: String
    let developer: String
    
    static let dummyData = [
        MockApp(name: "WhatsApp Plus", developer: "Fouad Mods"),
        MockApp(name: "Spotify Premium", developer: "Spotify Ltd."),
        MockApp(name: "Instagram Dark", developer: "Meta"),
        MockApp(name: "TikTok", developer: "ByteDance"),
        MockApp(name: "YouTube Reborn", developer: "Twitch"),
        MockApp(name: "PUBG Hack", developer: "Tencent")
    ]
}
