//
//  SourceAppsCellView.swift
//  SY STORE
//
//  Created by samara on 3.05.2025.
//  Modified for SY STORE.
//

import SwiftUI
import AltSourceKit
import NimbleViews
import Combine
import NukeUI

struct SourceAppsCellView: View {
	@AppStorage("SYStore.storeCellAppearance") private var _storeCellAppearance: Int = 0
	
	var source: ASRepository
	var app: ASRepository.App
	
	var body: some View {
		VStack {
			HStack(spacing: 8) {
				FRIconCellView(
					title: app.currentName,
					subtitle: Self.appDescription(app: app),
					iconUrl: app.iconURL
				)
                // تم حذف كود الصورة الصغيرة (overlay) من هنا لتصبح الأيقونة نظيفة تماماً
                
                Spacer() // دفع زر التنزيل لليسار
                
				DownloadButtonView(app: app)
			}
			
			if
				_storeCellAppearance != 0,
				let desc = app.localizedDescription ?? app.currentDescription
			{
				Text(desc)
					.frame(maxWidth: .infinity, alignment: .leading)
					.font(.subheadline)
					.foregroundStyle(.secondary)
					.padding(.top, 2)
                    .multilineTextAlignment(.leading)
			}
		}
	}
	
	static func appDescription(app: ASRepository.App) -> String {
		let optionalComponents: [String?] = [
			app.currentVersion,
            app.subtitle ?? "تطبيق مميز"
		]
		
		let components: [String] = optionalComponents.compactMap { value in
			guard
				let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
				!trimmed.isEmpty
			else {
				return nil
			}
			
			return trimmed
		}
		
		return components.joined(separator: " • ")
	}
}
