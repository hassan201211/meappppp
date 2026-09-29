//
//  LibraryCellView.swift
//  SY STORE
//
//  Created by samara on 11.04.2025.
//  Modified for SY STORE.
//

import SwiftUI
import NimbleExtensions
import NimbleViews

// MARK: - View
struct LibraryCellView: View {
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	@Environment(\.editMode) private var editMode

	var certInfo: Date.ExpirationInfo? {
		Storage.shared.getCertificate(from: app)?.expiration?.expirationInfo()
	}
	
	var certRevoked: Bool {
		Storage.shared.getCertificate(from: app)?.revoked == true
	}
	
	var app: AppInfoPresentable
	@Binding var selectedInfoAppPresenting: AnyApp?
	@Binding var selectedSigningAppPresenting: AnyApp?
	@Binding var selectedInstallAppPresenting: AnyApp?
	@Binding var selectedAppUUIDs: Set<String>
	
	// MARK: Selections
	private var _isSelected: Bool {
		guard let uuid = app.uuid else { return false }
		return selectedAppUUIDs.contains(uuid)
	}
	
	private func _toggleSelection() {
		guard let uuid = app.uuid else { return }
		if selectedAppUUIDs.contains(uuid) {
			selectedAppUUIDs.remove(uuid)
		} else {
			selectedAppUUIDs.insert(uuid)
		}
	}
	
	// MARK: Body
	var body: some View {
		let isRegular = horizontalSizeClass != .compact
		let isEditing = editMode?.wrappedValue == .active
		
		HStack(spacing: 14) {
			if isEditing {
				Button {
					_toggleSelection()
				} label: {
					Image(systemName: _isSelected ? "checkmark.circle.fill" : "circle")
						.foregroundColor(_isSelected ? .accentColor : .secondary)
						.font(.title2)
				}
				.buttonStyle(.borderless)
			}
			
            // 1. الأيقونة أولاً (لتظهر على اليمين في اللغة العربية)
            FRAppIconView(app: app, size: 57)
            
            // 2. اسم ومعلومات التطبيق
			NBTitleWithSubtitleView(
				title: app.name ?? "غير معروف",
				subtitle: _desc,
				linelimit: 0
			)
            
            Spacer() // دفع زر التوقيع لأقصى اليسار
            
            // 3. زر الأكشن (توقيع / تثبيت) يوضع في النهاية (ليظهر على اليسار)
            if !isEditing {
                _buttonActions(for: app)
            }
		}
		.padding(isRegular ? 12 : 0)
		.background(
			isRegular
				? RoundedRectangle(cornerRadius: 18, style: .continuous)
				.fill(_isSelected && isEditing ? Color.accentColor.opacity(0.1) : Color(.quaternarySystemFill))
				: nil
		)
		.contentShape(Rectangle())
		.onTapGesture {
			if isEditing {
				_toggleSelection()
			}
		}
		.swipeActions {
			if !isEditing {
				_actions(for: app)
			}
		}
		.contextMenu {
			if !isEditing {
				_contextActions(for: app)
				Divider()
				_contextActionsExtra(for: app)
				Divider()
				_actions(for: app)
			}
		}
	}
	
	private var _desc: String {
		if let version = app.version, let id = app.identifier {
			return "\(version) • \(id)"
		} else {
			return "معلومات غير معروفة"
		}
	}
}

// MARK: - Extension: View
extension LibraryCellView {
	@ViewBuilder
	private func _actions(for app: AppInfoPresentable) -> some View {
		Button("حذف", systemImage: "trash", role: .destructive) {
			Storage.shared.deleteApp(for: app)
		}
	}
	
	@ViewBuilder
	private func _contextActions(for app: AppInfoPresentable) -> some View {
		Button("معلومات التطبيق", systemImage: "info.circle") {
			selectedInfoAppPresenting = AnyApp(base: app)
		}
	}
	
	@ViewBuilder
	private func _contextActionsExtra(for app: AppInfoPresentable) -> some View {
		if app.isSigned {
			if let id = app.identifier {
				Button("فتح التطبيق", systemImage: "app.badge.checkmark") {
					UIApplication.openApp(with: id)
				}
			}
			Button("تثبيت", systemImage: "square.and.arrow.down") {
				selectedInstallAppPresenting = AnyApp(base: app)
			}
			Button("إعادة توقيع", systemImage: "signature") {
				selectedSigningAppPresenting = AnyApp(base: app)
			}
			Button("تصدير IPA", systemImage: "square.and.arrow.up") {
				selectedInstallAppPresenting = AnyApp(base: app, archive: true)
			}
		} else {
			Button("تثبيت", systemImage: "square.and.arrow.down") {
				selectedInstallAppPresenting = AnyApp(base: app)
			}
			Button("توقيع", systemImage: "signature") {
				selectedSigningAppPresenting = AnyApp(base: app)
			}
		}
	}
	
	@ViewBuilder
	private func _buttonActions(for app: AppInfoPresentable) -> some View {
		Group {
			if app.isSigned {
				Button {
					selectedInstallAppPresenting = AnyApp(base: app)
				} label: {
					FRExpirationPillView(
						title: "تثبيت",
						revoked: certRevoked,
						expiration: certInfo
					)
				}
			} else {
				Button {
					selectedSigningAppPresenting = AnyApp(base: app)
				} label: {
					FRExpirationPillView(
						title: "توقيع",
						revoked: false,
						expiration: nil
					)
				}
			}
		}
		.buttonStyle(.borderless)
	}
}
