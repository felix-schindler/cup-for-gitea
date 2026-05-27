//
//  ActionView.swift
//  Gitea
//
//  Created by Felix Schindler on 27.05.26.
//

import SwiftUI

struct ActionView: View {
	private let run: Components.Schemas.ActionWorkflowRun
	private let owner: String
	private let repo: String

	@State private var jobsState = LoadState<[Components.Schemas.ActionWorkflowJob]>.loading
	@State private var artifactsState = LoadState<[Components.Schemas.ActionArtifact]>.loading

	init(run: Components.Schemas.ActionWorkflowRun, owner: String, repo: String) {
		self.run = run
		self.owner = owner
		self.repo = repo
	}

	private var statusLabel: String {
		if run.conclusion.isNotEmpty { return run.conclusion }
		return run.status
	}

	private var statusIcon: String {
		if run.conclusion == "success" { return Icons.actionsSuccess.rawValue }
		if run.conclusion == "failure" { return Icons.actionsFailure.rawValue }
		if run.conclusion == "cancelled" { return Icons.actionsCancelled.rawValue }
		if run.status == "in_progress" { return Icons.actionsInProgress.rawValue }
		if run.status == "queued" || run.status == "pending" { return Icons.actionsPending.rawValue }
		return Icons.actions.rawValue
	}

	private var statusColor: Color {
		if run.conclusion == "success" { return .green }
		if run.conclusion == "failure" { return .red }
		if run.conclusion == "cancelled" || run.conclusion == "skipped" { return .gray }
		if run.status == "in_progress" { return .orange }
		if run.status == "queued" || run.status == "pending" { return .yellow }
		return .primary
	}

	private var duration: String {
		guard run.completedAt > run.startedAt else { return "In progress..." }
		let interval = run.completedAt.timeIntervalSince(run.startedAt)
		let formatter = DateComponentsFormatter()
		formatter.allowedUnits = [.hour, .minute, .second]
		formatter.unitsStyle = .abbreviated
		return formatter.string(from: interval) ?? ""
	}

	private var shortSha: String {
		String(run.headSha.prefix(7))
	}

	private func loadJobs() async {
		jobsState = await LoadState {
			try await Network.shared.client.listWorkflowRunJobs(
				path: .init(owner: owner, repo: repo, run: Int(run.id)),
				query: .init(page: 1, limit: 50)
			).ok.body.json.jobs
		}
	}

	private func loadArtifacts() async {
		artifactsState = await LoadState {
			try await Network.shared.client.getArtifactsOfRun(
				path: .init(owner: owner, repo: repo, run: Int(run.id))
			).ok.body.json.artifacts
		}
	}

	var body: some View {
		List {
			Section {
				VStack(alignment: .leading, spacing: 12) {
					HStack {
						PillView(verbatim: statusLabel.capitalized, systemImage: statusIcon, bgColor: statusColor.opacity(0.2), fgColor: statusColor)
						Spacer()
						Text("#\(run.runNumber)")
							.font(.caption)
							.foregroundStyle(.secondary)
							.monospacedDigit()
					}

					Text(run.displayTitle)
						.font(.title2)
						.fontWeight(.semibold)

					HStack {
						Label(run.headBranch, systemImage: "arrow.triangle.branch")
							.font(.caption)
						Spacer()
						Text(shortSha)
							.font(.caption)
							.monospaced()
							.foregroundStyle(.secondary)
					}

					HStack(spacing: 4) {
						SmallUserView(run.actor, showUsername: true)
						Spacer()
						PillView(verbatim: run.event, bgColor: Color(.systemGray5), fgColor: .secondary)
					}

					Divider()

					LabeledContent("Started", value: run.startedAt.toString(timeStyle: .short))
					if run.completedAt > run.startedAt {
						LabeledContent("Completed", value: run.completedAt.toString(timeStyle: .short))
					}
					LabeledContent("Duration", value: duration)
				}
			}

			Section("Jobs") {
				switch jobsState {
				case .loading:
					LoadingView("Loading jobs", systemImage: Icons.actions.rawValue)
				case .loaded(let jobs):
					if jobs.isEmpty {
						NoContentView("No jobs", systemImage: Icons.actions.rawValue)
					} else {
						ForEach(jobs, id: \.id) { job in
							ActionsJobView(job: job)
						}
					}
				case .failed(let failure):
					FailedView(failure)
				}
			}

			if case .loaded(let artifacts) = artifactsState, artifacts.isNotEmpty {
				Section {
					DisclosureGroup("Artifacts (\(artifacts.count))") {
						ForEach(artifacts, id: \.id) { artifact in
							if let url = URL(string: artifact.archiveDownloadUrl) {
								Link(
									destination: url,
									label: {
										Label(
											"\(artifact.name) (\(ByteFormatter.shared.format(artifact.sizeInBytes)))",
											systemImage: "square.and.arrow.down"
										)
									}
								)
							} else {
								Text(artifact.name)
							}
						}
					}
				}
			}
		}
		.task {
			await loadJobs()
		}
		.task {
			await loadArtifacts()
		}
		.navigationTitle("Run #\(run.runNumber)")
		.navigationBarTitleDisplayMode(.inline)
	}
}

private struct ActionsJobView: View {
	let job: Components.Schemas.ActionWorkflowJob

	private var statusIcon: String {
		if job.conclusion == "success" { return Icons.actionsSuccess.rawValue }
		if job.conclusion == "failure" { return Icons.actionsFailure.rawValue }
		if job.conclusion == "cancelled" { return Icons.actionsCancelled.rawValue }
		if job.status == "in_progress" { return Icons.actionsInProgress.rawValue }
		if job.status == "queued" || job.status == "pending" { return Icons.actionsPending.rawValue }
		return Icons.actions.rawValue
	}

	private var statusColor: Color {
		if job.conclusion == "success" { return .green }
		if job.conclusion == "failure" { return .red }
		if job.conclusion == "cancelled" || job.conclusion == "skipped" { return .gray }
		if job.status == "in_progress" { return .orange }
		if job.status == "queued" || job.status == "pending" { return .yellow }
		return .primary
	}

	var body: some View {
		DisclosureGroup {
			ForEach(job.steps, id: \.number) { step in
				HStack {
					Image(systemName: step.conclusion == "success" ? Icons.actionsSuccess.rawValue
						: step.conclusion == "failure" ? Icons.actionsFailure.rawValue
						: step.conclusion == "cancelled" ? Icons.actionsCancelled.rawValue
						: step.status == "in_progress" ? Icons.actionsInProgress.rawValue
						: Icons.actionsPending.rawValue)
						.foregroundStyle(step.conclusion == "success" ? .green
							: step.conclusion == "failure" ? .red
							: step.conclusion == "cancelled" ? .gray
							: step.status == "in_progress" ? .orange
							: .yellow)
						.font(.caption)
					Text(step.name)
						.font(.callout)
					Spacer()
					if step.completedAt > step.startedAt {
						Text(duration(from: step.startedAt, to: step.completedAt))
							.font(.caption2)
							.foregroundStyle(.secondary)
							.monospacedDigit()
					}
				}
				.padding(.leading, 8)
			}
		} label: {
			HStack {
				Image(systemName: statusIcon)
					.foregroundStyle(statusColor)
				Text(job.name)
					.font(.subheadline)
					.fontWeight(.medium)
				Spacer()
				if job.conclusion.isNotEmpty {
					Text(job.conclusion.capitalized)
						.font(.caption2)
						.foregroundStyle(statusColor)
				} else {
					Text(job.status.capitalized)
						.font(.caption2)
						.foregroundStyle(statusColor)
				}
			}
		}
	}

	private func duration(from start: Date, to end: Date) -> String {
		let interval = end.timeIntervalSince(start)
		let formatter = DateComponentsFormatter()
		formatter.allowedUnits = [.minute, .second]
		formatter.unitsStyle = .positional
		formatter.zeroFormattingBehavior = .pad
		return formatter.string(from: interval) ?? ""
	}
}
