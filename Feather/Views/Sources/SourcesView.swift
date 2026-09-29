//
//  SourcesView.swift
//  SY STORE
//
//  Created by samara on 10.04.2025.
//  Modified for Direct Apps Display - Apple App Store Style.
//

import CoreData
import AltSourceKit
import SwiftUI
import NimbleViews

// MARK: - View
struct SourcesView: View {
    @StateObject var viewModel = SourcesViewModel.shared
    
    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
        animation: .snappy
    ) private var _sources: FetchedResults<AltSource>
    
    // تقسيم البيانات لسكاشن المتجر
    @State private var isLoading = true
    @State private var featuredApps: [(source: ASRepository, app: ASRepository.App)] = []
    @State private var essentialApps: [(source: ASRepository, app: ASRepository.App)] = []
    @State private var newApps: [(source: ASRepository, app: ASRepository.App)] = []
    
    // مسار التنقل للتفاصيل
    @State private var _selectedRoute: SourceAppRoute?
    
    // MARK: Body
    var body: some View {
        NBNavigationView("التطبيقات") {
            ZStack {
                Color(uiColor: .systemBackground).edgesIgnoringSafeArea(.all)
                
                if isLoading {
                    ProgressView("جاري جلب التطبيقات...")
                } else if featuredApps.isEmpty && essentialApps.isEmpty {
                    // التوافق مع إصدارات iOS المتعددة
                    if #available(iOS 17.0, *) {
                        ContentUnavailableView {
                            Label("لا توجد تطبيقات", systemImage: "app.dashed")
                        } description: {
                            Text("يرجى سحب الشاشة للأسفل للتحديث.")
                        }
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "app.dashed").font(.largeTitle)
                            Text("لا توجد تطبيقات").font(.headline)
                            Text("يرجى سحب الشاشة للأسفل للتحديث.").font(.subheadline)
                        }
                        .foregroundColor(.secondary)
                        .padding(.top, 50)
                    }
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 35) {
                            
                            // MARK: 1. الكاروسيل الرئيسي (Featured Apps)
                            if !featuredApps.isEmpty {
                                TabView {
                                    ForEach(featuredApps, id: \.app.currentUniqueId) { item in
                                        Button {
                                            _selectedRoute = SourceAppRoute(source: item.source, app: item.app)
                                        } label: {
                                            FeaturedAppBanner(app: item.app)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .frame(height: 320)
                                .tabViewStyle(.page(indexDisplayMode: .never))
                            }
                            
                            Divider().padding(.horizontal, 20)
                            
                            // MARK: 2. تطبيقات لا غنى عنها (Essential Apps)
                            if !essentialApps.isEmpty {
                                AppSectionHorizontalView(
                                    title: "تطبيقات لا غنى عنها",
                                    subtitle: "أفضل الخيارات لك",
                                    apps: essentialApps,
                                    onSelect: { route in _selectedRoute = route }
                                )
                            }
                            
                            Divider().padding(.horizontal, 20)
                            
                            // MARK: 3. أحدث الإضافات (New Apps)
                            if !newApps.isEmpty {
                                AppSectionHorizontalView(
                                    title: "أحدث الإضافات",
                                    subtitle: "اكتشف ما هو جديد",
                                    apps: newApps,
                                    onSelect: { route in _selectedRoute = route }
                                )
                            }
                        }
                        .padding(.vertical, 15)
                    }
                }
            }
            .compatNavigationDestination(item: $_selectedRoute) { route in
                SourceAppsDetailView(source: route.source, app: route.app)
            }
        }
        .task(id: Array(_sources)) {
            await viewModel.fetchSources(_sources)
            _importDefaultSources()
            _loadStoreData()
        }
        .refreshable {
            await viewModel.fetchSources(_sources, refresh: true)
            _loadStoreData()
        }
    }
    
    // MARK: - فرز وتحميل البيانات للعرض المباشر
    private func _loadStoreData() {
        isLoading = true
        Task {
            var allApps: [(source: ASRepository, app: ASRepository.App)] = []
            
            for rawSource in _sources {
                guard let source = viewModel.sources[rawSource] else { continue }
                for app in source.apps {
                    allApps.append((source: source, app: app))
                }
            }
            
            // ترتيب حسب الأحدث
            allApps.sort {
                ($0.app.currentDate?.date ?? .distantPast) > ($1.app.currentDate?.date ?? .distantPast)
            }
            
            DispatchQueue.main.async {
                if allApps.count > 0 {
                    self.featuredApps = Array(allApps.prefix(4))
                }
                
                if allApps.count > 4 {
                    let nextApps = Array(allApps.dropFirst(4))
                    self.essentialApps = Array(nextApps.prefix(9)) 
                }
                
                if allApps.count > 13 {
                    self.newApps = Array(allApps.dropFirst(13).prefix(12))
                } else {
                    self.newApps = allApps
                }
                
                self.isLoading = false
            }
        }
    }
    
    // MARK: - دالة استيراد المصادر
    private func _importDefaultSources() {
        let myStoreSources = [
            "https://raw.githubusercontent.com/ipa-black/ATTACK-repo/refs/heads/main/ATTACK.json",
            "https://community-apps.sidestore.io/sidecommunity.json",
            "https://repository.apptesters.org"
        ]
        
        for source in myStoreSources {
            let exists = _sources.contains { $0.sourceURL?.absoluteString.lowercased() == source.lowercased() }
            if !exists {
                FR.handleSource(source) { }
            }
        }
    }
}

// MARK: - 1. تصميم بانر التطبيقات المميزة (Featured App)
struct FeaturedAppBanner: View {
    let app: ASRepository.App
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("تطبيق مميز")
                .font(.caption.weight(.bold))
                .foregroundColor(.blue)
                .textCase(nil)
            
            // حماية المتغيرات الاختيارية
            Text(app.name ?? "تطبيق غير معروف")
                .font(.title2.weight(.regular))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Text(app.developerName ?? "المطور غير معروف")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            GeometryReader { proxy in
                if let iconUrl = app.iconURL {
                    AsyncImage(url: iconUrl) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: proxy.size.width, height: 200)
                                .clipped()
                                .cornerRadius(12)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.secondary.opacity(0.1))
                        }
                    }
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.1))
                }
            }
            .frame(height: 200)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - 2. تصميم التمرير الأفقي (Horizontal App Section)
struct AppSectionHorizontalView: View {
    let title: String
    let subtitle: String
    let apps: [(source: ASRepository, app: ASRepository.App)]
    let onSelect: (SourceAppRoute) -> Void
    
    let rows = [
        GridItem(.fixed(75), spacing: 10),
        GridItem(.fixed(75), spacing: 10),
        GridItem(.fixed(75), spacing: 10)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.title2.bold())
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("عرض الكل") {}
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: rows, spacing: 15) {
                    ForEach(apps, id: \.app.currentUniqueId) { item in
                        Button {
                            onSelect(SourceAppRoute(source: item.source, app: item.app))
                        } label: {
                            CompactAppRow(app: item.app)
                                .frame(width: UIScreen.main.bounds.width - 40)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - 3. تصميم الصف المصغر (Compact App Row)
struct CompactAppRow: View {
    let app: ASRepository.App
    
    var body: some View {
        HStack(spacing: 12) {
            // أيقونة التطبيق
            if let iconUrl = app.iconURL {
                AsyncImage(url: iconUrl) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fit)
                    } else {
                        RoundedRectangle(cornerRadius: 14).fill(Color.gray.opacity(0.2))
                    }
                }
                .frame(width: 65, height: 65)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                )
            } else {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 65, height: 65)
            }
            
            // تفاصيل التطبيق مع حماية المتغيرات
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name ?? "تطبيق غير معروف")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(app.developerName ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // زر التثبيت
            VStack {
                Text("تثبيت")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 7)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 5)
    }
}
