import CoreSpotlight

enum SpotlightDestination: Hashable {
	case repo(instanceURL: String, owner: String, repo: String)
	case issue(instanceURL: String, owner: String, repo: String, number: Int64)
	case pullRequest(instanceURL: String, owner: String, repo: String, number: Int64)

	var uniqueIdentifier: String {
		switch self {
		case .repo(let instance, let owner, let repo):
			"repo:\(instance):\(owner)/\(repo)"
		case .issue(let instance, let owner, let repo, let number):
			"issue:\(instance):\(owner)/\(repo)#\(number)"
		case .pullRequest(let instance, let owner, let repo, let number):
			"pullRequest:\(instance):\(owner)/\(repo)#\(number)"
		}
	}

	static func from(identifier: String) -> Self? {
		let parts = identifier.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
		guard parts.count == 2 else { return nil }
		let type = parts[0]
		let rest = String(parts[1])

		switch type {
		case "repo":
			let components = rest.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
			guard components.count == 2 else { return nil }
			let instanceURL = String(components[0])
			let path = components[1].split(separator: "/", maxSplits: 1).map(String.init)
			guard path.count == 2 else { return nil }
			return .repo(instanceURL: instanceURL, owner: path[0], repo: path[1])

		case "issue", "pullRequest":
			let components = rest.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
			guard components.count == 2 else { return nil }
			let instanceURL = String(components[0])
			let path = components[1].split(separator: "#", maxSplits: 1).map(String.init)
			guard path.count == 2,
				let number = Int64(path[1])
			else { return nil }
			let repoPath = path[0].split(separator: "/", maxSplits: 1).map(String.init)
			guard repoPath.count == 2 else { return nil }
			if type == "issue" {
				return .issue(instanceURL: instanceURL, owner: repoPath[0], repo: repoPath[1], number: number)
			} else {
				return .pullRequest(instanceURL: instanceURL, owner: repoPath[0], repo: repoPath[1], number: number)
			}

		default:
			return nil
		}
	}
}

enum SpotlightIndexer {
	private static let domainPrefix = "de.schindlerfelix.Gitea"

	static func index(repos: [Components.Schemas.Repository]) async throws {
		let items = repos.compactMap { repo -> CSSearchableItem? in
			guard let owner = repo.owner?.login else { return nil }
			let dest = SpotlightDestination.repo(
				instanceURL: Network.baseURL.absoluteString,
				owner: owner,
				repo: repo.name
			)
			let attrs = CSSearchableItemAttributeSet(contentType: .content)
			attrs.title = repo.fullName
			attrs.contentDescription = repo.description
			attrs.keywords = [owner, repo.name] + (repo.topics ?? [])
			return CSSearchableItem(
				uniqueIdentifier: dest.uniqueIdentifier,
				domainIdentifier: "\(domainPrefix).repo",
				attributeSet: attrs
			)
		}
		guard items.isNotEmpty else { return }
		try await CSSearchableIndex.default().indexItems(items)
	}

	static func index(issues: [Components.Schemas.Issue]) async throws {
		let items = issues.compactMap { issue -> CSSearchableItem? in
			guard issue.pullRequest == nil else { return nil }
			let dest = SpotlightDestination.issue(
				instanceURL: Network.baseURL.absoluteString,
				owner: issue.repository.owner,
				repo: issue.repository.name,
				number: issue.number
			)
			let attrs = CSSearchableItemAttributeSet(contentType: .content)
			attrs.title = "#\(issue.number) \(issue.title)"
			attrs.contentDescription = issue.body.map { String($0.prefix(200)) }
			attrs.keywords = [issue.repository.fullName, issue.title]
			return CSSearchableItem(
				uniqueIdentifier: dest.uniqueIdentifier,
				domainIdentifier: "\(domainPrefix).issue",
				attributeSet: attrs
			)
		}
		guard items.isNotEmpty else { return }
		try await CSSearchableIndex.default().indexItems(items)
	}

	static func index(pullRequests: [Components.Schemas.PullRequest]) async throws {
		let items = pullRequests.compactMap { pr -> CSSearchableItem? in
			let dest = SpotlightDestination.pullRequest(
				instanceURL: Network.baseURL.absoluteString,
				owner: pr.base.repo.owner,
				repo: pr.base.repo.name,
				number: pr.number
			)
			let attrs = CSSearchableItemAttributeSet(contentType: .content)
			attrs.title = "!\(pr.number) \(pr.title)"
			attrs.contentDescription = pr.body.map { String($0.prefix(200)) }
			attrs.keywords = [pr.base.repo.fullName, pr.title]
			return CSSearchableItem(
				uniqueIdentifier: dest.uniqueIdentifier,
				domainIdentifier: "\(domainPrefix).pullRequest",
				attributeSet: attrs
			)
		}
		guard items.isNotEmpty else { return }
		try await CSSearchableIndex.default().indexItems(items)
	}

	static func deleteAll() async throws {
		try await CSSearchableIndex.default().deleteAllItems()
	}

	static func deleteAll(for domain: String) async throws {
		try await CSSearchableIndex.default().deleteItems(withDomainIdentifiers: ["\(domainPrefix).\(domain)"])
	}
}
