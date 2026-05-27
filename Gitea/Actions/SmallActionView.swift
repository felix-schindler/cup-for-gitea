//
//  SmallActionView.swift
//  Gitea
//
//  Created by Felix Schindler on 27.05.26.
//

import SwiftUI

struct SmallActionView: View {
	private let run: Components.Schemas.ActionWorkflowRun

	init(_ run: Components.Schemas.ActionWorkflowRun) {
		self.run = run
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

	var body: some View {
		HStack(spacing: 12) {
			Image(systemName: statusIcon)
				.foregroundStyle(statusColor)
				.font(.title3)

			VStack(alignment: .leading, spacing: 4) {
				HStack {
					Text(run.displayTitle)
						.font(.subheadline)
						.fontWeight(.medium)
						.lineLimit(1)
					Spacer()
					Text("#\(run.runNumber)")
						.font(.caption)
						.foregroundStyle(.secondary)
						.monospacedDigit()
				}

				HStack(spacing: 6) {
					PillView(verbatim: run.event, systemImage: nil, bgColor: Color(.systemGray5), fgColor: .secondary)
						.font(.caption2)

					Label(run.headBranch, systemImage: "arrow.triangle.branch")
						.font(.caption2)
						.foregroundStyle(.secondary)

					Spacer()

					Text(run.startedAt.toString(timeStyle: .short))
						.font(.caption2)
						.foregroundStyle(.secondary)
				}
			}
		}
		.padding(.vertical, 2)
	}
}
