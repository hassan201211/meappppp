//
//  SourceAppsView.swift
//  SY STORE
//
//  Created by samara on 1.05.2025.
//  Modified for SY STORE - Unified Store.
//

import SwiftUI
import AltSourceKit
import NimbleViews
import UIKit

// MARK: - Extension: View (Enil & Categories)
extension SourceAppsView {
    enum SortOption: String, CaseIterable {
        case `default` = "default"
        case name
        case date
        
        var displayName: String {
            switch self {
            case .default:  return "الافتراضي"
            case .name:     return "الاسم"
            case .date:     return "التاريخ"
            }
        }
    }
    
    enum AppCategory: String, CaseIterable {
        case all = "الكل"
        case social = "اجتماعي"
        case entertainment = "ترفيه"
        case games = "ألعاب"
        case photoVideo = "صورة فيديو"
        case developer = "مطور"
        case lifestyle = "نمط الحياة"
        case other = "غير ذلك"
    }
}

// MARK: - View
struct SourceAppsView: View {
    @AppStorage("SYStore.sortOptionRawValue") private var _sortOptionRawValue: String = SortOption.default.rawValue
    @AppStorage("SYStore.sortAscending") private var _sortAscending: Bool = true
    
    @State private var _sortOption: SortOption = .default
    @State private var _selectedRoute: SourceAppRoute?
    @State private var _selectedCategory: AppCategory = .all
    
    @State var isLoading = true
    @State var hasLoadedOnce = false
    @State private var _searchText = ""

    var object: [AltSource]
    @ObservedObject var viewModel: SourcesViewModel
    @State private var _sources: [ASRepository]?
    
    // MARK: Body
    var body: some View {
        VStack(spacing: 0) {
            // 1. شريط التصنيفات الاحترافي (يظهر فقط إذا تم تحميل التطبيقات)
            if let _sources, !_sources.isEmpty {
                _categoryChips()
                    .zIndex(1) // للحفاظ على الظل فوق قائمة التطبيقات
            }
            
            // 2. قائمة التطبيقات
            ZStack {
                if let _sources, !_sources.isEmpty {
                    SourceAppsTableRepresentableView(
                        sources: _sources,
                        searchText: $_searchText,
                        sortOption: $_sortOption,
                        sortAscending: $_sortAscending,
                        selectedCategory: $_selectedCategory, // تمرير التصنيف
                        onSelect: { self._selectedRoute = $0 }
                    )
                    .ignoresSafeArea(edges: .bottom) // تجاهل الحافة السفلية فقط لكي لا يتداخل مع الأقسام
                } else {
                    ProgressView("جاري تحميل التطبيقات...")
                }
            }
        }
        .navigationTitle("التطبيقات")
        .searchable(text: $_searchText, placement: .platform(), prompt: "ابحث في التطبيقات...")
        .toolbar {
            NBToolbarMenu(
                systemImage: "arrow.up.arrow.down.circle", // تغيير الأيقونة لتناسب خيارات الترتيب
                style: .icon,
                placement: .topBarTrailing
            ) {
                // تمت إزالة خيارات التصنيف من هنا وأبقينا الترتيب فقط
                _sortActions()
            }
        }
        .onAppear {
            if !hasLoadedOnce, viewModel.isFinished {
                _load()
                hasLoadedOnce = true
            }
            _sortOption = SortOption(rawValue: _sortOptionRawValue) ?? .default
        }
        .onChange(of: viewModel.isFinished) { _ in
            _load()
        }
        .onChange(of: _sortOption) { newValue in
            _sortOptionRawValue = newValue.rawValue
        }
        .navigationDestinationIfAvailable(item: $_selectedRoute) { route in
            SourceAppsDetailView(source: route.source, app: route.app)
        }
    }
    
    private func _load() {
        isLoading = true
        
        Task {
            let loadedSources = object.compactMap { viewModel.sources[$0] }
            _sources = loadedSources
            withAnimation(.easeIn(duration: 0.2)) {
                isLoading = false
            }
        }
    }
    
    struct SourceAppRoute: Identifiable, Hashable {
        let source: ASRepository
        let app: ASRepository.App
        let id: String = UUID().uuidString
    }
}

// MARK: - Extension: View (Sort & Category Builders)
extension SourceAppsView {
    
    // تصميم شريط التصنيفات الأفقي
    @ViewBuilder
    private func _categoryChips() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AppCategory.allCases, id: \.self) { category in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            _selectedCategory = category
                        }
                    } label: {
                        Text(category.rawValue)
                            .font(.system(size: 15, weight: _selectedCategory == category ? .bold : .medium))
                            .foregroundColor(_selectedCategory == category ? .white : .primary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                ZStack {
                                    if _selectedCategory == category {
                                        Color.accentColor
                                            .cornerRadius(20)
                                            .shadow(color: Color.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                                    } else {
                                        Color(UIColor.secondarySystemBackground)
                                            .cornerRadius(20)
                                    }
                                }
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(
            Color(UIColor.systemBackground)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 4)
        )
    }

    @ViewBuilder
    private func _sortActions() -> some View {
        Section("ترتيب حسب") {
            ForEach(SortOption.allCases, id: \.displayName) { opt in
                _sortButton(for: opt)
            }
        }
    }
    
    private func _sortButton(for option: SortOption) -> some View {
        Button {
            if _sortOption == option {
                _sortAscending.toggle()
            } else {
                _sortOption = option
                _sortAscending = true
            }
        } label: {
            HStack {
                Text(option.displayName)
                Spacer()
                if _sortOption == option {
                    Image(systemName: _sortAscending ? "chevron.up" : "chevron.down")
                }
            }
        }
    }
}

extension View {
    @ViewBuilder
    func navigationDestinationIfAvailable<Item: Identifiable & Hashable, Destination: View>(
        item: Binding<Item?>,
        @ViewBuilder destination: @escaping (Item) -> Destination
    ) -> some View {
        if #available(iOS 17, *) {
            self.navigationDestination(item: item, destination: destination)
        } else {
            self
        }
    }
}
