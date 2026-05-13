//
//  NewIssueView.swift
//  Gitea
//
//  Created by Felix Schindler on 11.05.26.
//

import HighlightedTextEditor
import SwiftUI

struct NewIssueView: View {
	@Environment(\.dismiss) var dismiss

	let owner: String
	let repo: String

	@State private var title = ""
	@State private var content = ""
	@State private var setDueDate = false
	@State private var dueDate = Date()

	@State private var users: [Components.Schemas.User]?
	@State private var labels: [Components.Schemas.Label]?
	@State private var milestones: [Components.Schemas.Milestone]?

	@State private var assignees: [String] = []
	@State private var setLabels: [Int64] = []
	@State private var milestone: Int64?

	@State private var error: Error?

	private func load() async {
		async let labels = try? await Network.shared.client
			.issueListLabels(.init(path: .init(owner: owner, repo: repo)))
			.ok.body.json

		async let milestones = try? await Network.shared.client
			.issueGetMilestonesList(.init(path: .init(owner: owner, repo: repo)))
			.ok.body.json

		async let users = try? await Network.shared.client
			.repoGetAssignees(path: .init(owner: owner, repo: repo))
			.ok.body.json

		self.labels = await labels
		self.milestones = await milestones
		self.users = await users
	}

	private func create() async {
		do {
			_ = try await Network.shared.client.issueCreateIssue(
				.init(
					path: .init(owner: owner, repo: repo),
					body: .json(
						.init(
							assignees: assignees.isEmpty ? nil : assignees,
							body: content.isEmpty ? nil : content,
							dueDate: setDueDate ? dueDate : nil,
							labels: setLabels.isEmpty ? nil : setLabels,
							milestone: milestone,
							title: title
						))))

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
					HighlightedTextEditor(text: $content, highlightRules: .markdown)
						.frame(minHeight: 100)
				}
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
			}

			if let labels, labels.isNotEmpty {
				Section {
					ForEach(labels, id: \.id) { label in
						Button {
							if setLabels.contains(label.id) {
								setLabels.removeAll { $0 == label.id }
							} else {
								setLabels.append(label.id)
							}
						} label: {
							HStack {
								Circle()
									.fill(Color(hex: label.color))
									.frame(width: 12, height: 12)
								Text(label.name.emojized())
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
							Text(milestone.title.emojized()).tag(milestone.id)
						}
					}
				}
			}

			Section {
				Toggle("Set due date", isOn: $setDueDate)
				if setDueDate {
					DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
				}
			}
		}.task {
			await load()
		}.toolbar {
			AsyncButton("Save", systemImage: "checkmark") {
				await create()
			}.buttonStyle(.borderedProminent)
		}
		.scrollDismissesKeyboard(.immediately)
		.navigationTitle("New Issue")
	}
}

#Preview {
	NavigationStack {
		NewIssueView(owner: "Tanuki", repo: "gitea-ios")
	}
}
