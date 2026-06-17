//
//  PushActivityContent.swift
//  Gitea
//
//  Created by Felix Schindler on 16.06.26.
//

import Foundation

struct PushActivityContent: Codable {
	var commits: [PushActivityCommit]?
	var headCommit: PushActivityCommit
	var compareURL: String
	var len: Int

	enum CodingKeys: String, CodingKey {
		case commits = "Commits"
		case headCommit = "HeadCommit"
		case compareURL = "CompareURL"
		case len = "Len"
	}
}

struct PushActivityCommit: Codable {
	var sha1: String
	var message: String
	var authorEmail: String
	var authorName: String
	var committerEmail: String
	var committerName: String
	var timestamp: String

	var messageFirstLine: String {
		message
			.trimmingCharacters(in: .newlines)
			.components(separatedBy: "\n").first ?? ""
	}

	var shaAbbreviated: String {
		String(sha1.prefix(7))
	}

	enum CodingKeys: String, CodingKey {
		case sha1 = "Sha1"
		case message = "Message"
		case authorEmail = "AuthorEmail"
		case authorName = "AuthorName"
		case committerEmail = "CommitterEmail"
		case committerName = "CommitterName"
		case timestamp = "Timestamp"
	}
}
