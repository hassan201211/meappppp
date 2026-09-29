//
//  LibraryView.swift
//  SY STORE
//
//  Created by samara on 10.04.2025.
//  Modified for SY STORE.
//

import SwiftUI
import CoreData
import NimbleViews

// MARK: - View
struct LibraryView: View {
	@StateObject var downloadManager = DownloadManager.shared
	
	@State private var _selectedInfoAppPresenting: AnyApp?
	@State private var _selectedSigningAppPresenting: AnyApp?
	@State private var _selectedInstallAppPresenting: AnyApp?
	@State private var _isImportingPresenting = false
	@State private var _isDownloadingPresenting = false
	@State private var _alertDownloadString: String = ""
	
	// MARK: Selection State
	@State private var _selectedAppUUIDs: Set<String> = []
	@State private var _editMode: EditMode = .inactive
	
	@State private var _searchText = ""
	@State private var _selectedScope: Scope = .imported // "لم يتم التوقيع" هي الافتراضية
	
	@Namespace private var _namespace
	
	private func filteredAndSortedApps<T>(from apps: FetchedResults<T>) -> [T] where T: NSManagedObject {
		apps.filter {
			_searchText.isEmpty ||
				(($0.value(forKey: "name") as? String)?.localizedCaseInsensitiveContains(_searchText) ?? false)
		}
	}
	
	private var _filteredSignedApps: [Signed] {
		filteredAndSortedApps(from: _signedApps)
	}
	
	private var _filteredImportedApps: [Imported] {
		filteredAndSortedApps(from: _importedApps)
	}
	
	// MARK: Fetch
	@FetchRequest(
		entity: Signed.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \Signed.date, ascending: false)],
		animation: .snappy
	) private var _signedApps: FetchedResults<Signed>
	
	@FetchRequest(
		entity: Imported.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \Imported.date, ascending: false)],
		animation: .snappy
	) private var _importedApps: FetchedResults<Imported>
	
	// MARK: Body
	var body: some View {
		NBNavigationView("التوقيع") {
            VStack(spacing: 0) {
                Picker("التصنيف", selection: $_selectedScope) {
                    ForEach(Scope.allCases, id: \.self) { scope in
                        Text(scope.displayName).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 5)

                NBListAdaptable {
                    if !_filteredImportedApps.isEmpty, _selectedScope == .imported {
                        Section {
                            ForEach(_filteredImportedApps, id: \.uuid) { app in
                                LibraryCellView(
                                    app: app,
                                    selectedInfoAppPresenting: $_selectedInfoAppPresenting,
                                    selectedSigningAppPresenting: $_selectedSigningAppPresenting,
                                    selectedInstallAppPresenting: $_selectedInstallAppPresenting,
                                    selectedAppUUIDs: $_selectedAppUUIDs
                                )
                                .compatMatchedTransitionSource(id: app.uuid ?? "", ns: _namespace)
                            }
                        }
                    }
                    
                    if !_filteredSignedApps.isEmpty, _selectedScope == .signed {
                        Section {
                            ForEach(_filteredSignedApps, id: \.uuid) { app in
                                LibraryCellView(
                                    app: app,
                                    selectedInfoAppPresenting: $_selectedInfoAppPresenting,
                                    selectedSigningAppPresenting: $_selectedSigningAppPresenting,
                                    selectedInstallAppPresenting: $_selectedInstallAppPresenting,
                                    selectedAppUUIDs: $_selectedAppUUIDs
                                )
                                .compatMatchedTransitionSource(id: app.uuid ?? "", ns: _namespace)
                            }
                        }
                    }
                }
            }
			.searchable(text: $_searchText, placement: .platform(), prompt: "ابحث في التطبيقات...")
			.safeScrollDismissesKeyboard() // توافق iOS 15
			.overlay {
				if
					(_selectedScope == .signed && _filteredSignedApps.isEmpty) ||
					(_selectedScope == .imported && _filteredImportedApps.isEmpty)
				{
					if #available(iOS 17, *) {
						ContentUnavailableView {
							Label("لا توجد تطبيقات", systemImage: "signature")
						} description: {
							Text("ابدأ باستيراد ملف IPA لتتمكن من توقيعه وتثبيته.")
						} actions: {
                            HStack(spacing: 16) {
                                Button {
                                    _isImportingPresenting = true
                                } label: {
                                    NBButton("استيراد من الملفات", style: .text)
                                }
                            }
						}
					}
				}
			}
			.toolbar {
				ToolbarItem(placement: .navigationBarLeading) { // تعديل لـ iOS 15
                    if _editMode.isEditing {
                        Button("تم", role: .cancel) {
                            _editMode = .inactive
                        }
                    } else {
                        EditButton()
                    }
				}
				
                ToolbarItemGroup(placement: .navigationBarTrailing) { // تعديل لـ iOS 15
                    if _editMode.isEditing {
                        Button {
                            _bulkDeleteSelectedApps()
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(_selectedAppUUIDs.isEmpty ? .gray : .red)
                        }
                        .disabled(_selectedAppUUIDs.isEmpty)
                    } else {
                        Button {
                            _isImportingPresenting = true
                        } label: {
                            Image(systemName: "folder.badge.plus")
                                .font(.body.bold())
                                .foregroundColor(.primary)
                        }
                        
                        Button {
                            _isDownloadingPresenting = true
                        } label: {
                            Image(systemName: "link")
                                .font(.body.bold())
                                .foregroundColor(.primary)
                        }
                    }
                }
			}
			.environment(\.editMode, $_editMode)
			.sheet(item: $_selectedInfoAppPresenting) { app in
				LibraryInfoView(app: app.base)
			}
			.sheet(item: $_selectedInstallAppPresenting) { app in
				InstallPreviewView(app: app.base, isSharing: app.archive)
					.safePresentationDetents(height: 200) // توافق iOS 15
					.safePresentationDragIndicator()     // توافق iOS 15
			}
			.fullScreenCover(item: $_selectedSigningAppPresenting) { app in
				SigningView(app: app.base)
					.compatNavigationTransition(id: app.base.uuid ?? "", ns: _namespace)
			}
			.sheet(isPresented: $_isImportingPresenting) {
				FileImporterRepresentableView(
					allowedContentTypes:  [.ipa, .tipa],
					allowsMultipleSelection: true,
					onDocumentsPicked: { urls in
						guard !urls.isEmpty else { return }
						
						for url in urls {
							let id = "SYStoreManualDownload_\(UUID().uuidString)"
							let dl = downloadManager.startArchive(from: url, id: id)
							try? downloadManager.handlePachageFile(url: url, dl: dl)
						}
					}
				)
				.ignoresSafeArea()
			}
			.alert("استيراد من رابط", isPresented: $_isDownloadingPresenting) {
				TextField("الرابط (URL)", text: $_alertDownloadString)
					.textInputAutocapitalization(.never)
				Button("إلغاء", role: .cancel) {
					_alertDownloadString = ""
				}
				Button("استيراد") {
					if let url = URL(string: _alertDownloadString) {
						_ = downloadManager.startDownload(from: url, id: "SYStoreManualDownload_\(UUID().uuidString)")
					}
				}
			}
			.onReceive(NotificationCenter.default.publisher(for: Notification.Name("SYStore.installApp"))) { _ in
				if let latest = _signedApps.first {
					_selectedInstallAppPresenting = AnyApp(base: latest)
				}
			}
			.onChange(of: _editMode) { mode in
				if mode == .inactive {
					_selectedAppUUIDs.removeAll()
				}
			}
		}
	}
}

// MARK: - Extension: Bulk Delete
extension LibraryView {
	private func _bulkDeleteSelectedApps() {
		let selectedApps = _getAllApps().filter { app in
			guard let uuid = app.uuid else { return false }
			return _selectedAppUUIDs.contains(uuid)
		}
		
		for app in selectedApps {
			Storage.shared.deleteApp(for: app)
		}
		
		_selectedAppUUIDs.removeAll()
        _editMode = .inactive
	}
	
	private func _getAllApps() -> [AppInfoPresentable] {
		var allApps: [AppInfoPresentable] = []
		
		if _selectedScope == .signed {
			allApps.append(contentsOf: _filteredSignedApps)
		}
		
		if _selectedScope == .imported {
			allApps.append(contentsOf: _filteredImportedApps)
		}
		
		return allApps
	}
}

// MARK: - Extension: View (Sort)
extension LibraryView {
	enum Scope: CaseIterable {
		case imported
		case signed
		
		var displayName: String {
			switch self {
			case .imported: return "لم يتم التوقيع"
			case .signed: return "موقّعة"
			}
		}
	}
}

// MARK: - Compatibility Extensions
private extension View {
    @ViewBuilder
    func safePresentationDetents(height: CGFloat) -> some View {
        if #available(iOS 16.0, *) {
            self.presentationDetents([.height(height)])
        } else {
            self
        }
    }
    
    @ViewBuilder
    func safePresentationDragIndicator() -> some View {
        if #available(iOS 16.0, *) {
            self.presentationDragIndicator(.visible)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func safeScrollDismissesKeyboard() -> some View {
        if #available(iOS 16.0, *) {
            self.scrollDismissesKeyboard(.interactively)
        } else {
            self
        }
    }
}
