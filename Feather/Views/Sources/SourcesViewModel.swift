//
//  SourcesViewModel.swift
//  Feather
//

import Foundation
import AltSourceKit
import SwiftUI
import NimbleJSON

// MARK: - Class
final class SourcesViewModel: ObservableObject {
	static let shared = SourcesViewModel()
	
	typealias RepositoryDataHandler = Result<ASRepository, Error>
	
	private let _dataService = NBFetchService()
	
	var isFinished = true
	@Published var sources: [AltSource: ASRepository] = [:]
	
	func fetchSources(_ sourcesList: FetchedResults<AltSource>, refresh: Bool = false, batchSize: Int = 4) async {
		guard isFinished else { return }
		
		if !refresh, sourcesList.allSatisfy({ self.sources[$0] != nil }) { return }
		
		isFinished = false
		defer { isFinished = true }
		
        // 🔥 الحل الذهبي للسرعة: قمنا بإزالة السطر الذي يمسح الشاشة (self.sources = [:])
        // الآن ستبقى التطبيقات موجودة على الشاشة أثناء تحديثها في الخلفية ولن يضطر المستخدم للانتظار!
		
		let sourcesArray = Array(sourcesList)
		
		for startIndex in stride(from: 0, to: sourcesArray.count, by: batchSize) {
			let endIndex = min(startIndex + batchSize, sourcesArray.count)
			let batch = sourcesArray[startIndex..<endIndex]
			
			let batchResults = await withTaskGroup(of: (AltSource, ASRepository?).self, returning: [AltSource: ASRepository].self) { group in
				for source in batch {
					group.addTask {
						guard let url = source.sourceURL else {
							return (source, nil)
						}
						
						return await withCheckedContinuation { continuation in
							self._dataService.fetch(from: url) { (result: RepositoryDataHandler) in
								switch result {
								case .success(let repo):
									continuation.resume(returning: (source, repo))
								case .failure(_):
									continuation.resume(returning: (source, nil))
								}
							}
						}
					}
				}
				
				var results = [AltSource: ASRepository]()
				for await (source, repo) in group {
					if let repo {
						results[source] = repo
					}
				}
				return results
			}
			
			await MainActor.run {
				for (source, repo) in batchResults {
					self.sources[source] = repo
				}
			}
		}
	}
}
