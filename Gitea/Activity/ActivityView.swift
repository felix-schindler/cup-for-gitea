//
//  ActivityView.swift
//  Gitea
//
//  Created by Felix Schindler on 16.06.26.
//

import SwiftUI

struct ActivityView: View {
	let activity: Components.Schemas.Activity
	var showActor: Bool = true

	var body: some View {
		NavigationLink(destination: destinationView) {
			VStack(alignment: .leading) {
				if showActor {
					ScrollView(.horizontal, showsIndicators: false) {
						HStack {
							SmallUserView(activity.actUser)
							PillView(verbatim: activity.repo.fullName)
							PillView(verbatim: activity.created.formatted(.relative(presentation: .named, unitsStyle: .abbreviated)))
						}.font(.footnote)
					}
				}

				HStack {
					Image(systemName: icon)
						.foregroundStyle(iconColor)
					Text(description)
				}

				switch activity.opType {
				case .createIssue, .commentIssue, .closeIssue, .reopenIssue,
					.createPullRequest, .mergePullRequest, .closePullRequest, .reopenPullRequest,
					.commentPull, .approvePullRequest, .rejectPullRequest, .pullReviewDismissed,
					.pullRequestReadyForReview, .autoMergePullRequest:
					let parts = activity.content.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)
					if parts.count == 2 {
						let content = String(parts[1])

						if content.isNotEmpty {
							Text(content.emojized())
								.font(.footnote)
								.lineLimit(5)
						}
					}
				default:
					if activity.content.isNotEmpty {
						Text(activity.content.emojized())
							.font(.footnote)
							.lineLimit(5)
					}
				}
			}
		}
		.buttonStyle(.plain)
	}

	private var actorName: String {
		let actor = activity.actUser
		if actor.fullName.isNotEmpty {
			return actor.fullName
		}
		return actor.login
	}

	@ViewBuilder
	private var destinationView: some View {
		let owner = activity.repo.owner.login
		let repo = activity.repo.name
		let ref = activity.refName

		switch activity.opType {
		case .createIssue, .commentIssue, .closeIssue, .reopenIssue:
			if let index = Int64(activity.content.split(separator: "|").first ?? "") {
				IssueLoader(owner: owner, repo: repo, index: index)
			} else {
				FullRepoView(activity.repo)
			}
		case .createPullRequest, .mergePullRequest, .closePullRequest, .reopenPullRequest,
			.commentPull, .approvePullRequest, .rejectPullRequest, .pullReviewDismissed,
			.pullRequestReadyForReview, .autoMergePullRequest:
			if let index = Int64(activity.content.split(separator: "|").first ?? "") {
				PullRequestLoader(owner: owner, repo: repo, index: index)
			} else {
				FullRepoView(activity.repo)
			}
		case .commitRepo:
			CommitsLoader(owner: owner, repo: repo, ref: ref)
		case .pushTag, .deleteTag:
			TagsLoader(owner: owner, repo: repo)
		case .publishRelease:
			ReleaseLoader(owner: owner, repo: repo)
		case .deleteBranch:
			BranchesLoader(owner: owner, repo: repo)
		default:
			FullRepoView(activity.repo)
		}
	}

	private var icon: String {
		switch activity.opType {
		case .createRepo: return "book.closed"
		case .renameRepo: return "pencil"
		case .starRepo: return "star"
		case .watchRepo: return "eye"
		case .commitRepo: return "checkmark.circle"
		case .createIssue: return "dot.circle"
		case .createPullRequest: return "arrow.triangle.pull"
		case .transferRepo: return "arrow.left.arrow.right"
		case .pushTag: return "tag"
		case .commentIssue: return "note.text"
		case .mergePullRequest: return "arrow.triangle.merge"
		case .closeIssue: return "xmark.circle"
		case .reopenIssue: return "arrow.circlepath"
		case .closePullRequest: return "xmark.circle"
		case .reopenPullRequest: return "arrow.circlepath"
		case .deleteTag: return "tag.slash"
		case .deleteBranch: return "arrow.triangle.branch.slash"
		case .mirrorSyncPush: return "arrow.triangle.2.circlepath"
		case .mirrorSyncCreate: return "arrow.triangle.2.circlepath"
		case .mirrorSyncDelete: return "arrow.triangle.2.circlepath"
		case .approvePullRequest: return "checkmark.seal"
		case .rejectPullRequest: return "xmark.seal"
		case .commentPull: return "note.text"
		case .publishRelease: return "music.note"
		case .pullReviewDismissed: return "xmark.seal"
		case .pullRequestReadyForReview: return "arrow.triangle.pull"
		case .autoMergePullRequest: return "arrow.triangle.merge"
		}
	}

	private var iconColor: Color {
		switch activity.opType {
		case .starRepo, .watchRepo: return .yellow
		case .createRepo, .pushTag, .publishRelease: return .green
		case .createIssue, .reopenIssue, .reopenPullRequest: return .green
		case .closeIssue, .closePullRequest, .deleteTag, .deleteBranch: return .red
		case .mergePullRequest, .autoMergePullRequest: return .purple
		case .approvePullRequest: return .green
		case .rejectPullRequest, .pullReviewDismissed: return .red
		case .commentIssue, .commentPull: return .blue
		case .commitRepo: return .teal
		default: return .secondary
		}
	}

	private var description: LocalizedStringResource {
		let ref =
			switch activity.opType {
			case .createIssue, .commentIssue, .closeIssue, .reopenIssue,
				.createPullRequest, .mergePullRequest, .closePullRequest, .reopenPullRequest,
				.commentPull, .approvePullRequest, .rejectPullRequest, .pullReviewDismissed,
				.pullRequestReadyForReview, .autoMergePullRequest:
				if let iid = activity.content.split(separator: "|").first {
					String(iid)
				} else {
					""
				}
			default:
				activity.refName
			}

		return switch activity.opType {
		case .createRepo: "Created repository"
		case .renameRepo: "Renamed repository"
		case .starRepo: "Starred"
		case .watchRepo: "Started watching"
		case .commitRepo: "Pushed to \(ref)"
		case .createIssue: "Opened issue"
		case .createPullRequest: "Opened pull request #\(ref)"
		case .transferRepo: "Transferred repository"
		case .pushTag: "Pushed tag to \(ref)"
		case .commentIssue: "Commented on issue #\(ref)"
		case .mergePullRequest: "Merged pull request #\(ref)"
		case .closeIssue: "Closed issue #\(ref)"
		case .reopenIssue: "Reopened issue #\(ref)"
		case .closePullRequest: "Closed pull request #\(ref)"
		case .reopenPullRequest: "Reopened pull request #\(ref)"
		case .deleteTag: "Deleted tag \(ref)"
		case .deleteBranch: "Deleted branch \(ref)"
		case .mirrorSyncPush: "Mirror-pushed"
		case .mirrorSyncCreate: "Mirror-created"
		case .mirrorSyncDelete: "Mirror-deleted"
		case .approvePullRequest: "Approved pull request #\(ref)"
		case .rejectPullRequest: "Rejected pull request #\(ref)"
		case .commentPull: "Commented on pull request #\(ref)"
		case .publishRelease: "Published release"
		case .pullReviewDismissed: "Dismissed review on pull request"
		case .pullRequestReadyForReview: "Marked pull request ready for review"
		case .autoMergePullRequest: "Auto-merged pull request"
		}
	}
}
