//
//  SigningOptionsDictView.swift
//  Feather
//
//  Created by samara on 15.04.2025.
//

import SwiftUI
import NimbleViews

// MARK: - View
struct ConfigurationDictView: View {
	@State private var _isAddingPresenting = false
	
	var title: String
	@Binding var dataDict: [String: String]
	
	// MARK: Body
	var body: some View {
		NBList(title, type: .list) {
			ForEach(dataDict.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
				Section(key) {
					Text(value).swipeActions(edge: .trailing) {
						_actions(key: key)
					}
				}
			}
		}
		.toolbar {
			NBToolbarButton(
				systemImage: "plus",
				style: .icon,
				placement: .topBarTrailing
			) {
				_isAddingPresenting = true
			}
		}
        // تم استبدال navigationDestination بـ background NavigationLink للتوافق مع iOS 15
        .background(
            NavigationLink(
                destination: ConfigurationDictAddView(dataDict: $dataDict),
                isActive: $_isAddingPresenting,
                label: { EmptyView() }
            )
        )
	}
}

// MARK: - Extension: View
extension ConfigurationDictView {
	@ViewBuilder
	private func _actions(key: String) -> some View {
		Button(role: .destructive) {
			dataDict.removeValue(forKey: key)
		} label: {
			Label(.localized("Delete"), systemImage: "trash")
		}
	}
}
