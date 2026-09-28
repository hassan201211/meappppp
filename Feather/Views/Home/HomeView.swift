//
//  HomeView.swift
//  CY STORE
//
//  Created by samara on 13.05.2026.
//  Modified for CY STORE - Today App Store Style & No Ads.
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
    @State private var _selectedRoute: SourceAppRoute?
    @State private var isLoading = true
    @State private var _recentAppsCount = 0

    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
        animation: .snappy
    ) private var _sources: FetchedResults<AltSource>

    // تنسيق التاريخ لواجهة "اليوم"
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.dateFormat = "EEEE، d MMMM"
        return formatter.string(from: Date()).uppercased()
    }

    var body: some View {
        NBNavigationView("") {
            ZStack {
                Color(uiColor: .systemBackground).edgesIgnoringSafeArea(.all)
                
                if isLoading && _recentApps.isEmpty {
                    ProgressView("جاري التحديث...")
                } else if _recentApps.isEmpty {
                    if #available(iOS 17, *) {
                        ContentUnavailableView {
                            Label("لا توجد تطبيقات", systemImage: "tray.fill")
                        } description: {
                            Text("لم يتم العثور على تطبيقات حالياً.")
                        }
                    } else {
                        Text("لا توجد تطبيقات")
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 30) {
                            
                            // MARK: - ترويسة واجهة "اليوم" (Today Header)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(formattedDate)
                                    .font(.footnote.weight(.bold))
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Text("اليوم")
                                        .font(.largeTitle.weight(.bold))
                                    Spacer()
                                    
                                    // أيقونة الحساب (اختياري، مشابهة لمتجر آبل)
                                    Image(systemName: "person.crop.circle")
                                        .font(.largeTitle)
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 10)

                            // MARK: - كروت التطبيقات (Today Cards)
                            ForEach(_recentApps, id: \.app.currentUniqueId) { item in
                                Button {
                                    _selectedRoute = SourceAppRoute(source: item.source, app: item.app)
                                } label: {
                                    TodayCardView(app: item.app)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarHidden(true)
            .compatNavigationDestination(item: $_selectedRoute) { route in
                SourceAppsDetailView(source: route.source, app: route.app)
            }
            .refreshable {
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

    // MARK: - جلب البيانات الآمن (بدون إعلانات)
    private func _loadData() {
        isLoading = true
        Task {
            let rawSources = _sources
            var allApps: [(source: ASRepository, app: ASRepository.App)] = []

            for rawSource in rawSources {
                guard let source = viewModel.sources[rawSource] else { continue }
                
                let sourceApps = source.apps
                for app in sourceApps {
                    allApps.append((source: source, app: app))
                }
            }

            // فرز زمني دقيق تصاعدياً حسب الأحدث
            allApps.sort { firstItem, secondItem in
                let firstDate = firstItem.app.currentDate?.date ?? .distantPast
                let secondDate = secondItem.app.currentDate?.date ?? .distantPast
                return firstDate > secondDate
            }

            let topApps = Array(allApps.prefix(25))

            DispatchQueue.main.async {
                self._allApps = allApps
                self._recentApps = topApps
                self._recentAppsCount = topApps.count
                self.isLoading = false
            }
        }
    }
}

// MARK: - Today Card View (تصميم الكرت لمتجر آبل)
struct TodayCardView: View {
    let app: ASRepository.App
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // الخلفية (استخدام أيقونة التطبيق مع تمويه كخلفية فنية)
            if let iconUrl = app.iconURL {
                AsyncImage(url: iconUrl) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 360)
                            .blur(radius: 30)
                            .overlay(Color.black.opacity(0.2))
                    } else {
                        Rectangle().fill(Color.secondary.opacity(0.2))
                    }
                }
            }
            
            // محتوى الكرت من الأعلى
            VStack(alignment: .leading) {
                Text("أحدث الإضافات")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(radius: 2)
                
                Text(app.name)
                    .font(.title.weight(.bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .shadow(radius: 3)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            
            // الشريط السفلي لتفاصيل التطبيق
            HStack(spacing: 12) {
                if let iconUrl = app.iconURL {
                    AsyncImage(url: iconUrl) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fit)
                        } else {
                            Color.secondary.opacity(0.3)
                        }
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name)
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(app.developerName ?? "مطور غير معروف")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // زر التحميل الوهمي (الشكل فقط، الضغط يتم على الكرت كاملاً)
                Text("عرض")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(Capsule())
            }
            .padding(16)
            .background(.ultraThinMaterial)
        }
        .frame(height: 360)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
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
