//
//  SourcesView.swift
//  SY STORE
//
//  Created by samara on 10.04.2025.
//  Modified for Direct Apps Display.
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
    
    // MARK: Body
    var body: some View {
        NBNavigationView("التطبيقات") {
            // عرض قائمة التطبيقات المدمجة مباشرةً بدلاً من عرض قائمة السورسات
            SourceAppsView(object: Array(_sources), viewModel: viewModel)
        }
        .task(id: Array(_sources)) {
            await viewModel.fetchSources(_sources)
            _importDefaultSources() // جلب المصادر تلقائياً
        }
        .refreshable {
            await viewModel.fetchSources(_sources, refresh: true)
        }
    }
    
    // MARK: - دالة استيراد المصادر 
    private func _importDefaultSources() {
        let myStoreSources = [
            // === المصادر المعتمدة للمتجر ===
            "https://raw.githubusercontent.com/ipa-black/ATTACK-repo/refs/heads/main/ATTACK.json",
            "https://community-apps.sidestore.io/sidecommunity.json",
            "https://repository.apptesters.org"
        ]
        
        for source in myStoreSources {
            // التحقق مما إذا كان السورس موجوداً مسبقاً لمنع التكرار
            let exists = _sources.contains { $0.sourceURL?.absoluteString.lowercased() == source.lowercased() }
            if !exists {
                FR.handleSource(source) { }
            }
        }
    }
}
