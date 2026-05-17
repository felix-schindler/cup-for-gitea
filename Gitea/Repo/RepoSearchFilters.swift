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
    }

    enum OrderOption: String, CaseIterable {
        case asc, desc
    }

    enum ModeFilter: String, CaseIterable {
        case all = ""
        case fork, source, mirror, collaborative
    }

    enum PrivateFilter: String, CaseIterable {
        case all, `public`, `private`
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
            limitText
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
