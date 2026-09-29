//
//  SigningView.swift
//  SY STORE
//
//  Created by samara on 14.04.2025.
//  Modified for SY STORE.
//

import SwiftUI
import PhotosUI
import NimbleViews

// MARK: - View
struct SigningView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var _optionsManager = OptionsManager.shared
    
    @State private var _temporaryOptions: Options = OptionsManager.shared.options
    @State private var _temporaryCertificate: Int
    @State private var _isAltPickerPresenting = false
    @State private var _isFilePickerPresenting = false
    @State private var _isImagePickerPresenting = false
    @State private var _isSigning = false
    
    @State var appIcon: UIImage?
    
    // متغير جديد خاص بتكرار التطبيقات
    @State private var _duplicationCount: Int = 0
    
    // MARK: Fetch
    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
        animation: .snappy
    ) private var certificates: FetchedResults<CertificatePair>
    
    private func _selectedCert() -> CertificatePair? {
        guard certificates.indices.contains(_temporaryCertificate) else { return nil }
        return certificates[_temporaryCertificate]
    }
    
    var app: AppInfoPresentable
    
    init(app: AppInfoPresentable) {
        self.app = app
        let storedCert = UserDefaults.standard.integer(forKey: "feather.selectedCert")
        __temporaryCertificate = State(initialValue: storedCert)
    }
        
    // MARK: Body
    var body: some View {
        NBNavigationView("توقيع التطبيق", displayMode: .inline) {
            Form {
                // هيدر مخصص لعرض الأيقونة والتحكم بها بشكل عصري
                appIconHeaderSection(for: app)
                
                _customizationOptions(for: app)
                
                _cert()
                
                _customizationProperties(for: app)
                
                Rectangle()
                    .foregroundStyle(.clear)
                    .frame(height: 100)
                    .listRowBackground(EmptyView())
            }
            .safeScrollContentBackground()
            .background {
                Color.clear
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()
            }
            .overlay {
                VStack(spacing: 0) {
                    Spacer()
                    NBVariableBlurView()
                        .frame(height: UIDevice.current.userInterfaceIdiom == .pad ? 70 : 90)
                        .rotationEffect(.degrees(180))
                        .overlay {
                            Button {
                                _start()
                            } label: {
                                NBSheetButton(title: "بدء التوقيع وتجهيز التطبيق", style: .prominent)
                                    .padding(.horizontal)
                                    .shadow(color: Color.accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .buttonStyle(.plain)
                            .offset(y: UIDevice.current.userInterfaceIdiom == .pad ? -10 : -20)
                        }
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .toolbar {
                NBToolbarButton(role: .dismiss)
                NBToolbarButton(
                    "إعادة تعيين",
                    style: .text,
                    placement: .topBarTrailing
                ) {
                    withAnimation(.snappy) {
                        _temporaryOptions = OptionsManager.shared.options
                        appIcon = nil
                        _duplicationCount = 0
                        _updateBundleID()
                    }
                }
            }
            .sheet(isPresented: $_isAltPickerPresenting) { SigningAlternativeIconView(app: app, appIcon: $appIcon, isModifing: .constant(true)) }
            .sheet(isPresented: $_isFilePickerPresenting) {
                FileImporterRepresentableView(
                    allowedContentTypes: [.image],
                    onDocumentsPicked: { urls in
                        guard let selectedFileURL = urls.first else { return }
                        self.appIcon = UIImage.fromFile(selectedFileURL)?.resizeToSquare()
                    }
                )
                .ignoresSafeArea()
            }
            .safePhotosPicker(isPresented: $_isImagePickerPresenting, appIcon: $appIcon)
            .disabled(_isSigning)
            .animation(.smooth, value: _isSigning)
        }
        .onAppear {
            if
                _optionsManager.options.ppqProtection,
                let identifier = app.identifier,
                let cert = _selectedCert(),
                cert.ppQCheck
            {
                _temporaryOptions.appIdentifier = "\(identifier).\(_optionsManager.options.ppqString)"
            }
            
            if
                let currentBundleId = app.identifier,
                let newBundleId = _temporaryOptions.identifiers[currentBundleId]
            {
                _temporaryOptions.appIdentifier = newBundleId
            }
            
            if
                let currentName = app.name,
                let newName = _temporaryOptions.displayNames[currentName]
            {
                _temporaryOptions.appName = newName
            }
        }
    }
    
    private func _updateBundleID() {
        let baseBundle = app.identifier ?? "com.unknown.app"
        if _duplicationCount > 0 {
            _temporaryOptions.appIdentifier = "\(baseBundle)\(_duplicationCount)"
        } else {
            _temporaryOptions.appIdentifier = baseBundle
        }
    }
}

// MARK: - Extension: View Layout Components
extension SigningView {
    
    // قسم الهيدر الجديد لعرض الأيقونة بشكل مميز وجذاب
    @ViewBuilder
    private func appIconHeaderSection(for app: AppInfoPresentable) -> some View {
        Section {
            VStack(spacing: 12) {
                Menu {
                    Button("اختيار أيقونة بديلة", systemImage: "app.dashed") { _isAltPickerPresenting = true }
                    Button("اختيار من الملفات", systemImage: "folder") { _isFilePickerPresenting = true }
                    Button("اختيار من الصور", systemImage: "photo") { _isImagePickerPresenting = true }
                } label: {
                    VStack(spacing: 8) {
                        if let icon = appIcon {
                            Image(uiImage: icon)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .cornerRadius(18)
                                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                        } else {
                            FRAppIconView(app: app, size: 80)
                                .cornerRadius(18)
                                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 12))
                            Text("تعديل الأيقونة")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.accentColor)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 8)
        }
        .listRowBackground(Color.clear)
    }
    
    @ViewBuilder
    private func _customizationOptions(for app: AppInfoPresentable) -> some View {
        NBSection("التخصيص الأساسي") {
            
            _infoCell("الاسم", desc: _temporaryOptions.appName ?? app.name, systemImage: "text.alignleft", iconColor: .blue) {
                SigningPropertiesView(
                    title: "الاسم",
                    initialValue: _temporaryOptions.appName ?? (app.name ?? ""),
                    bindingValue: $_temporaryOptions.appName
                )
            }
            
            _infoCell("المعرّف (Bundle ID)", desc: _temporaryOptions.appIdentifier ?? app.identifier, systemImage: "personalhotspot.circle", iconColor: .purple) {
                SigningPropertiesView(
                    title: "المعرّف",
                    initialValue: _temporaryOptions.appIdentifier ?? (app.identifier ?? ""),
                    bindingValue: $_temporaryOptions.appIdentifier
                )
            }
            
            // خلية التكرار المعاد تصميمها بالكامل بصرياً
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.orange.opacity(0.12))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "plus.square.on.square")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("تكرار التطبيق")
                        .font(.system(size: 15, weight: .medium))
                    Text("إنشاء نسخة مستقلة بجانب الأساسية")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 14) {
                    Button(action: {
                        withAnimation(.snappy) {
                            if _duplicationCount > 0 {
                                _duplicationCount -= 1
                                _updateBundleID()
                            }
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(_duplicationCount > 0 ? .red : Color(.systemGray4))
                    }
                    .buttonStyle(.plain)

                    Text("\(_duplicationCount)")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .frame(width: 20, alignment: .center)

                    Button(action: {
                        withAnimation(.snappy) {
                            _duplicationCount += 1
                            _updateBundleID()
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
            
            _infoCell("الإصدار", desc: _temporaryOptions.appVersion ?? app.version, systemImage: "v.circle.fill", iconColor: .green) {
                SigningPropertiesView(
                    title: "الإصدار",
                    initialValue: _temporaryOptions.appVersion ?? (app.version ?? ""),
                    bindingValue: $_temporaryOptions.appVersion
                )
            }
        }
    }
    
    @ViewBuilder
    private func _cert() -> some View {
        NBSection("شهادة التوقيع") {
            if let cert = _selectedCert() {
                NavigationLink {
                    CertificatesView(selectedCert: $_temporaryCertificate)
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.green.opacity(0.12))
                                .frame(width: 34, height: 34)
                            
                            Image(systemName: "shield.authcheck")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.green)
                        }
                        
                        CertificatesCellView(cert: cert)
                    }
                    .padding(.vertical, 2)
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.shield.fill")
                        .foregroundColor(.red)
                    Text("لا توجد شهادة نشطة حالياً")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.disabled())
                }
            }
        }
    }
    
    @ViewBuilder
    private func _customizationProperties(for app: AppInfoPresentable) -> some View {
        NBSection("خيارات المطورين المتقدمة") {
            DisclosureGroup(isExpanded: .constant(true)) {
                Group {
                    _customNavigationLink("مكتبات ومحاقن Dylibs", systemImage: "doc.zipper", iconColor: .teal) {
                        SigningDylibView(app: app, options: $_temporaryOptions.optional())
                    }
                    
                    _customNavigationLink("الإطارات والملحقات (Frameworks)", systemImage: "square.stack.3d.up.fill", iconColor: .indigo) {
                        SigningFrameworksView(app: app, options: $_temporaryOptions.optional())
                    }
                    
                    #if NIGHTLY || DEBUG
                    _customNavigationLink("ملف الصلاحيات (Entitlements)", systemImage: "lock.doc.fill", iconColor: .pink) {
                        SigningEntitlementsView(bindingValue: $_temporaryOptions.appEntitlementsFile)
                    }
                    #endif
                    
                    _customNavigationLink("أدوات التعديل والدمج (Tweaks)", systemImage: "puzzlepiece.extension.fill", iconColor: .purple) {
                        SigningTweaksView(options: $_temporaryOptions)
                    }
                }
                .padding(.vertical, 2)
            } label: {
                Label("أدوات الحقن والتعديل المباشر", systemImage: "gearshape.2.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            
            _customNavigationLink("خصائص ومفاتيح التوقيع الداخلي", systemImage: "slider.horizontal.3", iconColor: .gray) {
                Form { SigningOptionsView(
                    options: $_temporaryOptions,
                    temporaryOptions: _optionsManager.options
                )}
                .navigationTitle("الخصائص")
            }
            .padding(.vertical, 2)
        }
    }
    
    // دالة إنشاء خلايا التخصيص بشكلها الجديد والمنسق بالأيقونات والألوان
    @ViewBuilder
    private func _infoCell<V: View>(_ title: String, desc: String?, systemImage: String, iconColor: Color, @ViewBuilder destination: () -> V) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                
                Spacer()
                
                Text(desc ?? "تلقائي")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.vertical, 2)
        }
    }
    
    // دالة مساعدة لإنشاء روابط الانتقال داخل القوائم بشكل جذاب
    @ViewBuilder
    private func _customNavigationLink<V: View>(_ title: String, systemImage: String, iconColor: Color, @ViewBuilder destination: () -> V) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: systemImage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
    }
}

// MARK: - Extension: View (import)
extension SigningView {
    private func _start() {
        guard
            _selectedCert() != nil || _temporaryOptions.signingOption != .default
        else {
            UIAlertController.showAlertWithOk(
                title: "لا توجد شهادة",
                message: "يرجى الذهاب إلى الإعدادات واستيراد شهادة صالحة لمتجر CY STORE",
                isCancel: true
            )
            return
        }

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        _isSigning = true
		
        FR.signPackageFile(
            app,
            using: _temporaryOptions,
            icon: appIcon,
            certificate: _selectedCert()
        ) { error in
            if let error {
                let ok = UIAlertAction(title: "إغلاق", style: .cancel) { _ in
                    dismiss()
                }
                
                UIAlertController.showAlert(
                    title: "خطأ في عملية التوقيع",
                    message: error.localizedDescription,
                    actions: [ok]
                )
            } else {
                if
                    _temporaryOptions.post_deleteAppAfterSigned,
                    !app.isSigned
                {
                    Storage.shared.deleteApp(for: app)
                }
                
                if _temporaryOptions.post_installAppAfterSigned {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        NotificationCenter.default.post(name: Notification.Name("SYStore.installApp"), object: nil)
                    }
                }
                dismiss()
            }
        }
    }
}

// MARK: - Compatibility Extensions
private extension View {
    @ViewBuilder
    func safeScrollContentBackground() -> some View {
        if #available(iOS 16.0, *) {
            self.scrollContentBackground(.hidden)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func safePhotosPicker(isPresented: Binding<Bool>, appIcon: Binding<UIImage?>) -> some View {
        if #available(iOS 16.0, *) {
            self.modifier(PhotosPickerModifier(isPresented: isPresented, appIcon: appIcon))
        } else {
            self.sheet(isPresented: isPresented) {
                Text("اختيار الصور مدعوم في iOS 16 وما فوق. يرجى اختيار 'من الملفات'")
                    .padding()
            }
        }
    }
}

// Modifier مخصص لعزل أكواد PhotosPickerItem الخاصة بـ iOS 16
@available(iOS 16.0, *)
private struct PhotosPickerModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var appIcon: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    
    func body(content: Content) -> some View {
        content
            .photosPicker(isPresented: $isPresented, selection: $selectedItem)
            .onChange(of: selectedItem) { newValue in
                guard let newValue else { return }
                Task {
                    if let data = try? await newValue.loadTransferable(type: Data.self),
                       let image = UIImage(data: data)?.resizeToSquare() {
                        DispatchQueue.main.async {
                            appIcon = image
                        }
                    }
                }
            }
    }
}
