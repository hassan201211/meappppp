//
//  SourceAppsDetailView.swift
//  SY STORE
//
//  Created by samsam on 7/25/25.
//  Modified for SY STORE.
//

import SwiftUI
import Combine
import AltSourceKit
import NimbleViews
import NukeUI

// MARK: - SourceAppsDetailView
struct SourceAppsDetailView: View {
	@ObservedObject var downloadManager = DownloadManager.shared
	@State private var _downloadProgress: Double = 0
	@State var cancellable: AnyCancellable? // Combine
	@State private var _isScreenshotPreviewPresented: Bool = false
	@State private var _selectedScreenshotIndex: Int = 0
	
	var currentDownload: Download? {
		downloadManager.getDownload(by: app.currentUniqueId)
	}
	
	var source: ASRepository
	var app: ASRepository.App
	
	var body: some View {
		ScrollView {
			if #available(iOS 18, *) {
				_header().flexibleHeaderContent()
			}
			
			VStack(alignment: .leading, spacing: 10) {
				HStack(spacing: 15) { // زيادة المسافة قليلاً للتنسيق
					if let iconURL = app.iconURL {
						LazyImage(url: iconURL) { state in
							if let image = state.image {
								image.appIconStyle(size: 100, isCircle: false) // حجم متناسق 100
							} else {
								standardIcon
							}
						}
					} else {
						standardIcon
					}

					VStack(alignment: .leading, spacing: 4) {
						Text(app.currentName)
							.font(.title3.weight(.semibold)) // حجم متناسق ومتوافق مع iOS 15
							.foregroundColor(.primary)
						Text(app.currentDescription ?? "تطبيق مميز")
							.font(.subheadline)
							.foregroundColor(.secondary)
						
						Spacer()
						
						DownloadButtonView(app: app)
					}
					.lineLimit(2)
					.frame(maxWidth: .infinity, alignment: .leading)
				}
				
				Divider()
				_infoPills(app: app)
				Divider()
                
				if let screenshotURLs = app.screenshotURLs {
					NBSection("الصور") {
						_screenshots(screenshotURLs: screenshotURLs)
					}
                    
					Divider()
				}
                
				NBSection("المعلومات") {
					VStack(spacing: 12) {
						if let size = app.size {
							_infoRow(title: "الحجم", value: size.formattedByteCount)
						}
						
						if let category = app.category {
							_infoRow(title: "التصنيف", value: category.capitalized)
						}
						
						if let version = app.currentVersion {
							_infoRow(title: "الإصدار", value: version)
						}
						
						if let date = app.currentDate?.date {
							_infoRow(title: "تاريخ التحديث", value: DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none))
						}
						
						if let bundleId = app.id {
							_infoRow(title: "المعرّف", value: bundleId)
						}
					}
				}
				
				if let appPermissions = app.appPermissions {
					NBSection("الصلاحيات") {
						Group {
							if let entitlements = appPermissions.entitlements {
								NBTitleWithSubtitleView(
									title: "التصريحات",
									subtitle: entitlements.map(\.name).joined(separator: "\n")
								)
							} else {
								Text("لا توجد تصريحات مسجلة.")
									.font(.subheadline)
									.foregroundStyle(.secondary)
							}
							if let privacyItems = appPermissions.privacy {
								ForEach(privacyItems, id: \.self) { item in
									NBTitleWithSubtitleView(
										title: item.name,
										subtitle: item.usageDescription
									)
								}
							} else {
								Text("لا توجد صلاحيات خصوصية مسجلة.")
									.font(.subheadline)
									.foregroundStyle(.secondary)
							}
						}
						.padding()
						.background(
							RoundedRectangle(cornerRadius: 18, style: .continuous)
								.fill(Color(.quaternarySystemFill))
						)
					}
				}
			}
			.padding([.horizontal, .bottom])
			.padding(.top, {
				if #available(iOS 18, *) { 8 } else { 0 }
			}())
		}
		.flexibleHeaderScrollView()
		.shouldSetInset()
		.toolbar {
			NBToolbarButton(
				systemImage: "square.and.arrow.up",
				placement: .topBarTrailing
			) {
				let sharedString = """
				\(app.currentName) - \(app.currentVersion ?? "0")
				\(app.currentDescription ?? "تطبيق مميز")
				---
				تمت المشاركة من SY STORE
				"""
				UIActivityViewController.show(activityItems: [sharedString])
			}
		}
		.fullScreenCover(isPresented: $_isScreenshotPreviewPresented) {
			if let screenshotURLs = app.screenshotURLs {
				ScreenshotPreviewView(
					screenshotURLs: screenshotURLs,
					initialIndex: _selectedScreenshotIndex
				)
			}
		}
	}
	
	var standardIcon: some View {
		Image("App_Unknown").appIconStyle(size: 100, isCircle: false)
	}
	
	var standardHeader: some View {
		Image("App_Unknown")
			.resizable()
			.aspectRatio(contentMode: .fill)
			.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
			.clipped()
	}
}

// MARK: - SourceAppsDetailView (Extension): Builders
extension SourceAppsDetailView {
	@available(iOS 18.0, *)
	@ViewBuilder
	private func _header() -> some View {
		ZStack {
			if let iconURL = source.currentIconURL {
				LazyImage(url: iconURL) { state in
					if let image = state.image {
						image.resizable()
							.aspectRatio(contentMode: .fill)
							.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
							.clipped()
					} else {
						standardHeader
					}
				}
			} else {
				standardHeader
			}
			
			NBVariableBlurView()
				.rotationEffect(.degrees(-180))
				.overlay(
					LinearGradient(
						gradient: Gradient(colors: [
							Color.black.opacity(0.8),
							Color.black.opacity(0)
						]),
						startPoint: .top,
						endPoint: .bottom
					)
				)
		}
	}
	
	@ViewBuilder
	private func _infoPills(app: ASRepository.App) -> some View {
		let pillItems = _buildPills(from: app)
		HStack(spacing: 6) {
			ForEach(pillItems.indices, id: \.hashValue) { index in
				let pill = pillItems[index]
				NBPillView(
					title: pill.title,
					icon: pill.icon,
					color: pill.color,
					index: index,
					count: pillItems.count
				)
			}
		}
	}
	
	private func _buildPills(from app: ASRepository.App) -> [NBPillItem] {
		var pills: [NBPillItem] = []
		
		if let version = app.currentVersion {
			pills.append(NBPillItem(title: version, icon: "tag", color: Color.accentColor))
		}
		
		if let size = app.size {
			pills.append(NBPillItem(title: size.formattedByteCount, icon: "archivebox", color: .secondary))
		}
		
		return pills
	}
	
	@ViewBuilder
	private func _infoRow(title: String, value: String) -> some View {
        // حل مشكلة LabeledContent لـ iOS 15
        if #available(iOS 16.0, *) {
            LabeledContent(title, value: value)
        } else {
            HStack {
                Text(title)
                Spacer()
                Text(value)
                    .foregroundColor(.secondary)
            }
        }
		Divider()
	}
	
	@ViewBuilder
	private func _screenshots(screenshotURLs: [URL]) -> some View {
		ScrollView(.horizontal, showsIndicators: false) {
			HStack(spacing: 12) {
				ForEach(screenshotURLs.indices, id: \.self) { index in
					let url = screenshotURLs[index]
					LazyImage(url: url) { state in
						if let image = state.image {
							image
								.resizable()
								.aspectRatio(contentMode: .fit)
								.frame(
									maxWidth: UIScreen.main.bounds.width - 32,
									maxHeight: 400
								)
								.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
								.overlay {
									RoundedRectangle(cornerRadius: 16, style: .continuous)
										.strokeBorder(.gray.opacity(0.3), lineWidth: 1)
								}
								.onTapGesture {
									_selectedScreenshotIndex = index
									_isScreenshotPreviewPresented = true
								}
						}
					}
				}
			}
			.padding(.horizontal)
			.compatScrollTargetLayout()
		}
		.compatScrollTargetBehavior()
		.padding(.horizontal, -16)
	}
}
