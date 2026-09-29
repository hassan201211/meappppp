//
//  SYStoreApp.swift
//  SY STORE
//

import SwiftUI
import Nuke
import IDeviceSwift
import OSLog
import CoreData

@main
struct SYStoreApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let heartbeat = HeartbeatManager.shared
    @StateObject var downloadManager = DownloadManager.shared
    let storage = Storage.shared
    
    // تم ضبط اللون الافتراضي ليصبح أزرق أبل الرسمي
    @AppStorage("Feather.userTintColor") private var appTintColor: String = "#007AFF"
    
    // متغير للتحكم في ظهور شاشة البداية (Splash Screen)
    @State private var showSplash: Bool = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // الخلفية السوداء الحقيقية (True Black)
                Color.black.ignoresSafeArea()
                
                if showSplash {
                    // MARK: 1. شاشة البداية (Splash Screen)
                    SplashScreenView(appTintColor: appTintColor)
                        .transition(.opacity)
                } else {
                    // MARK: 2. واجهة التطبيق الرئيسية
                    VStack(spacing: 0) {
                        DownloadHeaderView(downloadManager: downloadManager)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        
                        VariedTabbarView()
                            .environment(\.managedObjectContext, storage.context)
                            .onOpenURL(perform: _handleURL)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    // تم التعديل هنا: استخدام easeInOut لدعم iOS 15 بدلاً من smooth المحصورة في iOS 17
                    .animation(.easeInOut, value: downloadManager.manualDownloads.description)
                    .onReceive(NotificationCenter.default.publisher(for: .heartbeatInvalidHost)) { _ in
                        DispatchQueue.main.async { UIAlertController.showAlertWithOk(title: "خطأ", message: "ملف الربط غير متوافق.") }
                    }
                    .onAppear {
                        if let style = UIUserInterfaceStyle(rawValue: UserDefaults.standard.integer(forKey: "Feather.userInterfaceStyle")) {
                            UIApplication.topViewController()?.view.window?.overrideUserInterfaceStyle = style
                        }
                        UIApplication.topViewController()?.view.window?.tintColor = UIColor(Color(hex: appTintColor))
                    }
                    .onChange(of: appTintColor) { newColor in
                        UIApplication.topViewController()?.view.window?.tintColor = UIColor(Color(hex: newColor))
                    }
                }
            }
            .environment(\.colorScheme, .dark) // تفعيل المظهر الداكن التلقائي
            .tint(Color(hex: appTintColor))
            .onAppear {
                // إخفاء شاشة البداية بعد 2 ثانية بلمسة ناعمة
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        showSplash = false
                    }
                }
            }
        }
    }
    
    // MARK: - معالجة الروابط العميقة (Deep Links)
    private func _handleURL(_ url: URL) {
        if url.scheme == "systore" {
            if url.host == "import-certificate" {
                guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let queryItems = components.queryItems else { return }
                func queryValue(_ name: String) -> String? { queryItems.first(where: { $0.name == name })?.value?.removingPercentEncoding }
                guard let p12Base64 = queryValue("p12"), let provisionBase64 = queryValue("mobileprovision"), let passwordBase64 = queryValue("password"), let passwordData = Data(base64Encoded: passwordBase64), let password = String(data: passwordData, encoding: .utf8) else { return }
                
                let generator = UINotificationFeedbackGenerator()
                generator.prepare()
                
                guard let p12URL = FileManager.default.decodeAndWrite(base64: p12Base64, pathComponent: ".p12"),
                      let provisionURL = FileManager.default.decodeAndWrite(base64: provisionBase64, pathComponent: ".mobileprovision"),
                      FR.checkPasswordForCertificate(for: p12URL, with: password, using: provisionURL) else {
                    generator.notificationOccurred(.error)
                    DispatchQueue.main.async { UIAlertController.showAlertWithOk(title: "خطأ", message: "كلمة المرور أو ملفات الشهادة غير صالحة.") }
                    return
                }
                
                FR.handleCertificateFiles(p12URL: p12URL, provisionURL: provisionURL, p12Password: password) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            UIAlertController.showAlertWithOk(title: "فشل الاستيراد", message: error.localizedDescription)
                        } else {
                            generator.notificationOccurred(.success)
                            UIAlertController.showAlertWithOk(title: "نجاح", message: "تم استيراد الشهادة وتفعيلها بنجاح!")
                        }
                    }
                }
                return
            }
            if let fullPath = url.validatedScheme(after: "/source/") { FR.handleSource(fullPath) { } }
            if let fullPath = url.validatedScheme(after: "/install/"), let downloadURL = URL(string: fullPath) { _ = DownloadManager.shared.startDownload(from: downloadURL) }
        } else {
            if url.pathExtension == "ipa" || url.pathExtension == "tipa" {
                if FileManager.default.isFileFromFileProvider(at: url) {
                    guard url.startAccessingSecurityScopedResource() else { return }
                    FR.handlePackageFile(url) { _ in }
                } else {
                    FR.handlePackageFile(url) { _ in }
                }
                return
            }
        }
    }
}

// MARK: - تصميم شاشة البداية (Splash Screen)
struct SplashScreenView: View {
    let appTintColor: String
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // أيقونة المتجر (مربّع بزوايا دائرية مع تدرج لوني)
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: appTintColor).opacity(0.8), Color(hex: appTintColor)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 110, height: 110)
                        .shadow(color: Color(hex: appTintColor).opacity(0.4), radius: 25, x: 0, y: 12)
                    
                    Image(systemName: "bag.fill")
                        .font(.system(size: 55, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // اسم المتجر
                Text("SY STORE")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(2) // مسافة جمالية بين الأحرف
            }
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
        }
    }
}

// MARK: - AppDelegate & Auto-Signing Logic
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        _createPipeline()
        _createDocumentsDirectories()
        ResetView.clearWorkCache()
        _addDefaultCertificates()
        return true
    }
    
    static func performDirectAutoSign(downloadId: String) {
        let context = Storage.shared.context
        let appRequest = Imported.fetchRequest()
        appRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Imported.date, ascending: false)]
        appRequest.fetchLimit = 1
        guard let latestApp = try? context.fetch(appRequest).first else {
            DispatchQueue.main.async { DownloadManager.shared.removeDownload(id: downloadId) }
            return
        }
        
        let certRequest = CertificatePair.fetchRequest()
        certRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)]
        guard let certs = try? context.fetch(certRequest), !certs.isEmpty else {
            DispatchQueue.main.async {
                DownloadManager.shared.removeDownload(id: downloadId)
                UIAlertController.showAlertWithOk(title: "تنبيه", message: "لا توجد شهادة لتوقيعه تلقائياً.")
            }
            return
        }
        
        let selectedIndex = UserDefaults.standard.integer(forKey: "feather.selectedCert")
        let cert = certs.indices.contains(selectedIndex) ? certs[selectedIndex] : certs.first!
        let options = OptionsManager.shared.options
        
        FR.signPackageFile(latestApp, using: options, icon: nil, certificate: cert) { error in
            DispatchQueue.main.async {
                DownloadManager.shared.removeDownload(id: downloadId)
                if let error = error {
                    UIAlertController.showAlertWithOk(title: "فشل التوقيع", message: error.localizedDescription)
                } else {
                    if options.post_deleteAppAfterSigned { Storage.shared.deleteApp(for: latestApp) }
                    NotificationCenter.default.post(name: Notification.Name("SYStore.installApp"), object: nil)
                    // إضافة تنبيه بنجاح التوقيع
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            }
        }
    }
    
    private func _createPipeline() {
        DataLoader.sharedUrlCache.diskCapacity = 0
        let pipeline = ImagePipeline {
            let dataLoader: DataLoader = { let config = URLSessionConfiguration.default; config.urlCache = nil; return DataLoader(configuration: config) }()
            let dataCache = try? DataCache(name: "com.systore.datacache"); let imageCache = Nuke.ImageCache()
            dataCache?.sizeLimit = 500 * 1024 * 1024; imageCache.costLimit = 100 * 1024 * 1024
            $0.dataCache = dataCache; $0.imageCache = imageCache; $0.dataLoader = dataLoader; $0.dataCachePolicy = .automatic; $0.isStoringPreviewsInMemoryCache = false
        }
        ImagePipeline.shared = pipeline
    }
    
    private func _createDocumentsDirectories() {
        let fileManager = FileManager.default
        let directories: [URL] = [fileManager.archives, fileManager.certificates, fileManager.signed, fileManager.unsigned]
        for url in directories { try? fileManager.createDirectoryIfNeeded(at: url) }
    }
    
    private func _addDefaultCertificates() {
        guard UserDefaults.standard.bool(forKey: "systore.didImportDefaultCertificates") == false, let signingAssetsURL = Bundle.main.url(forResource: "signing-assets", withExtension: nil) else { return }
        do {
            let folderContents = try FileManager.default.contentsOfDirectory(at: signingAssetsURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for folderURL in folderContents {
                guard folderURL.hasDirectoryPath else { continue }
                let certName = folderURL.lastPathComponent
                let p12Url = folderURL.appendingPathComponent("cert.p12"); let provisionUrl = folderURL.appendingPathComponent("cert.mobileprovision"); let passwordUrl = folderURL.appendingPathComponent("cert.txt")
                guard FileManager.default.fileExists(atPath: p12Url.path), FileManager.default.fileExists(atPath: provisionUrl.path), FileManager.default.fileExists(atPath: passwordUrl.path) else { continue }
                let password = try String(contentsOf: passwordUrl, encoding: .utf8)
                FR.handleCertificateFiles(p12URL: p12Url, provisionURL: provisionUrl, p12Password: password, certificateName: certName, isDefault: true) { _ in }
            }
            UserDefaults.standard.set(true, forKey: "systore.didImportDefaultCertificates")
        } catch { Logger.misc.error("Failed to list signing-assets: \(error)") }
    }
}

// MARK: - Extension for Hex Color
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted); var int: UInt64 = 0; Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue:  Double(b) / 255, opacity: Double(a) / 255)
    }
}
