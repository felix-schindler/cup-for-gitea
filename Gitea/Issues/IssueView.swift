//
//  IssueView.swift
//  Gitea
//
//  Created by Felix Schindler on 11.05.26.
//

import SwiftUI
import Textual

protocol IssueDisplayable {
	var displayNavigationTitle: LocalizedStringResource { get }
	var displayRepositoryFullName: String { get }
	var displayOwner: String { get }
	var displayRepo: String { get }
	var displayNumber: Int64 { get }
	var displayIsLocked: Bool { get }
	var displayCreatedAt: Date { get }
	var displayTitle: String { get }
	var displayBody: String { get }
	var displayComments: Int64 { get }
	var displayHtmlUrl: String { get }
}

extension Components.Schemas.Issue: IssueDisplayable {
	var displayNavigationTitle: LocalizedStringResource { "Issue" }
	var displayRepositoryFullName: String { repository.fullName }
	var displayOwner: String { repository.owner }
	var displayRepo: String { repository.name }
	var displayNumber: Int64 { number }
	var displayIsLocked: Bool { isLocked }
	var displayCreatedAt: Date { createdAt }
	var displayTitle: String { title }
	var displayBody: String { body }
	var displayComments: Int64 { comments }
	var displayHtmlUrl: String { htmlUrl }
}

extension Components.Schemas.PullRequest: IssueDisplayable {
	var displayNavigationTitle: LocalizedStringResource { "Pull Request" }
	var displayRepositoryFullName: String { base.repo.fullName }
	var displayOwner: String { base.repo.owner.login }
	var displayRepo: String { base.repo.name }
	var displayNumber: Int64 { number }
	var displayIsLocked: Bool { isLocked }
	var displayCreatedAt: Date { createdAt }
	var displayTitle: String { title }
	var displayBody: String { body }
	var displayComments: Int64 { comments }
	var displayHtmlUrl: String { htmlUrl }
}

struct IssueView: View {
	private enum Item {
		case issue(Components.Schemas.Issue)
		case pullRequest(Components.Schemas.PullRequest)

		var data: any IssueDisplayable {
			switch self {
			case .issue(let issue): issue
			case .pullRequest(let pr): pr
			}
		}
	}

	@State private var item: Item
	@State private var error: Error?
	@State private var showErrorAlert = false
	@State private var showMergeSheet = false
	@State private var mergeConfig = MergeConfig()
	@State private var mergeError: Error?
	@State private var showMergeErrorAlert = false
	@State private var commentText = ""
	@State private var commentRefreshID = 0
	@State private var hasPostedComment = false
	@State private var showReviewSheet = false
	@State private var reviewRefreshID = 0
	@State private var reviewEvent: Components.Schemas.CreatePullReviewOptions.EventPayload = .comment

	private struct MergeConfig {
		var method: Components.Schemas.MergePullRequestOption.DoPayload = .merge
		var deleteBranch = false
		var forceMerge = false
	}

	init(_ issue: Components.Schemas.Issue) {
		self._item = State(initialValue: .issue(issue))
	}

	init(_ pullRequest: Components.Schemas.PullRequest) {
		self._item = State(initialValue: .pullRequest(pullRequest))
	}

	var body: some View {
		List {
			Section {
				header
			}

			if item.data.displayBody.isNotEmpty {
				Section("Description") {
					StructuredText(markdown: item.data.displayBody.emojized())
						.textual.structuredTextStyle(.gitHub)
						.textual.textSelection(.enabled)
				}
			}

			Section("Actions") {
				toolbarActions
			}

			if hasDetails {
				Section("Details") {
					details
				}
			}

			if isPullRequest {
				Section("Review") {
					reviewActions
				}

				ReviewsLoader(
					owner: item.data.displayOwner,
					repo: item.data.displayRepo,
					index: item.data.displayNumber,
					refreshID: reviewRefreshID
				)
			}

			Section("Comments") {
				HStack(alignment: .top) {
					ZStack(alignment: .topLeading) {
						if commentText.isEmpty {
							Text("New comment")
								.foregroundStyle(.secondary)
								.font(.body.monospaced())
								.padding(.top, 8)
								.padding(.leading, 4)
						}
						TextEditor(text: $commentText)
							.font(.body.monospaced())
							.frame(maxHeight: 100)
					}

					AsyncButton(systemImage: "paperplane.fill") {
						await postComment()
					}
					.disabled(commentText.isEmpty)
					.buttonStyle(.borderedProminent)
					.buttonBorderShape(.circle)
				}

				if item.data.displayComments != 0 || hasPostedComment {
					CommentsLoader(owner: item.data.displayOwner, repo: item.data.displayRepo, iid: item.data.displayNumber, refreshID: commentRefreshID)
				}
			}
		}.toolbar {
			toolbarContent
		}
		.navigationTitle(Text(item.data.displayNavigationTitle))
		.navigationBarTitleDisplayMode(.inline)
		.scrollDismissesKeyboard(.immediately)
		.alert("Error", isPresented: $showErrorAlert, presenting: error) { _ in
			Button("OK") {}
		} message: { error in
			Text(error.localizedDescription)
		}
		.sheet(isPresented: $showMergeSheet) {
			mergeSheet
		}
		.sheet(isPresented: $showReviewSheet) {
			ReviewSheet(
				owner: item.data.displayOwner,
				repo: item.data.displayRepo,
				index: item.data.displayNumber,
				initialEvent: reviewEvent,
				commitId: reviewCommitId
			) {
				reviewRefreshID += 1
			}
		}
		.alert("Merge Error", isPresented: $showMergeErrorAlert, presenting: mergeError) { _ in
			Button("OK") {}
		} message: { error in
			Text(error.localizedDescription)
		}
	}

	@ToolbarContentBuilder
	private var toolbarContent: some ToolbarContent {
		ToolbarItem(placement: .primaryAction) {
			if let url = URL(string: item.data.displayHtmlUrl) {
				ShareLink(item: url)
			}
		}
	}

	@ViewBuilder
	private var reviewActions: some View {
		if case .pullRequest(let pr) = item, pr.state == .open, !pr.merged, !pr.draft {
			AsyncButton("Approve", systemImage: "checkmark.circle") {
				await quickApprove()
			}
			Button("Comment", systemImage: "bubble.left") {
				reviewEvent = .comment
				showReviewSheet = true
			}
			Button("Request Changes", systemImage: "pencil") {
				reviewEvent = .requestChanges
				showReviewSheet = true
			}
		}
	}

	@ViewBuilder
	private var toolbarActions: some View {
		switch item {
		case .issue(let issue):
			if issue.state == .open {
				AsyncButton("Close", systemImage: "archivebox") {
					await closeIssue()
				}
			} else {
				AsyncButton("Reopen", systemImage: "arrow.circlepath") {
					await reopenIssue()
				}
			}
		case .pullRequest(let pr):
			if !pr.merged {
				if pr.state == .open {
					if pr.draft {
						AsyncButton("Mark Ready for Review", systemImage: "pencil.slash") {
							await markReadyForReview()
						}
					} else {
						AsyncButton("Mark as WIP", systemImage: "pencil") {
							await markAsWIP()
						}

						if pr.base.sha != pr.mergeBase {
							AsyncButton("Update Branch", systemImage: "arrow.triangle.merge") {
								await updatePullRequestBranch()
							}
						}
					}
					AsyncButton("Close", systemImage: "archivebox") {
						await closePullRequest()
					}
					if pr.mergeable {
						Button("Merge", systemImage: "checkmark.circle") {
							showMergeSheet = true
						}
					}
				} else {
					AsyncButton("Reopen", systemImage: "arrow.circlepath") {
						await reopenPullRequest()
					}
				}
			}
		}
	}

	@ViewBuilder
	private var mergeSheet: some View {
		NavigationStack {
			Form {
				Section("Merge Method") {
					Picker("Method", selection: $mergeConfig.method) {
						Text("Merge").tag(Components.Schemas.MergePullRequestOption.DoPayload.merge)
						Text("Rebase").tag(Components.Schemas.MergePullRequestOption.DoPayload.rebase)
						Text("Rebase Merge").tag(Components.Schemas.MergePullRequestOption.DoPayload.rebaseMerge)
						Text("Squash").tag(Components.Schemas.MergePullRequestOption.DoPayload.squash)
						Text("Fast-forward only").tag(Components.Schemas.MergePullRequestOption.DoPayload.fastForwardOnly)
					}
				}

				Section("Options") {
					Toggle("Delete branch after merge", isOn: $mergeConfig.deleteBranch)
					Toggle("Force merge", isOn: $mergeConfig.forceMerge)
				}

				Section {
					AsyncButton("Merge Pull Request", role: .destructive) {
						await mergePullRequest()
					}
				}
			}
			.navigationTitle("Merge")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel") {
						showMergeSheet = false
					}
				}
			}
		}
		.presentationDetents([.medium])
	}

	// MARK: - Actions

	private func closeIssue() async {
		guard case .issue(let issue) = item else { return }
		do {
			let response = try await Network.shared.client.issueEditIssue(
				.init(
					path: .init(owner: item.data.displayOwner, repo: item.data.displayRepo, index: item.data.displayNumber),
					body: .json(
						.init(
							assignee: "", assignees: [], body: issue.body,
							contentVersion: issue.contentVersion, dueDate: issue.dueDate ?? Date(),
							milestone: issue.milestone?.id ?? 0, ref: issue.ref,
							state: "closed", title: issue.title, unsetDueDate: issue.dueDate == nil
						))
				)
			).created.body.json
			item = .issue(response)
			HapticFeedback.notify(.success)
		} catch {
			self.error = error
			showErrorAlert = true
			HapticFeedback.notify(.error)
		}
	}

	private func reopenIssue() async {
		guard case .issue(let issue) = item else { return }
		do {
			let response = try await Network.shared.client.issueEditIssue(
				.init(
					path: .init(owner: item.data.displayOwner, repo: item.data.displayRepo, index: item.data.displayNumber),
					body: .json(
						.init(
							assignee: "", assignees: [], body: issue.body,
							contentVersion: issue.contentVersion, dueDate: issue.dueDate ?? Date(),
							milestone: issue.milestone?.id ?? 0, ref: "",
							state: "open", title: issue.title, unsetDueDate: false
						))
				)
			).created.body.json
			item = .issue(response)
			HapticFeedback.notify(.success)
		} catch {
			self.error = error
			showErrorAlert = true
			HapticFeedback.notify(.error)
		}
	}

	private func closePullRequest() async {
		guard case .pullRequest(let pr) = item else { return }
		do {
			let response = try await Network.shared.client.repoEditPullRequest(
				.init(
					path: .init(owner: item.data.displayOwner, repo: item.data.displayRepo, index: item.data.displayNumber),
					body: .json(
						.init(
							allowMaintainerEdit: pr.allowMaintainerEdit, assignee: pr.assignee?.login ?? "",
							assignees: pr.assignees?.map(\.login) ?? [], base: pr.base.ref,
							body: pr.body, contentVersion: pr.contentVersion,
							dueDate: pr.dueDate ?? Date(), labels: pr.labels.map(\.id),
							milestone: pr.milestone?.id ?? 0, state: "closed",
							title: pr.title, unsetDueDate: pr.dueDate == nil
						))
				)
			).created.body.json
			item = .pullRequest(response)
			HapticFeedback.notify(.success)
		} catch {
			self.error = error
			showErrorAlert = true
			HapticFeedback.notify(.error)
		}
	}

	private func reopenPullRequest() async {
		guard case .pullRequest(let pr) = item else { return }
		do {
			let response = try await Network.shared.client.repoEditPullRequest(
				.init(
					path: .init(owner: item.data.displayOwner, repo: item.data.displayRepo, index: item.data.displayNumber),
					body: .json(
						.init(
							allowMaintainerEdit: pr.allowMaintainerEdit, assignee: pr.assignee?.login ?? "",
							assignees: pr.assignees?.map(\.login) ?? [], base: pr.base.ref,
							body: pr.body, contentVersion: pr.contentVersion,
							dueDate: pr.dueDate ?? Date(), labels: pr.labels.map(\.id),
							milestone: pr.milestone?.id ?? 0, state: "open",
							title: pr.title, unsetDueDate: false
						))
				)
			).created.body.json
			item = .pullRequest(response)
			HapticFeedback.notify(.success)
		} catch {
			self.error = error
			showErrorAlert = true
			HapticFeedback.notify(.error)
		}
	}

	private func mergePullRequest() async {
		guard case .pullRequest = item else { return }
		do {
			let response = try await Network.shared.client.repoMergePullRequest(
				.init(
					path: .init(owner: item.data.displayOwner, repo: item.data.displayRepo, index: item.data.displayNumber),
					body: .json(
						.init(
							deleteBranchAfterMerge: mergeConfig.deleteBranch,
							_do: mergeConfig.method,
							forceMerge: mergeConfig.forceMerge,
							headCommitId: "", mergeCommitId: "",
							mergeMessageField: "", mergeTitleField: "",
							mergeWhenChecksSucceed: false
						))
				)
			)

			switch response {
			case .ok:
				let pr = try await Network.shared.client.repoGetPullRequest(
					.init(path: .init(owner: item.data.displayOwner, repo: item.data.displayRepo, index: item.data.displayNumber))
				).ok.body.json
				item = .pullRequest(pr)
				showMergeSheet = false
				HapticFeedback.notify(.success)
			case .methodNotAllowed:
				self.mergeError = NSError(domain: "", code: 405, userInfo: [NSLocalizedDescriptionKey: "Pull request is not mergeable. It may be marked as Work in Progress or have merge conflicts."])
				showMergeErrorAlert = true
				HapticFeedback.notify(.error)
			case .conflict(let error):
				self.mergeError = NSError(domain: "", code: 409, userInfo: [NSLocalizedDescriptionKey: error.headers.message ?? "Merge conflict"])
				showMergeErrorAlert = true
				HapticFeedback.notify(.error)
			case .code423:
				self.mergeError = NSError(domain: "", code: 423, userInfo: [NSLocalizedDescriptionKey: "Repository is archived"])
				showMergeErrorAlert = true
				HapticFeedback.notify(.error)
			case .forbidden(let error):
				self.mergeError = NSError(domain: "", code: 403, userInfo: [NSLocalizedDescriptionKey: error.headers.message ?? "Forbidden"])
				showMergeErrorAlert = true
				HapticFeedback.notify(.error)
			default:
				self.mergeError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])
				showMergeErrorAlert = true
				HapticFeedback.notify(.error)
			}
		} catch {
			self.mergeError = error
			showMergeErrorAlert = true
			HapticFeedback.notify(.error)
		}
	}

	private func updatePullRequestBranch() async {
		do {
			let response = try await Network.shared.client.repoUpdatePullRequest(
				.init(
					path: .init(owner: item.data.displayOwner, repo: item.data.displayRepo, index: item.data.displayNumber)
				)
			)

			switch response {
			case .ok:
				HapticFeedback.notify(.success)
			case .conflict(let error):
				self.error = NSError(domain: "", code: 409, userInfo: [NSLocalizedDescriptionKey: error.headers.message ?? "Update conflict"])
				showErrorAlert = true
				HapticFeedback.notify(.error)
			case .forbidden(let error):
				self.error = NSError(domain: "", code: 403, userInfo: [NSLocalizedDescriptionKey: error.headers.message ?? "Forbidden"])
				showErrorAlert = true
				HapticFeedback.notify(.error)
			default:
				HapticFeedback.notify(.success)
			}
		} catch {
			self.error = error
			showErrorAlert = true
			HapticFeedback.notify(.error)
		}
	}

	private func markReadyForReview() async {
		guard case .pullRequest(let pr) = item else { return }

		let cleanedTitle = pr.title
			.replacingOccurrences(of: #"^\[WIP\]\s*"#, with: "", options: .regularExpression)
			.replacingOccurrences(of: #"^WIP:\s*"#, with: "", options: .regularExpression)

		guard cleanedTitle != pr.title else {
			self.error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No WIP prefix found in title."])
			showErrorAlert = true
			HapticFeedback.notify(.error)
			return
		}

		do {
			let response = try await Network.shared.client.repoEditPullRequest(
				.init(
					path: .init(owner: item.data.displayOwner, repo: item.data.displayRepo, index: item.data.displayNumber),
					body: .json(
						.init(
							allowMaintainerEdit: pr.allowMaintainerEdit, assignee: pr.assignee?.login ?? "",
							assignees: pr.assignees?.map(\.login) ?? [], base: pr.base.ref,
							body: pr.body, contentVersion: pr.contentVersion,
							dueDate: pr.dueDate ?? Date(), labels: pr.labels.map(\.id),
							milestone: pr.milestone?.id ?? 0, state: "open",
							title: cleanedTitle, unsetDueDate: pr.dueDate == nil
						))
				)
			).created.body.json
			item = .pullRequest(response)
			HapticFeedback.notify(.success)
		} catch {
			self.error = error
			showErrorAlert = true
			HapticFeedback.notify(.error)
		}
	}

	private func markAsWIP() async {
		guard case .pullRequest(let pr) = item else { return }
		guard !pr.title.hasPrefix("WIP:"), !pr.title.hasPrefix("[WIP]") else {
			self.error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Pull request is already marked as WIP."])
			showErrorAlert = true
			HapticFeedback.notify(.error)
			return
		}

		do {
			let response = try await Network.shared.client.repoEditPullRequest(
				.init(
					path: .init(owner: item.data.displayOwner, repo: item.data.displayRepo, index: item.data.displayNumber),
					body: .json(
						.init(
							allowMaintainerEdit: pr.allowMaintainerEdit, assignee: pr.assignee?.login ?? "",
							assignees: pr.assignees?.map(\.login) ?? [], base: pr.base.ref,
							body: pr.body, contentVersion: pr.contentVersion,
							dueDate: pr.dueDate ?? Date(), labels: pr.labels.map(\.id),
							milestone: pr.milestone?.id ?? 0, state: "open",
							title: "WIP: " + pr.title, unsetDueDate: pr.dueDate == nil
						))
				)
			).created.body.json
			item = .pullRequest(response)
			HapticFeedback.notify(.success)
		} catch {
			self.error = error
			showErrorAlert = true
			HapticFeedback.notify(.error)
		}
	}

	private func quickApprove() async {
		guard case .pullRequest(let pr) = item else { return }
		do {
			let response = try await Network.shared.client.repoCreatePullReview(
				.init(
					path: .init(owner: item.data.displayOwner, repo: item.data.displayRepo, index: item.data.displayNumber),
					body: .json(
						.init(
							body: "",
							comments: [],
							commitId: pr.head.sha,
							event: .approved
						))
				)
			)
			switch response {
			case .ok:
				reviewRefreshID += 1
				HapticFeedback.notify(.success)
			case .unprocessableContent(let error):
				self.error = NSError(
					domain: "", code: 422,
					userInfo: [NSLocalizedDescriptionKey: error.headers.message ?? "Validation error"]
				)
				showErrorAlert = true
				HapticFeedback.notify(.error)
			case .notFound:
				self.error = NSError(
					domain: "", code: 404,
					userInfo: [NSLocalizedDescriptionKey: "Review not found"]
				)
				showErrorAlert = true
				HapticFeedback.notify(.error)
			case .undocumented:
				self.error = NSError(
					domain: "", code: 0,
					userInfo: [NSLocalizedDescriptionKey: "An unexpected error occurred"]
				)
				showErrorAlert = true
				HapticFeedback.notify(.error)
			}
		} catch {
			self.error = error
			showErrorAlert = true
			HapticFeedback.notify(.error)
		}
	}

	private func postComment() async {
		let body = commentText
		commentText = ""
		do {
			_ = try await Network.shared.client.issueCreateComment(
				.init(
					path: .init(owner: item.data.displayOwner, repo: item.data.displayRepo, index: item.data.displayNumber),
					body: .json(.init(body: body))
				)
			).created.body.json
			commentRefreshID += 1
			hasPostedComment = true
			HapticFeedback.notify(.success)
		} catch {
			commentText = body
			self.error = error
			showErrorAlert = true
			HapticFeedback.notify(.error)
		}
	}

	// MARK: - Views

	private var header: some View {
		VStack(alignment: .leading) {
			HStack {
				stateIcon
				Text("\(item.data.displayRepositoryFullName)#\(item.data.displayNumber)")
					.foregroundStyle(.secondary)
				if item.data.displayIsLocked {
					Image(systemName: "lock")
				}
				Spacer()
				Text(item.data.displayCreatedAt.toString())
			}.font(.footnote)

			InlineText(markdown: item.data.displayTitle.emojized())
				.textual.inlineStyle(.gitHub)
				.textual.textSelection(.enabled)

			headerMetadata

			issueMetadata
		}
	}

	@ViewBuilder
	private var stateIcon: some View {
		switch item {
		case .issue(let issue):
			StateIconView(.issue, issue.state)
		case .pullRequest(let pullRequest):
			StateIconView(.pull, pullRequest.notificationState, isDraft: pullRequest.draft)
		}
	}

	@ViewBuilder
	private var headerMetadata: some View {
		ScrollView(.horizontal, showsIndicators: false) {
			HStack {
				switch item {
				case .issue(let issue):
					SmallUserView(issue.user)
					if let pr = issue.pullRequest,
						let url = URL(string: pr.htmlUrl)
					{
						NavigationLink(
							destination: PullRequestLoader(owner: item.data.displayOwner, repo: item.data.displayRepo, index: item.data.displayNumber)
						) {
							Label(
								title: {
									Text("#\(url.lastPathComponent)")
								},
								icon: {
									StateIconView(.pull, issue.pullRequestState, isDraft: pr.draft)
								})
						}
						.controlSize(.mini)
						.buttonStyle(.bordered)
					}
					if let milestone = issue.milestone {
						NavigationLink {
							MilestonesLoader(owner: item.data.displayOwner, repo: item.data.displayRepo)
						} label: {
							Label(milestone.title.emojized(), systemImage: Icons.milestones.rawValue)
						}
						.controlSize(.mini)
						.buttonStyle(.bordered)
					}
				case .pullRequest(let pullRequest):
					SmallUserView(pullRequest.user)
					branchPill(pullRequest.head.ref)
					Image(systemName: "arrow.right")
					branchPill(pullRequest.base.ref)
				}
			}
		}.font(.footnote)
	}

	@ViewBuilder
	private func branchPill(_ name: String) -> some View {
		PillView(
			verbatim: name,
			bgColor: .blue,
			fgColor: .white,
			cornerRadius: 5
		)
		.monospaced()
		.textSelection(.enabled)
	}

	@ViewBuilder
	private var issueMetadata: some View {
		switch item {
		case .issue(let issue):
			if issue.timeEstimate != 0 || issue.dueDate != nil {
				ScrollView(.horizontal, showsIndicators: false) {
					HStack {
						if issue.timeEstimate != 0 {
							PillView(verbatim: "\(issue.timeEstimate)", systemImage: "clock")
								.font(.footnote)
						}
						if let dueDate = issue.dueDate {
							PillView(verbatim: dueDate.toString(), systemImage: "calendar.badge.checkmark")
						}
					}
				}
			}

			if issue.assets.isNotEmpty {
				ScrollView(.horizontal, showsIndicators: false) {
					ForEach(issue.assets, id: \.id) { asset in
						if let url = URL(string: asset.browserDownloadUrl) {
							Link(asset.name, destination: url)
						} else {
							Text(asset.name)
						}
					}
				}
			}
		case .pullRequest(let pullRequest):
			if pullRequest.draft {
				PillView("Draft", systemImage: "pencil")
					.font(.footnote)
			}
		}
	}

	@ViewBuilder
	private var details: some View {
		switch item {
		case .issue(let issue):
			commonDetails(assignees: issue.assignees, labels: issue.labels, milestoneTitle: issue.milestone?.title)
		case .pullRequest(let pullRequest):
			commonDetails(
				assignees: pullRequest.assignees,
				labels: pullRequest.labels,
				milestoneTitle: pullRequest.milestone?.title
			)
			pullRequestDetails(pullRequest)
		}
	}

	@ViewBuilder
	private func commonDetails(
		assignees: [Components.Schemas.User]?,
		labels: [Components.Schemas.Label],
		milestoneTitle: String?
	) -> some View {
		if let assignees, assignees.isNotEmpty {
			DisclosureGroup(
				content: {
					ForEach(assignees, id: \.id) { user in
						SmallUserView(user)
					}
				},
				label: {
					Label(
						title: {
							HStack {
								Text("Assignees")
								Spacer()
								Text("\(assignees.count)")
							}
						},
						icon: {
							Image(systemName: Icons.users.rawValue)
						})
				})
		}

		if labels.isNotEmpty {
			Label(
				title: {
					ScrollView(.horizontal) {
						HStack {
							ForEach(labels, id: \.id) { label in
								let bgColor = Color(hex: label.color)
								PillView(
									verbatim: label.name.emojized(),
									bgColor: bgColor,
									fgColor: bgColor.adaptiveText()
								)
							}
						}
					}
				},
				icon: {
					Image(systemName: Icons.topics.rawValue)
				}
			)
		}

		if let milestoneTitle {
			Label(milestoneTitle.emojized(), systemImage: Icons.milestones.rawValue)
		}
	}

	@ViewBuilder
	private func pullRequestDetails(_ pullRequest: Components.Schemas.PullRequest) -> some View {
		if let requestedReviewers = pullRequest.requestedReviewers, requestedReviewers.isNotEmpty {
			DisclosureGroup(
				content: {
					ForEach(requestedReviewers, id: \.id) { user in
						SmallUserView(user)
					}
				},
				label: {
					Label(
						title: {
							HStack {
								Text("Requested reviewers")
								Spacer()
								Text("\(requestedReviewers.count)")
							}
						},
						icon: {
							Image(systemName: Icons.users.rawValue)
						})
				}
			)
		}

		if let requestedTeams = pullRequest.requestedReviewersTeams, requestedTeams.isNotEmpty {
			DisclosureGroup(
				content: {
					ForEach(requestedTeams, id: \.id) { team in
						Label(team.name, systemImage: "person.3")
					}
				},
				label: {
					Label(
						title: {
							HStack {
								Text("Requested teams")
								Spacer()
								Text("\(requestedTeams.count)")
							}
						},
						icon: {
							Image(systemName: "person.3")
						})
				}
			)
		}

		if let additions = pullRequest.additions,
			let deletions = pullRequest.deletions,
			let changedFiles = pullRequest.changedFiles
		{
			NavigationLink {
				PullRequestDiffLoader(
					owner: item.data.displayOwner,
					repo: item.data.displayRepo,
					index: item.data.displayNumber
				)
			} label: {
				Label(
					title: {
						HStack {
							Text("\(changedFiles) files changed")
							Spacer()
							HStack {
								Text("+\(additions)")
									.foregroundStyle(.green)
								Text("-\(deletions)")
									.foregroundStyle(.red)
							}.monospaced()
						}
					},
					icon: {
						Image(systemName: "doc.text")
					}
				)
			}
		}

		if pullRequest.reviewComments != 0 {
			Label(
				title: {
					HStack {
						Text("Review comments")
						Spacer()
						Text("\(pullRequest.reviewComments)")
					}
				},
				icon: {
					Image(systemName: "text.bubble")
				})
		}
	}

	private var isPullRequest: Bool {
		if case .pullRequest = item { true } else { false }
	}

	private var reviewCommitId: String {
		if case .pullRequest(let pr) = item { pr.head.sha } else { "" }
	}

	private var hasDetails: Bool {
		switch item {
		case .issue(let issue):
			(issue.assignees?.isNotEmpty == true) || issue.labels.isNotEmpty || issue.milestone != nil
		case .pullRequest(let pullRequest):
			(pullRequest.assignees?.isNotEmpty == true)
				|| pullRequest.labels.isNotEmpty
				|| pullRequest.milestone != nil
				|| (pullRequest.requestedReviewers?.isNotEmpty == true)
				|| (pullRequest.requestedReviewersTeams?.isNotEmpty == true)
				|| pullRequest.additions != nil
				|| pullRequest.deletions != nil
				|| pullRequest.changedFiles != nil
				|| pullRequest.reviewComments != 0
		}
	}
}
