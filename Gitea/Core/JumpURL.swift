//
//  JumpURL.swift
//  Gitea
//
//  Created by Felix Schindler on 18.11.26.
//

import Foundation

enum JumpTarget: Hashable {
	/// A bare `host/username` — a user or organization, resolved at runtime.
	case namespace(String)
	/// A bare `host/owner/repo` — a repository.
	case repository(owner: String, repo: String)
	/// A single issue or pull request: the repository and index are right there in the URL.
	case issue(owner: String, repo: String, index: Int64)
	case pullRequest(owner: String, repo: String, index: Int64)
	/// Any sub-page of a repository, resolved at runtime.
	case route(owner: String, repo: String, route: JumpRoute)
}

enum JumpRoute: Hashable {
	case issues
	case pulls
	case releases(tag: String?)
	case actions
	case run(Int64)
	case commits(ref: String)
	case commit(sha: String)
	case tree(ref: String, path: String?)
}

extension JumpTarget {
	var describeTarget: String {
		switch self {
		case .namespace(let name):
			return "“\(name)”"
		case .repository(let owner, let repo):
			return "Repository “\(owner)/\(repo)”"
		case .issue(let owner, let repo, let index):
			return "Repository “\(owner)/\(repo)” → issue #\(index)"
		case .pullRequest(let owner, let repo, let index):
			return "Repository “\(owner)/\(repo)” → pull request #\(index)"
		case .route(let owner, let repo, let route):
			return "“\(owner)/\(repo)” → \(route.describeTarget)"
		}
	}
}

extension JumpRoute {
	var describeTarget: String {
		switch self {
		case .issues:
			return "issues"
		case .pulls:
			return "pull requests"
		case .releases(let tag):
			return tag.map { "release “\($0)”" } ?? "releases"
		case .actions:
			return "actions"
		case .run(let id):
			return "workflow run #\(id)"
		case .commits(let ref):
			return "commits on “\(ref)”"
		case .commit(let sha):
			return "commit \(sha)"
		case .tree(let ref, let path):
			if let path {
				return "file “\(path)” on “\(ref)”"
			}
			return "repository at “\(ref)”"
		}
	}
}

enum JumpURLError: Error, Equatable {
	case emptyClipboard
	case notALink(raw: String)
	case wrongHost(urlHost: String, expectedHost: String)
	case nothingToOpen(raw: String, host: String)

	var title: String {
		switch self {
		case .emptyClipboard, .notALink:
			return "No link on the clipboard"
		case .wrongHost:
			return "That link belongs to another instance"
		case .nothingToOpen:
			return "That link doesn't point anywhere"
		}
	}

	var message: String {
		switch self {
		case .emptyClipboard:
			return "Nothing was on the clipboard. Copy a Gitea link, then try again."
		case .notALink(let raw):
			return "“\(JumpURLError.excerpt(raw))” isn't an http(s) link, so there's nothing to open."
		case .wrongHost(let urlHost, let expectedHost):
			return "The link is for “\(urlHost)”, but this app is signed in to “\(expectedHost)”, so it can't open it."
		case .nothingToOpen(_, let host):
			return "The link only points at “\(host)”, not at a repository, issue or pull request."
		}
	}

	static func excerpt(_ raw: String, limit: Int = 160) -> String {
		let collapsed = raw.split(whereSeparator: \.isWhitespace).joined(separator: " ")
		guard collapsed.isNotEmpty else { return "(empty)" }
		guard collapsed.count > limit else { return collapsed }
		return String(collapsed.prefix(limit)) + "…"
	}
}

enum JumpURL {
	static func parse(_ raw: String, host: String) throws -> JumpTarget {
		let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
		guard trimmed.isNotEmpty else { throw JumpURLError.emptyClipboard }

		let candidate = firstURL(in: trimmed) ?? trimmed

		guard let url = URL(string: candidate),
			let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
			let urlHost = hostWithPort(of: url)
		else { throw JumpURLError.notALink(raw: trimmed) }

		guard isSameHost(urlHost, authority(of: host)) else {
			throw JumpURLError.wrongHost(urlHost: urlHost, expectedHost: host)
		}

		var segments = url.pathComponents.filter { $0 != "/" && !$0.isEmpty }
		let basePath = basePathSegments(of: host)
		if !basePath.isEmpty {
			guard segments.starts(with: basePath) else {
				throw JumpURLError.nothingToOpen(raw: trimmed, host: host)
			}
			segments.removeFirst(basePath.count)
		}
		guard !segments.isEmpty else {
			throw JumpURLError.nothingToOpen(raw: trimmed, host: host)
		}

		guard segments.count >= 2 else {
			return .namespace(segments[0])
		}

		let owner = segments[0]
		let repo = segments[1]
		let rest = Array(segments.dropFirst(2))
		guard let kind = rest.first else {
			return .repository(owner: owner, repo: repo)
		}
		let value = rest.count >= 2 ? rest[1] : nil

		switch kind {
		case "issues":
			if let value, let index = Int64(value) { return .issue(owner: owner, repo: repo, index: index) }
			return .route(owner: owner, repo: repo, route: .issues)
		case "pulls", "pull":
			if let value, let index = Int64(value) { return .pullRequest(owner: owner, repo: repo, index: index) }
			return .route(owner: owner, repo: repo, route: .pulls)
		case "releases":
			let tag = rest.count >= 3 && rest[1] == "tag" ? rest[2...].joined(separator: "/") : nil
			return .route(owner: owner, repo: repo, route: .releases(tag: tag))
		case "actions":
			if rest.count >= 3, rest[1] == "runs", let id = Int64(rest[2]) {
				return .route(owner: owner, repo: repo, route: .run(id))
			}
			return .route(owner: owner, repo: repo, route: .actions)
		case "commit":
			guard let sha = value else { return .repository(owner: owner, repo: repo) }
			return .route(owner: owner, repo: repo, route: .commit(sha: sha))
		case "commits":
			if rest.count >= 3, rest[1] == "branch" {
				return .route(owner: owner, repo: repo, route: .commits(ref: rest[2...].joined(separator: "/")))
			}
			return .repository(owner: owner, repo: repo)
		case "src":
			if rest.count >= 3, rest[1] == "branch" {
				let path = rest.count > 3 ? rest[3...].joined(separator: "/") : nil
				return .route(owner: owner, repo: repo, route: .tree(ref: rest[2], path: path))
			}
			return .repository(owner: owner, repo: repo)
		default:
			return .repository(owner: owner, repo: repo)
		}
	}

	/// Extracts the first `http(s)://…` token from text that may hold more than a link.
	private static func firstURL(in text: String) -> String? {
		let lowercased = text.lowercased()
		guard let start = ["https://", "http://"].compactMap({ lowercased.range(of: $0)?.lowerBound }).min()
		else { return nil }

		let terminators: Set<Character> = [" ", "\n", "\r", "\t", "<", ">", "\"", "'", "`", "]", ")", ","]
		let tail = text[start...]
		let end = tail.firstIndex(where: { terminators.contains($0) }) ?? text.endIndex
		return String(text[start..<end])
	}

	/// `host`, plus the port when it isn't the default one. `URL.host()` drops it,
	/// but a self-hosted instance may live on a port.
	private static func hostWithPort(of url: URL) -> String? {
		guard let host = url.host()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
			host.isNotEmpty
		else { return nil }
		guard let port = url.port, port != 443, port != 80 else { return host }
		return "\(host):\(port)"
	}

	private static func isSameHost(_ urlHost: String, _ expectedHost: String) -> Bool {
		func name(_ host: String) -> String {
			let bare = stripPort(host)
			return bare.hasPrefix("www.") ? String(bare.dropFirst(4)) : bare
		}

		let expected = expectedHost.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
		guard name(urlHost) == name(expected) else { return false }

		// `hostWithPort()` already drops default ports, so a nil URL port means default;
		// treat an explicit default port on the configured host the same way.
		let urlPort = port(of: urlHost)
		let expectedPort = port(of: expected).flatMap { $0 == "443" || $0 == "80" ? nil : $0 }
		return urlPort == expectedPort
	}

	/// The configured instance without its base path: `host` or `host:port`.
	private static func authority(of host: String) -> String {
		guard let url = instanceURL(host), let name = url.host()?.lowercased() else { return host }
		guard let port = url.port, port != 443, port != 80 else { return name }
		return "\(name):\(port)"
	}

	/// The base path the instance is mounted at, e.g. `["gitea"]` for `host/gitea`.
	private static func basePathSegments(of host: String) -> [String] {
		guard let url = instanceURL(host) else { return [] }
		return url.pathComponents.filter { $0 != "/" && !$0.isEmpty }
	}

	private static func instanceURL(_ host: String) -> URL? {
		URL(string: host.contains("://") ? host : "https://\(host)")
	}

	private static func stripPort(_ host: String) -> String {
		guard let colon = host.lastIndex(of: ":") else { return host }
		return String(host[..<colon])
	}

	private static func port(of host: String) -> String? {
		guard let colon = host.lastIndex(of: ":") else { return nil }
		return String(host[host.index(after: colon)...])
	}
}

/// Everything the app knows about the last "Jump" attempt, so the UI can say
/// which link was on the clipboard and why it didn't open.
struct JumpDiagnostics {
	let raw: String
	let host: String
	var target: JumpTarget?
	var error: JumpURLError?

	var summary: String {
		error?.title ?? target?.describeTarget ?? "Nothing to open"
	}

	var message: String? {
		error?.message
	}
}
