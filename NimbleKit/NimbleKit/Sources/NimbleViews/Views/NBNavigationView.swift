//
//  NavigationViewWrapper.swift
//  Stars
//
//  Created by samara on 7.04.2025.
//

import SwiftUI

public struct NBNavigationView<Content>: View where Content: View {
	private var _title: String
	private var _mode: NavigationBarItem.TitleDisplayMode
	private var _content: Content
	
	public init(
		_ title: String,
		displayMode: NavigationBarItem.TitleDisplayMode = .automatic,
		@ViewBuilder content: () -> Content
	) {
		self._title = title
		self._mode = displayMode
		self._content = content()
	}
	
	public var body: some View {
		if #available(iOS 16.0, *) {
			NavigationStack {
				_content
					.navigationTitle(_title)
					.navigationBarTitleDisplayMode(_mode)
			}
		} else {
			NavigationView {
				_content
					.navigationTitle(_title)
					.navigationBarTitleDisplayMode(_mode)
			}
			// هذا السطر مهم جداً لكي لا تنقسم الشاشة في الآيباد على iOS 15
			.navigationViewStyle(.stack)
		}
	}
}
