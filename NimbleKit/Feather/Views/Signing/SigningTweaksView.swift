//
//  SigningTweaksView.swift
//  Feather
//
//  Created by samara on 20.04.2025.
//

import SwiftUI
import NimbleViews

// MARK: - View
struct SigningTweaksView: View {
    @State private var _isAddingPresenting = false
    
    @Binding var options: Options
    
    // MARK: Body
    var body: some View {
        NBList(.localized("Tweaks")) {
            NBSection(.localized("Injection")) {
                SigningOptionsView.picker(
                    .localized("Injection Path"),
                    systemImage: "doc.badge.gearshape",
                    selection: $options.injectPath,
                    values: Options.InjectPath.allCases
                )
                SigningOptionsView.picker(
                    .localized("Injection Folder"),
                    systemImage: "folder.badge.gearshape",
                    selection: $options.injectFolder,
                    values: Options.InjectFolder.allCases
                )
                
                Toggle(isOn: $options.injectIntoExtensions) {
                    Label(.localized("Inject into Extensions"), systemImage: "syringe")
                }
            }
            
            NBSection(.localized("Tweaks")) {
                if !options.injectionFiles.isEmpty {
                    ForEach(options.injectionFiles, id: \.absoluteString) { tweak in
                        _file(tweak: tweak)
                    }
                } else {
                    // واجهة برمجية محسنة للحالة الفارغة
                    emptyTweaksState
                }
            }
        }
        .toolbar {
            NBToolbarButton(
                systemImage: "plus",
                style: .icon,
                placement: .topBarTrailing
            ) {
                _isAddingPresenting = true
            }
        }
        .sheet(isPresented: $_isAddingPresenting) {
            FileImporterRepresentableView(
                allowedContentTypes: [.dylib, .deb],
                allowsMultipleSelection: true,
                onDocumentsPicked: { urls in
                    guard !urls.isEmpty else { return }
                    
                    for url in urls {
                        FileManager.default.moveAndStore(url, with: "FeatherTweak") { url in
                            withAnimation(.snappy) {
                                options.injectionFiles.append(url)
                            }
                        }
                    }
                }
            )
            .ignoresSafeArea()
        }
        .animation(.smooth, value: options.injectionFiles)
    }
    
    // MARK: - المكونات المضافة (Custom Components)
    
    private var emptyTweaksState: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.08))
                    .frame(width: 64, height: 64)
                
                Image(systemName: "puzzlepiece.extension")
                    .font(.system(size: 28))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
            
            Text(verbatim: .localized("No files chosen."))
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.secondary)
            
            Text("اضغط على زر (+) في الأعلى لإضافة ملفات (.dylib, .deb) لدمجها داخل التطبيق.")
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - Extension: View
extension SigningTweaksView {
    @ViewBuilder
    private func _file(tweak: URL) -> some View {
        let isDeb = tweak.pathExtension.lowercased() == "deb"
        
        HStack(spacing: 12) {
            // تصميم أيقونة مخصصة للأداة المدمجة بحسب نوع الملف
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.purple.opacity(0.12))
                    .frame(width: 40, height: 40)
                
                Image(systemName: isDeb ? "archivebox.fill" : "puzzlepiece.extension.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.purple)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(tweak.lastPathComponent)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(tweak.pathExtension.uppercased() + " File")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            _fileActions(tweak: tweak)
        }
        .contextMenu {
            _fileActions(tweak: tweak)
        }
    }
    
    @ViewBuilder
    private func _fileActions(tweak: URL) -> some View {
        Button(role: .destructive) {
            withAnimation(.snappy) {
                FileManager.default.deleteStored(tweak) { url in
                    if let index = options.injectionFiles.firstIndex(where: { $0 == url }) {
                        options.injectionFiles.remove(at: index)
                    }
                }
            }
        } label: {
            Label(.localized("Delete"), systemImage: "trash")
        }
    }
}
