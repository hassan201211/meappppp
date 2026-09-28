//
//  SigningEntitlementsView.swift
//  Feather
//
//  Created by samara on 20.04.2025.
//

import SwiftUI
import NimbleViews

// MARK: - View
struct SigningEntitlementsView: View {
    @State private var _isAddingPresenting = false
    @Binding var bindingValue: URL?
    
    // MARK: Body
    var body: some View {
        NBList(.localized("Entitlements")) {
            Section {
                if let ent = bindingValue {
                    // واجهة الملف المختار
                    selectedFileCard(for: ent)
                } else {
                    // واجهة طلب اختيار ملف
                    emptyStateCard
                }
            }
        }
        .sheet(isPresented: $_isAddingPresenting) {
            FileImporterRepresentableView(
                allowedContentTypes: [.xmlPropertyList, .plist, .entitlements],
                onDocumentsPicked: { urls in
                    guard let selectedFileURL = urls.first else { return }
                    
                    FileManager.default.moveAndStore(selectedFileURL, with: "FeatherEntitlement") { url in
                        // إضافة حركة سلسة عند ظهور الملف
                        withAnimation(.snappy) {
                            bindingValue = url
                        }
                    }
                }
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - مكونات الواجهة (Components)
    
    // 1. بطاقة الحالة الفارغة (دعوة للاختيار)
    private var emptyStateCard: some View {
        Button(action: { _isAddingPresenting = true }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 46, height: 46)
                    
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(.localized("Select entitlements file"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("اضغط لرفع ملف الصلاحيات (.plist, .entitlements)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.forward")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(.lightGray))
            }
            .padding(.vertical, 6)
        }
    }
    
    // 2. بطاقة الملف المختار حالياً
    private func selectedFileCard(for ent: URL) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 46, height: 46)
                
                Image(systemName: "lock.doc.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(ent.lastPathComponent)
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Text("ملف الصلاحيات جاهز للتوقيع")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // زر الحذف السريع المباشر
            Button(action: {
                withAnimation(.snappy) {
                    FileManager.default.deleteStored(ent) { _ in
                        bindingValue = nil
                    }
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color(.systemGray3))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 6)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withAnimation(.snappy) {
                    FileManager.default.deleteStored(ent) { _ in
                        bindingValue = nil
                    }
                }
            } label: {
                Label(.localized("Delete"), systemImage: "trash")
            }
        }
    }
}
