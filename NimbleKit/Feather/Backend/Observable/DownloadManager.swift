//
//  enum.swift
//  Feather
//
//  Modified for CY STORE - Direct AutoSign & Visual Feedback ⚡️
//

import Foundation
import Combine
import UIKit.UIImpactFeedbackGenerator
import BackgroundTasks

class Download: Identifiable, @unchecked Sendable {
	@Published var progress: Double = 0.0
	@Published var bytesDownloaded: Int64 = 0
	@Published var totalBytes: Int64 = 0
	@Published var unpackageProgress: Double = 0.0
    @Published var isSigning: Bool = false // 🔥 حالة جديدة لإظهار شريط التوقيع للمشترك
	
	var overallProgress: Double {
        if isSigning { return 1.0 } // إذا كان يوقع، نملأ الشريط
		return onlyArchiving ? unpackageProgress : (0.3 * unpackageProgress) + (0.7 * progress)
	}
	
	var task: URLSessionDownloadTask?
	var resumeData: Data?
	
	let id: String
	let url: URL
	let fileName: String
	let onlyArchiving: Bool
    let autoSign: Bool
	
	init(
		id: String,
		url: URL,
		onlyArchiving: Bool = false,
        autoSign: Bool = false
	) {
		self.id = id
		self.url = url
		self.onlyArchiving = onlyArchiving
        self.autoSign = autoSign
		self.fileName = url.lastPathComponent
	}
}

class DownloadManager: NSObject, ObservableObject {
	static let shared = DownloadManager()
	
	@Published var downloads: [Download] = []
	
	var manualDownloads: [Download] {
		downloads.filter { isManualDownload($0.id) }
	}
	
	private var _session: URLSession!
	
	#if !targetEnvironment(macCatalyst)
	private func _updateBackgroundAudioState() {
		if #unavailable(iOS 26.0){
			if !downloads.isEmpty {
				BackgroundAudioManager.shared.start()
			} else  {
				BackgroundAudioManager.shared.stop()
			}
		}
	}
	#endif
	
	override init() {
		super.init()
		let configuration = URLSessionConfiguration.default
		_session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
	}
	
	func startDownload(
		from url: URL,
		id: String = UUID().uuidString,
        autoSign: Bool = false
	) -> Download {
		if let existingDownload = downloads.first(where: { $0.url == url }) {
			resumeDownload(existingDownload)
			return existingDownload
		}
		
		let download = Download(id: id, url: url, autoSign: autoSign)
		
		let task = _session.downloadTask(with: url)
		download.task = task
		task.resume()
		
		downloads.append(download)
		
		#if !targetEnvironment(macCatalyst)
		if #available(iOS 26.0, *) {
			BackgroundTaskManager.shared.startTask(for: id, filename: url.lastPathComponent)
		} else {
			_updateBackgroundAudioState()
		}
		#endif
		
		return download
	}
	
	func startArchive(
		from url: URL,
		id: String = UUID().uuidString
	) -> Download {
		let download = Download(id: id, url: url, onlyArchiving: true)
		downloads.append(download)
		
		#if !targetEnvironment(macCatalyst)
		_updateBackgroundAudioState()
		#endif
		
		return download
	}
	
	func resumeDownload(_ download: Download) {
		if let resumeData = download.resumeData {
			let task = _session.downloadTask(withResumeData: resumeData)
			download.task = task
			task.resume()
			
			#if !targetEnvironment(macCatalyst)
			_updateBackgroundAudioState()
			#endif
		} else if let url = download.task?.originalRequest?.url {
			let task = _session.downloadTask(with: url)
			download.task = task
			task.resume()
			
			#if !targetEnvironment(macCatalyst)
			_updateBackgroundAudioState()
			#endif
		}
	}
	
	func cancelDownload(_ download: Download) {
		download.task?.cancel()
		
		if let index = downloads.firstIndex(where: { $0.id == download.id }) {
			downloads.remove(at: index)
			
			#if !targetEnvironment(macCatalyst)
			_updateBackgroundAudioState()

			if #available(iOS 26.0, *) {
				BackgroundTaskManager.shared.stopTask(for: download.id, success: false)
			}
			#endif
		}
	}
	
	func isManualDownload(_ string: String) -> Bool {
		return string.contains("FeatherManualDownload")
	}
	
	func getDownload(by id: String) -> Download? {
		return downloads.first(where: { $0.id == id })
	}
	
	func getDownloadIndex(by id: String) -> Int? {
		return downloads.firstIndex(where: { $0.id == id })
	}
	
	func getDownloadTask(by task: URLSessionDownloadTask) -> Download? {
		return downloads.first(where: { $0.task == task })
	}
    
    // 🔥 دالة الإزالة المنظمة
    func removeDownload(id: String) {
        if let index = getDownloadIndex(by: id) {
            downloads.remove(at: index)
            #if !targetEnvironment(macCatalyst)
            if #available(iOS 26.0, *) {
                BackgroundTaskManager.shared.updateProgress(for: id, progress: 1.0)
            }
            self._updateBackgroundAudioState()
            #endif
        }
    }
}

extension DownloadManager: URLSessionDownloadDelegate {
	
	func handlePachageFile(url: URL, dl: Download) throws {
		FR.handlePackageFile(url, download: dl) { err in
			if err != nil {
				let generator = UINotificationFeedbackGenerator()
				generator.notificationOccurred(.error)
                DispatchQueue.main.async { self.removeDownload(id: dl.id) }
			} else {
                // 🔥 الربط المباشر: إذا كان التوقيع التلقائي مفعلاً، لا نحذف الشريط بل نغير حالته!
                if dl.autoSign {
                    DispatchQueue.main.async {
                        dl.isSigning = true // تغيير شكل الشريط ليصبح "جاري التوقيع"
                        
                        // 🔥 تم حل المشكلة: استدعاء دالة التوقيع بشكل مباشر كـ Static Method!
                        AppDelegate.performDirectAutoSign(downloadId: dl.id)
                    }
                } else {
                    // إذا لم يكن هناك توقيع تلقائي، نزيل الشريط المكتمل كالمعتاد
                    DispatchQueue.main.async { self.removeDownload(id: dl.id) }
                }
            }
		}
	}
	
	func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
		guard let download = getDownloadTask(by: downloadTask) else { return }
		
		let tempDirectory = FileManager.default.temporaryDirectory
		let customTempDir = tempDirectory.appendingPathComponent("FeatherDownloads", isDirectory: true)
		
		do {
			try FileManager.default.createDirectoryIfNeeded(at: customTempDir)
			
			let suggestedFileName = downloadTask.response?.suggestedFilename ?? download.fileName
			let destinationURL = customTempDir.appendingPathComponent(suggestedFileName)
			
			try FileManager.default.removeFileIfNeeded(at: destinationURL)
			try FileManager.default.moveItem(at: location, to: destinationURL)
			
			try handlePachageFile(url: destinationURL, dl: download)
		} catch {
			print("Error handling downloaded file: \(error.localizedDescription)")
		}
	}
	
	func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
		guard let download = getDownloadTask(by: downloadTask) else { return }
		
		DispatchQueue.main.async {
			download.progress = totalBytesExpectedToWrite > 0
			? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
			: 0
			download.bytesDownloaded = totalBytesWritten
			download.totalBytes = totalBytesExpectedToWrite
			
			#if !targetEnvironment(macCatalyst)
			if #available(iOS 26.0, *) {
				BackgroundTaskManager.shared.updateProgress(for: download.id, progress: download.overallProgress)
			}
			#endif
		}
	}
	
	func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		guard let _ = error, let downloadTask = task as? URLSessionDownloadTask, let download = getDownloadTask(by: downloadTask) else { return }
		DispatchQueue.main.async { self.removeDownload(id: download.id) }
	}
}
