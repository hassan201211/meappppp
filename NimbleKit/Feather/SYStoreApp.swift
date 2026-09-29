//
//  SYStoreApp.swift
//  SY STORE
//

import SwiftUI
import Nuke
import IDeviceSwift
import OSLog
import CoreData
// 💡 تم حذف مكتبات فايربيس ونظام الأكواد بالكامل! التطبيق الآن متاح للجميع باللونين الكحلي والبرتقالي مماثلاً لألوان الصورة.

@main
struct SYStoreApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let heartbeat = HeartbeatManager.shared
    @StateObject var downloadManager = DownloadManager.shared
    let storage = Storage.shared
    
    // 💡 جلب اللون المخزن وتحديث التطبيق تلقائياً عند تغييره من "المظهر"
    @AppStorage("Feather.userTintColor") private var appTintColor: String = "#FF6600"
    
    // تم إزالة مدير المصادقة (AttackAuthManager).
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // تم إزالة جميع شرطيات المصادقة. التطبيق يفتح مباشرة على الواجهة الرئيسية.
                VStack {
                    DownloadHeaderView(downloadManager: downloadManager)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    VariedTabbarView()
                        .environment(\.managedObjectContext, storage.context)
                        .onOpenURL(perform: _handleURL)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                .animation(.smooth, value: downloadManager.manualDownloads.description)
                .onReceive(NotificationCenter.default.publisher(for: .heartbeatInvalidHost)) { _ in
                    DispatchQueue.main.async { UIAlertController.showAlertWithOk(title: "خطأ", message: "ملف الربط غير متوافق.") }
                }
                .onAppear {
                    // تعيين نمط واجهة المستخدم.
                    if let style = UIUserInterfaceStyle(rawValue: UserDefaults.standard.integer(forKey: "Feather.userInterfaceStyle")) { UIApplication.topViewController()?.view.window?.overrideUserInterfaceStyle = style }
                    
                    // تعيين لون صبغة التطبيق الأولية لعناصر UIKit
                    UIApplication.topViewController()?.view.window?.tintColor = UIColor(Color(hex: appTintColor))
                }
                // 💡 تحديث عناصر UIKit (مثل التنبيهات وغيرها) فور تغيير اللون من الإعدادات
                .onChange(of: appTintColor) { newColor in
                    UIApplication.topViewController()?.view.window?.tintColor = UIColor(Color(hex: newColor))
                }
            }
            .background(Color(hex: "#0C1F3F")) // استخدام الكحلي الداكن من الصورة كخلفية افتراضية.
            .ignoresSafeArea()
            .environment(\.colorScheme, .dark) // إجبار التطبيق على استخدام المظهر الداكن ليتوافق مع الألوان.
            .tint(Color(hex: appTintColor)) // 💡 تطبيق اللون على جميع أزرار وعناصر SwiftUI ديناميكياً
        }
    }
    
    private func _handleURL(_ url: URL) {
        if url.scheme == "systore" {
            if url.host == "import-certificate" {
                guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let queryItems = components.queryItems else { return }
                func queryValue(_ name: String) -> String? { queryItems.first(where: { $0.name == name })?.value?.removingPercentEncoding }
                guard let p12Base64 = queryValue("p12"), let provisionBase64 = queryValue("mobileprovision"), let passwordBase64 = queryValue("password"), let passwordData = Data(base64Encoded: passwordBase64), let password = String(data: passwordData, encoding: .utf8) else { return }
                let generator = UINotificationFeedbackGenerator(); generator.prepare()
                guard let p12URL = FileManager.default.decodeAndWrite(base64: p12Base64, pathComponent: ".p12"), let provisionURL = FileManager.default.decodeAndWrite(base64: provisionBase64, pathComponent: ".mobileprovision"), FR.checkPasswordForCertificate(for: p12URL, with: password, using: provisionURL) else { generator.notificationOccurred(.error); return }
                FR.handleCertificateFiles(p12URL: p12URL, provisionURL: provisionURL, p12Password: password) { error in
                    if let error = error { UIAlertController.showAlertWithOk(title: "خطأ", message: error.localizedDescription) } else { generator.notificationOccurred(.success) }
                }
                return
            }
            if let fullPath = url.validatedScheme(after: "/source/") { FR.handleSource(fullPath) { } }
            if let fullPath = url.validatedScheme(after: "/install/"), let downloadURL = URL(string: fullPath) { _ = DownloadManager.shared.startDownload(from: downloadURL) }
        } else {
            if url.pathExtension == "ipa" || url.pathExtension == "tipa" {
                if FileManager.default.isFileFromFileProvider(at: url) { guard url.startAccessingSecurityScopedResource() else { return }; FR.handlePackageFile(url) { _ in } } else { FR.handlePackageFile(url) { _ in } }
                return
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        _createPipeline(); _createDocumentsDirectories(); ResetView.clearWorkCache(); _addDefaultCertificates(); return true
    }
    
    static func performDirectAutoSign(downloadId: String) {
        let context = Storage.shared.context
        let appRequest = Imported.fetchRequest()
        appRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Imported.date, ascending: false)]
        appRequest.fetchLimit = 1
        guard let latestApp = try? context.fetch(appRequest).first else { DispatchQueue.main.async { DownloadManager.shared.removeDownload(id: downloadId) }; return }
        let certRequest = CertificatePair.fetchRequest()
        certRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)]
        guard let certs = try? context.fetch(certRequest), !certs.isEmpty else { DispatchQueue.main.async { DownloadManager.shared.removeDownload(id: downloadId); UIAlertController.showAlertWithOk(title: "تنبيه", message: "لا توجد شهادة لتوقيعه تلقائياً.") }; return }
        let selectedIndex = UserDefaults.standard.integer(forKey: "feather.selectedCert")
        let cert = certs.indices.contains(selectedIndex) ? certs[selectedIndex] : certs.first!
        let options = OptionsManager.shared.options
        FR.signPackageFile(latestApp, using: options, icon: nil, certificate: cert) { error in
            DispatchQueue.main.async {
                DownloadManager.shared.removeDownload(id: downloadId)
                if let error = error { UIAlertController.showAlertWithOk(title: "فشل التوقيع", message: error.localizedDescription) } else {
                    if options.post_deleteAppAfterSigned { Storage.shared.deleteApp(for: latestApp) }
                    NotificationCenter.default.post(name: Notification.Name("SYStore.installApp"), object: nil)
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
