//
//  HomeView.swift
//  CY STORE
//
//  Created by samara on 13.05.2026.
//  Modified for CY STORE - Safe Native Banners & Auto-Scroll.
//

import SwiftUI
import CoreData
import AltSourceKit
import NimbleViews

struct HomeView: View {
    @Environment(\.openURL) var openURL
    @StateObject var viewModel = SourcesViewModel.shared
    
    @State private var _allApps: [(source: ASRepository, app: ASRepository.App)] = []
    @State private var _recentApps: [(source: ASRepository, app: ASRepository.App)] = []
    @State private var _banners: [ASRepository.News] = []
    @State private var _selectedRoute: SourceAppRoute?
    @State private var isLoading = true
    @State private var _recentAppsCount = 0
    @State private var _currentBannerIndex = 0
    
    private let bannerTimer = Timer.publish(every: 3.5, on: .main, in: .common).autoconnect()

    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
        animation: .snappy
    ) private var _sources: FetchedResults<AltSource>

    var body: some View {
        NBNavigationView("الرئيسية") {
            ZStack {
                if isLoading && _recentApps.isEmpty && _banners.isEmpty {
                    ProgressView("جاري التحديث...")
                } else if _recentApps.isEmpty && _banners.isEmpty {
                    if #available(iOS 17, *) {
                        ContentUnavailableView {
                            Label("لا توجد تطبيقات", systemImage: "tray.fill")
                        } description: {
                            Text("لم يتم العثور على تطبيقات أو عروض حالياً.")
                        }
                    } else {
                        Text("لا توجد تطبيقات")
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        // MARK: - قسم البنرات الإعلانية (من ipa-black فقط)
                        if !_banners.isEmpty {
                            Section {
                                TabView(selection: $_currentBannerIndex) {
                                    ForEach(_banners.indices, id: \.self) { index in
                                        let banner = _banners[index]
                                        
                                        Button {
                                            if let url = banner.url {
                                                openURL(url)
                                            } else if let appID = banner.appID,
                                                      let targetApp = _allApps.first(where: { $0.app.id == appID }) {
                                                _selectedRoute = SourceAppRoute(source: targetApp.source, app: targetApp.app)
                                            }
                                        } label: {
                                            if let imgUrl = banner.imageURL {
                                                AsyncImage(url: imgUrl) { phase in
                                                    if let image = phase.image {
                                                        image
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fill)
                                                    } else if phase.error != nil {
                                                        Rectangle()
                                                            .fill(Color(uiColor: .secondarySystemBackground))
                                                            .overlay(Image(systemName: "photo.fill").foregroundColor(.secondary))
                                                    } else {
                                                        Rectangle()
                                                            .fill(Color(uiColor: .secondarySystemBackground))
                                                            .overlay(ProgressView())
                                                    }
                                                }
                                                .frame(height: 190)
                                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                                .padding(.horizontal, 16)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .tag(index)
                                    }
                                }
                                .frame(height: 230)
                                .tabViewStyle(.page(indexDisplayMode: .always))
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .onReceive(bannerTimer) { _ in
                                    if !_banners.isEmpty {
                                        withAnimation(.easeInOut(duration: 0.5)) {
                                            _currentBannerIndex = (_currentBannerIndex + 1) % _banners.count
                                        }
                                    }
                                }
                            }
                        }

                        // MARK: - قسم أحدث التطبيقات فرز حسب الإضافة مع العدد
                        if !_recentApps.isEmpty {
                            Section {
                                ForEach(_recentApps, id: \.app.currentUniqueId) { item in
                                    Button {
                                        _selectedRoute = SourceAppRoute(source: item.source, app: item.app)
                                    } label: {
                                        SourceAppsCellView(source: item.source, app: item.app)
                                    }
                                    .buttonStyle(.plain)
                                }
                            } header: {
                                HStack(spacing: 6) {
                                    Text("أحدث الإضافات")
                                        .font(.title3.bold())
                                        .foregroundColor(.primary)
                                    
                                    Text("\(_recentAppsCount)")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.accentColor.opacity(0.15))
                                        .foregroundColor(.accentColor)
                                        .clipShape(Capsule())
                                }
                                .padding(.top, 5)
                                .textCase(nil)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .compatNavigationDestination(item: $_selectedRoute) { route in
                SourceAppsDetailView(source: route.source, app: route.app)
            }
            .refreshable {
                // محاولة الجلب وفي حال حدوث خطأ في سورس خارجي لا يتوقف البرنامج
                do {
                    await viewModel.fetchSources(_sources, refresh: true)
                } catch {
                    print("صيانة السورسات الخارجية جارية...")
                }
                _loadData()
            }
        }
        .task(id: Array(_sources)) {
            do {
                await viewModel.fetchSources(_sources)
            } catch {
                print("تحميل صامت للسورسات المتاحة...")
            }
            _loadData()
        }
    }

    // MARK: - جلب البيانات الآمن
    private func _loadData() {
        isLoading = true
        Task {
            let rawSources = _sources
            
            var allApps: [(source: ASRepository, app: ASRepository.App)] = []
            var allBanners: [ASRepository.News] = []

            // التعديل: المرور على rawSources للوصول الآمن للمعلومات دون الحاجة لخاصية identifier
            for rawSource in rawSources {
                guard let source = viewModel.sources[rawSource] else { continue }
                
                // حماية 1: قراءة التطبيقات بشكل مستقل
                let sourceApps = source.apps
                for app in sourceApps {
                    allApps.append((source: source, app: app))
                }
                
                // حماية 2: عزل وقراءة بنرات ipa-black فقط
                if let sourceURLString = rawSource.sourceURL?.absoluteString.lowercased() {
                    if sourceURLString.contains("ipa-black") {
                        if let news = source.news {
                            allBanners.append(contentsOf: news)
                        }
                    }
                }
            }

            // فرز زمني دقيق تصاعدياً حسب الأحدث
            allApps.sort { firstItem, secondItem in
                let firstDate = firstItem.app.currentDate?.date ?? .distantPast
                let secondDate = secondItem.app.currentDate?.date ?? .distantPast
                return firstDate > secondDate
            }

            let topApps = Array(allApps.prefix(25))
            let validBanners = allBanners.filter { $0.imageURL != nil }

            DispatchQueue.main.async {
                self._allApps = allApps
                self._recentApps = topApps
                self._banners = validBanners
                self._recentAppsCount = topApps.count
                
                if self._currentBannerIndex >= validBanners.count {
                    self._currentBannerIndex = 0
                }
                self.isLoading = false
            }
        }
    }
}

// MARK: - Supporting Types
struct SourceAppRoute: Identifiable, Hashable {
    let source: ASRepository
    let app: ASRepository.App
    let id: String = UUID().uuidString
}

// MARK: - Extension for Navigation
extension View {
    @ViewBuilder
    func compatNavigationDestination<Item: Identifiable & Hashable, Destination: View>(
        item: Binding<Item?>,
        @ViewBuilder destination: @escaping (Item) -> Destination
    ) -> some View {
        if #available(iOS 16.0, *) {
            self.navigationDestination(isPresented: Binding(
                get: { item.wrappedValue != nil },
                set: { if !$0 { item.wrappedValue = nil } }
            )) {
                if let selectedItem = item.wrappedValue {
                    destination(selectedItem)
                }
            }
        } else {
            self.background(
                NavigationLink(
                    isActive: Binding(
                        get: { item.wrappedValue != nil },
                        set: { if !$0 { item.wrappedValue = nil } }
                    )
                ) {
                    if let selectedItem = item.wrappedValue {
                        destination(selectedItem)
                    } else {
                        EmptyView()
                    }
                } label: {
                    EmptyView()
                }
                .hidden()
            )
        }
    }
}
