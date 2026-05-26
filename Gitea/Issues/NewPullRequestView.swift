//
//  NewPullRequestView.swift
//  Gitea
//
//  Created by Felix Schindler on 22.05.26.
//

import HighlightedTextEditor
import SwiftUI

struct NewPullRequestView: View {
	@Environment(\.dismiss) private var dismiss

	let owner: String
	let repo: String

	@State private var title = ""
	@State private var baseBranch = ""
	@State private var headBranch = ""
	@State private var bodyText = ""
	@State private var allowMaintainerEdit = true

	@State private var branches: [Components.Schemas.Branch]?
	@State private var users: [Components.Schemas.User]?
	@State private var labels: [Components.Schemas.Label]?
	@State private var milestones: [Components.Schemas.Milestone]?

	@State private var assignees: [String] = []
	@State private var setLabels: [Int64] = []
	@State private var milestone: Int64?
	@State private var reviewerUsernames: [String] = []

	@State private var error: Error?

	private func load() async {
		async let branches = try? await Network.shared.client
			.repoListBranches(.init(path: .init(owner: owner, repo: repo)))
			.ok.body.json

		async let labels = try? await Network.shared.client
			.issueListLabels(.init(path: .init(owner: owner, repo: repo)))
			.ok.body.json

		async let milestones = try? await Network.shared.client
			.issueGetMilestonesList(.init(path: .init(owner: owner, repo: repo)))
			.ok.body.json

		async let users = try? await Network.shared.client
			.repoGetAssignees(path: .init(owner: owner, repo: repo))
			.ok.body.json

		self.branches = await branches
		self.labels = await labels
		self.milestones = await milestones
		self.users = await users

		// Set defaults
		if self.baseBranch.isEmpty, let firstMainOrMaster = self.branches?.first(where: { $0.name == "main" || $0.name == "master" }) {
			self.baseBranch = firstMainOrMaster.name
		}
	}

	private func create() async {
		do {
			var labelsArg: [Swift.Int64] = []
			if setLabels.isNotEmpty {
				labelsArg = setLabels
			}

			_ = try await Network.shared.client.repoCreatePullRequest(
				path: .init(owner: owner, repo: repo),
				body: .json(
					.init(
						allowMaintainerEdit: allowMaintainerEdit,
						assignee: assignees.first ?? "",
						assignees: assignees,
						base: baseBranch,
						body: bodyText,
						dueDate: Date(),
						head: headBranch,
						labels: labelsArg,
						milestone: milestone ?? 0,
						reviewers: reviewerUsernames,
						teamReviewers: [],
						title: title
					))
			).created

			HapticFeedback.notify(.success)
			dismiss()
		} catch {
			self.error = error
			HapticFeedback.notify(.error)
		}
	}

	var body: some View {
		Form {
			if let error {
				Section {
					FailedView(error)
				}
			}

			Section {
				TextField("Title", text: .init(get: { self.title.emojized() }, set: { self.title = $0 }))
				VStack(alignment: .leading) {
					Text("Description (optional)")
						.font(.footnote)
					HighlightedTextEditor(text: $bodyText, highlightRules: .markdown)
						.frame(minHeight: 100)
				}
			}

			Section {
				if let branches {
					Picker("Base Branch", selection: $baseBranch) {
						ForEach(branches, id: \.name) { branch in
							Text(branch.name).tag(branch.name)
						}
					}
					Picker("Head Branch", selection: $headBranch) {
						ForEach(branches, id: \.name) { branch in
							Text(branch.name).tag(branch.name)
						}
					}
				} else {
					TextField("Base Branch", text: $baseBranch)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
					TextField("Head Branch", text: $headBranch)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
				}
			} header: {
				Text("Branches")
			}

			if let users, users.isNotEmpty {
				Section {
					ForEach(users, id: \.id) { user in
						Button {
							if assignees.contains(user.login) {
								assignees.removeAll { $0 == user.login }
							} else {
								assignees.append(user.login)
							}
						} label: {
							HStack {
								Text(user.fullName.isEmpty ? user.login : user.fullName)
								Spacer()
								if assignees.contains(user.login) {
									Image(systemName: "checkmark")
								}
							}
						}
					}
				} header: {
					HStack {
						Text("Assignees")
						Spacer()
						Text("\(assignees.count)")
					}
				}

				Section {
					ForEach(users, id: \.id) { user in
						Button {
							if reviewerUsernames.contains(user.login) {
								reviewerUsernames.removeAll { $0 == user.login }
							} else {
								reviewerUsernames.append(user.login)
							}
						} label: {
							HStack {
								Text(user.fullName.isEmpty ? user.login : user.fullName)
								Spacer()
								if reviewerUsernames.contains(user.login) {
									Image(systemName: "checkmark")
								}
							}
						}
					}
				} header: {
					HStack {
						Text("Reviewers")
						Spacer()
						Text("\(reviewerUsernames.count)")
					}
				}
			}

			if let labels, labels.isNotEmpty {
				Section {
					ForEach(labels, id: \.id) { label in
						Button {
							if setLabels.contains(label.id) {
								setLabels.removeAll { $0 == label.id }
							} else if label.exclusive {
								let exclusiveIds = Set(labels.filter { $0.exclusive }.map { $0.id })
								setLabels.removeAll { exclusiveIds.contains($0) }
								setLabels.append(label.id)
							} else {
								setLabels.append(label.id)
							}
						} label: {
							HStack {
								SmallLabelView(label: label)
								Spacer()
								if setLabels.contains(label.id) {
									Image(systemName: "checkmark")
								}
							}
						}
					}
				} header: {
					HStack {
						Text("Labels")
						Spacer()
						Text("\(setLabels.count)")
					}
				}
			}

			if let milestones, milestones.isNotEmpty {
				Section {
					Picker("Milestone", selection: $milestone) {
						Text("None").tag(nil as Int64?)
						ForEach(milestones, id: \.id) { milestone in
							Text(milestone.title.emojized()).tag(Optional(milestone.id))
						}
					}
				}
			}

			Section {
				Toggle("Allow maintainers to edit", isOn: $allowMaintainerEdit)
			}
		}.toolbar {
			AsyncButton("Save", systemImage: "checkmark") {
				await create()
			}.disabled(title.isEmpty || baseBranch.isEmpty || headBranch.isEmpty)
				.buttonStyle(.borderedProminent)
		}
		.task {
			await load()
		}.refreshable {
			await load()
		}
		.scrollDismissesKeyboard(.immediately)
		.navigationTitle("New Pull Request")
	}
}

#Preview {
	NavigationStack {
		NewPullRequestView(owner: "Tanuki", repo: "gitea-ios")
	}
}
