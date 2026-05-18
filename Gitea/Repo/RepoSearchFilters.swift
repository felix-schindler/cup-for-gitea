import SwiftUI

struct RepoSearchFilters: Equatable {
	var sort: SortOption = .bestMatch
	var order: OrderOption = .desc
	var mode: ModeFilter = .all
	var isPrivate: PrivateFilter = .all
	var archived: Bool?
	var template: Bool?
	var topic: Bool = false
	var includeDesc: Bool = false
	var limitText: String = ""

	enum SortOption: String, CaseIterable {
		case bestMatch = ""
		case alpha, created, updated, size, stars, forks

		var displayName: LocalizedStringResource {
			switch self {
			case .bestMatch: "Best Match"
			case .alpha: "Alpha"
			case .created: "Created"
			case .updated: "Updated"
			case .size: "Size"
			case .stars: "Stars"
			case .forks: "Forks"
			}
		}
	}

	enum OrderOption: String, CaseIterable {
		case asc, desc

		var displayName: LocalizedStringResource {
			switch self {
			case .asc: "Asc"
			case .desc: "Desc"
			}
		}
	}

	enum ModeFilter: String, CaseIterable {
		case all = ""
		case fork, source, mirror, collaborative

		var displayName: LocalizedStringResource {
			switch self {
			case .all: "All"
			case .fork: "Fork"
			case .source: "Source"
			case .mirror: "Mirror"
			case .collaborative: "Collaborative"
			}
		}
	}

	enum PrivateFilter: String, CaseIterable {
		case all, `public`, `private`

		var displayName: LocalizedStringResource {
			switch self {
			case .all: "All"
			case .public: "Public"
			case .private: "Private"
			}
		}
	}

	var taskKey: String {
		[
			sort.rawValue,
			order.rawValue,
			mode.rawValue,
			isPrivate.rawValue,
			archived?.description ?? "",
			template?.description ?? "",
			topic.description,
			includeDesc.description,
			limitText,
		].joined(separator: "|")
	}

	var sortValue: String? { sort == .bestMatch ? nil : sort.rawValue }
	var modeValue: String? { mode == .all ? nil : mode.rawValue }
	var limitValue: Int? {
		let trimmed = limitText.trimmingCharacters(in: .whitespacesAndNewlines)
		guard let intValue = Int(trimmed), intValue >= 1 else { return nil }
		return intValue
	}
}
