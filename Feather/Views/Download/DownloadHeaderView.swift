//
//  DownloadHeaderView.swift
//  Feather
//
//  Created by samara on 16.05.2025.
//

import SwiftUI
import Combine
import NimbleExtensions

struct DownloadHeaderView: View {
	@ObservedObject var downloadManager: DownloadManager
	
	var body: some View {
		ZStack {
			if !downloadManager.manualDownloads.isEmpty {
				VStack {
					VStack(spacing: 12) {
						if let firstDownload = downloadManager.manualDownloads.first {
							DownloadItemView(download: firstDownload)
							
							if downloadManager.manualDownloads.count > 1 {
								HStack {
									Spacer()
									Text(verbatim: "+\(downloadManager.manualDownloads.count - 1)")
										.font(.caption)
										.foregroundColor(.secondary)
										.padding(.vertical, 4)
								}
							}
						}
					}
					.padding(.horizontal)
				}
				.transition(.move(edge: .top).combined(with: .opacity))
			}
		}
		.animation(.spring(), value: downloadManager.manualDownloads.count)
	}
}

struct DownloadItemView: View {
	let download: Download
	@State private var progress: Double = 0
	@State private var bytesDownloaded: Int64 = 0
	@State private var totalBytes: Int64 = 0
	@State private var unpackageProgress: Double = 0
	
	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(download.fileName)
				.font(.subheadline)
				.lineLimit(1)
			
			ProgressView(value: overallProgress)
				.progressViewStyle(.linear)
			
			HStack {
				Text(verbatim: "\(Int(overallProgress * 100))%")
					.compatibleNumericTextTransition() // تم التعديل لدعم iOS 15
				Spacer()
				if totalBytes > 0 {
					Text(verbatim: "\($bytesDownloaded.wrappedValue.formattedByteCount) / \(totalBytes.formattedByteCount)")
						.compatibleNumericTextTransition() // تم التعديل لدعم iOS 15
				}
			}
			.font(.caption)
			.foregroundColor(.secondary)
		}
		.padding(.vertical, 4)
		.onReceive(download.$progress) { self.progress = $0 }
		.onReceive(download.$bytesDownloaded) { self.bytesDownloaded = $0 }
		.onReceive(download.$totalBytes) { self.totalBytes = $0 }
		.onReceive(download.$unpackageProgress) { self.unpackageProgress = $0 }
	}
	
	private var overallProgress: Double {
		download.onlyArchiving
			? unpackageProgress
			: (0.3 * unpackageProgress) + (0.7 * progress)
	}
}

// MARK: - Compatibility Extension
private extension View {
    /// مُعدل مخصص يحافظ على التأثير الحركي للأرقام في iOS 16+ ويتجاهله في iOS 15 لضمان التوافق
    @ViewBuilder
    func compatibleNumericTextTransition() -> some View {
        if #available(iOS 16.0, *) {
            self.contentTransition(.numericText())
        } else {
            self
        }
    }
}
