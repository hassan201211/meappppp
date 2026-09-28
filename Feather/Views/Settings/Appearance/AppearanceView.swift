//
//  AppearanceView.swift
//  SY STORE
//
//  Created by samara on 7.05.2025.
//  Modified for SY STORE.
//

import SwiftUI
import NimbleViews
import UIKit

// MARK: - View
struct AppearanceView: View {
	@AppStorage("Feather.userInterfaceStyle")
	private var _userIntefacerStyle: Int = UIUserInterfaceStyle.unspecified.rawValue
	
	@AppStorage("Feather.userTintColor")
	private var _selectedColorHex: String = "#16BFE0"
	
	private var _tintColorBinding: Binding<Color> {
		Binding(
			get: { Color(hex: _selectedColorHex) },
			set: { newValue in
				_selectedColorHex = newValue.toHex()
				
				// تطبيق اللون الجديد فوراً على كافة واجهات التطبيق
				let uiColor = UIColor(newValue)
				for scene in UIApplication.shared.connectedScenes {
					if let windowScene = scene as? UIWindowScene {
						for window in windowScene.windows {
							window.tintColor = uiColor
						}
					}
				}
			}
		)
	}
	
	// MARK: Body
	var body: some View {
		NBList("المظهر") {
            // القسم الأول: خيارات المظهر (افتراضي، فاتح، داكن)
			Section {
				Picker("المظهر", selection: $_userIntefacerStyle) {
					Text("افتراضي").tag(UIUserInterfaceStyle.unspecified.rawValue)
					Text("فاتح").tag(UIUserInterfaceStyle.light.rawValue)
					Text("داكن").tag(UIUserInterfaceStyle.dark.rawValue)
				}
				.pickerStyle(.segmented)
			}
			
            // القسم الثاني: لون التطبيق المخصص
			NBSection("المظهر") {
				ColorPicker(
					"لون المظهر",
					selection: _tintColorBinding,
					supportsOpacity: false
				)
			}
		}
		.onChange(of: _userIntefacerStyle) { value in
			// تطبيق الوضع الفاتح/الداكن فوراً على كافة النوافذ
			if let style = UIUserInterfaceStyle(rawValue: value) {
				for scene in UIApplication.shared.connectedScenes {
					if let windowScene = scene as? UIWindowScene {
						for window in windowScene.windows {
							window.overrideUserInterfaceStyle = style
						}
					}
				}
			}
		}
	}
}
