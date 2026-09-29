//
//  SourcesAddView.swift
//  Feather
//
//  Created by samara on 1.05.2025.
//

import SwiftUI
import NimbleViews
import AltSourceKit
import NimbleJSON
import OSLog
import UIKit.UIImpactFeedbackGenerator

// MARK: - View
struct SourcesAddView: View {
	typealias RepositoryDataHandler = Result<ASRepository, Error>
	@Environment(\.dismiss) var dismiss

	private let _dataService = NBFetchService()
	
	@State private var _filteredRecommendedSourcesData: [(url: URL, data: ASRepository)] = []
	private func _refreshFilteredRecommendedSourcesData() {
		let filtered = recommendedSourcesData
			.filter { (url, data) in
				let id = data.id ?? url.absoluteString
				return !Storage.shared.sourceExists(id)
			}
			.sorted { lhs, rhs in
				let lhsName = lhs.data.name ?? ""
				let rhsName = rhs.data.name ?? ""
				return lhsName.localizedCaseInsensitiveCompare(rhsName) == .orderedAscending
			}
		_filteredRecommendedSourcesData = filtered
	}
	
	@State var recommendedSourcesData: [(url: URL, data: ASRepository)] = []
	let recommendedSources: [URL] = [
		"https://raw.githubusercontent.com/claration/Feather/refs/heads/main/app-repo.json",
		"https://raw.githubusercontent.com/Aidoku/Aidoku/altstore/apps.json",
		"https://github.com/chachillie/Flycast-iOS/raw/main/flycast-ios.json",
		"https://xitrix.github.io/iTorrent/AltStore.json",
		"https://altstore.oatmealdome.me/",
		"https://raw.githubusercontent.com/LiveContainer/LiveContainer/refs/heads/main/apps.json",
		"https://pokemmo.com/altstore",
		"https://provenance-emu.com/apps.json",
		"https://community-apps.sidestore.io/sidecommunity.json",
		"https://alt.getutm.app",
		"https://raw.githubusercontent.com/paigely/Navic/refs/heads/master/app-repo.json",
		"https://stikdebug.xyz/index.json",
		"https://apps.manicemu.site/altstore",
		"https://alt.crystall1ne.dev"
	].compactMap { URL(string: $0) }
	
	@State private var _isImporting = false
	@State private var _sourceURL = ""
	
	// MARK: Body
	var body: some View {
		NBNavigationView(.localized("Add Source"), displayMode: .inline) {
			Form {
				NBSection(.localized("Source URL")) {
					TextField(.localized("Enter Source URL"), text: $_sourceURL)
						.keyboardType(.URL)
						.textInputAutocapitalization(.never)
				} footer: {
					VStack(alignment: .leading, spacing: 4) {
						Text(.localized("The only supported repositories are AltStore repositories."))
						Text(verbatim: "[\(String.localized("Learn more about how to setup a repository..."))](https://faq.altstore.io/developers/make-a-source)")
					}
				}
				
				Section {
					Button {
						_isImporting = true
						_fetchImportedRepositories(UIPasteboard.general.string) {
							dismiss()
						}
					} label: {
						Label(.localized("Import"), systemImage: "square.and.arrow.down")
					}
					
					Button {
						let sources = Storage.shared.getSources()
						guard !sources.isEmpty else {
							UIAlertController.showAlertWithOk(
								title: .localized("Error"),
								message: .localized("No sources to export")
							)
							return
						}
						UIPasteboard.general.string = sources.map {
							$0.sourceURL!.absoluteString
						}.joined(separator: "\n")
						UIAlertController.showAlertWithOk(
							title: .localized("Success"),
							message: .localized("Sources copied to clipboard")
						) {
							dismiss()
						}
					} label: {
						Label(.localized("Export"), systemImage: "doc.on.doc")
					}
				} footer: {
					Text(.localized("Supports importing from KravaSign/MapleSign and ESign."))
				}
				
				if !_filteredRecommendedSourcesData.isEmpty {
					NBSection(.localized("Featured")) {
						ForEach(_filteredRecommendedSourcesData, id: \.url) { (url, source) in
							HStack {
								FRIconCellView(
									title: source.name ?? .localized("Unknown"),
									subtitle: url.host ?? url.absoluteString,
									iconUrl: source.currentIconURL
								)
								
								Spacer()
								
								Button {
									Storage.shared.addSource(url, repository: source) { _ in
										_refreshFilteredRecommendedSourcesData()
									}
								} label: {
									Text(.localized("Add"))
										.font(.subheadline.weight(.bold))
										.padding(.horizontal, 12)
										.padding(.vertical, 6)
										.background(Color.accentColor.opacity(0.1))
										.clipShape(Capsule())
								}
							}
							.padding(.vertical, 2)
						}
					} footer: {
						Text(.localized("Open an [issue](https://github.com/claration/Feather/issues) on GitHub if you want your source to be featured."))
					}
				}
			}
			.toolbar {
				ToolbarItem(placement: .navigationBarLeading) {
					Button {
						dismiss()
					} label: {
						Image(systemName: "xmark")
                            // 🔥 تم استبدال fontWeight هنا لتدعم iOS 15
							.font(.body.weight(.semibold))
					}
				}
				
				ToolbarItem(placement: .navigationBarTrailing) {
					HStack {
						if !_isImporting {
							Button {
								FR.handleSource(_sourceURL) {
									dismiss()
								}
							} label: {
								Text(.localized("Save"))
                                    // 🔥 تم استبدال fontWeight هنا لتدعم iOS 15
									.font(.body.weight(.semibold))
							}
							.disabled(_sourceURL.isEmpty)
						} else {
							ProgressView()
						}
					}
				}
			}
			.animation(.default, value: _filteredRecommendedSourcesData.map { $0.data.id ?? "" })
			.task {
				await _fetchRecommendedRepositories()
			}
		}
	}
	
	private func _fetchRecommendedRepositories() async {
		let fetched = await _concurrentFetchRepositories(from: recommendedSources)
		await MainActor.run {
			recommendedSourcesData = fetched
			_refreshFilteredRecommendedSourcesData()
		}
	}
	
	private func _fetchImportedRepositories(
		_ code: String?,
		competion: @escaping () -> Void
	) {
		guard let code else { return }
		
		let handler = ASDeobfuscator(with: code)
		let repoUrls = handler.decode().compactMap { URL(string: $0) }
		guard !repoUrls.isEmpty else { return }
		
		Task {
			let fetched = await _concurrentFetchRepositories(from: repoUrls)
			
			let dict = Dictionary(fetched, uniquingKeysWith: { first, _ in first })

			await MainActor.run {
				Storage.shared.addSources(repos: dict) { _ in
					competion()
				}
			}
		}
	}
	
	private func _concurrentFetchRepositories(
		from urls: [URL]
	) async -> [(url: URL, data: ASRepository)] {
		var results: [(url: URL, data: ASRepository)] = []
		
		let dataService = _dataService
		
		await withTaskGroup(of: Void.self) { group in
			for url in urls {
				group.addTask {
					await withCheckedContinuation { continuation in
						dataService.fetch<ASRepository>(from: url) { (result: RepositoryDataHandler) in
							switch result {
							case .success(let repo):
								Task { @MainActor in
									results.append((url: url, data: repo))
								}
							case .failure(let error):
								Logger.misc.error("Failed to fetch \(url): \(error.localizedDescription)")
							}
							continuation.resume()
						}
					}
				}
			}
			await group.waitForAll()
		}
		
		return results
	}
}
