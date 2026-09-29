//
//  DownloadButtonView.swift
//  SY STORE
//
//  Created by samsam on 7/25/25.
//  Modified for SY STORE.
//

import SwiftUI
import Combine
import AltSourceKit
import NimbleViews

struct DownloadButtonView: View {
	let app: ASRepository.App
	@ObservedObject private var downloadManager = DownloadManager.shared

	@State private var downloadProgress: Double = 0
	@State private var cancellable: AnyCancellable?

	var body: some View {
		ZStack {
			if let currentDownload = downloadManager.getDownload(by: app.currentUniqueId) {
				ZStack {
					Circle()
						.trim(from: 0, to: downloadProgress)
						.stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2.3, lineCap: .round))
						.rotationEffect(.degrees(-90))
						.frame(width: 31, height: 31)
                        .safeSmoothAnimation(value: downloadProgress)

					Image(systemName: downloadProgress >= 0.75 ? "archivebox" : "square.fill")
						.foregroundStyle(.tint)
						.font(.footnote.weight(.bold))
				}
				.onTapGesture {
					if downloadProgress <= 0.75 {
						downloadManager.cancelDownload(currentDownload)
					}
				}
				.compatTransition()
			} else {
				Button {
					if let url = app.currentDownloadUrl {
                        // 🔥 هنا أضفنا (autoSign: true) ليفهم النظام أننا نريد التوقيع التلقائي!
						_ = downloadManager.startDownload(from: url, id: app.currentUniqueId, autoSign: true)
					}
				} label: {
					Text("تنزيل") 
						.lineLimit(0)
						.font(.headline.weight(.bold))
						.foregroundStyle(Color.accentColor) 
						.padding(.horizontal, 22) 
						.padding(.vertical, 6)
						.background(Color(uiColor: .tertiarySystemFill)) 
						.clipShape(Capsule())
				}
				.buttonStyle(.borderless)
				.compatTransition()
			}
		}
		.onAppear(perform: setupObserver)
		.onDisappear { cancellable?.cancel() }
		.onChange(of: downloadManager.downloads.description) { _ in
			setupObserver()
		}
		.animation(.easeInOut(duration: 0.3), value: downloadManager.getDownload(by: app.currentUniqueId) != nil)
	}

	private func setupObserver() {
		cancellable?.cancel()
		guard let download = downloadManager.getDownload(by: app.currentUniqueId) else {
			downloadProgress = 0
			return
		}
		downloadProgress = download.overallProgress

		let publisher = Publishers.CombineLatest(
			download.$progress,
			download.$unpackageProgress
		)

		cancellable = publisher.sink { _, _ in
			downloadProgress = download.overallProgress
		}
	}
}

// MARK: - Compatibility Extensions
private extension View {
    @ViewBuilder
    func safeSmoothAnimation<V: Equatable>(value: V) -> some View {
        if #available(iOS 17.0, *) {
            self.animation(.smooth, value: value)
        } else {
            self.animation(.easeInOut, value: value)
        }
    }
}
