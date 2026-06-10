//
//  ActionsJobView.swift
//  Gitea
//
//  Created by Felix Schindler on 06.06.26.
//

import SwiftUI

struct ActionsJobView: View {
	let job: Components.Schemas.ActionWorkflowJob

	private var status: ActionStatus {
		ActionStatus(conclusion: job.conclusion, status: job.status)
	}

	var body: some View {
		DisclosureGroup {
			ForEach(job.steps, id: \.number) { step in
				Label(
					title: {
						HStack {
							Text(step.name)
								.font(.callout)
							if step.completedAt > step.startedAt {
								Spacer()
								Text(duration(from: step.startedAt, to: step.completedAt))
									.font(.footnote)
									.foregroundStyle(.secondary)
									.monospacedDigit()
							}
						}
					},
					icon: {
						let stepStatus = ActionStatus(conclusion: step.conclusion, status: step.status)
						Image(systemName: stepStatus.icon)
							.foregroundStyle(stepStatus.color)
							.font(.footnote)
							.accessibilityLabel(stepStatus.label)
					})
			}
		} label: {
			Label(title: {
				Text(job.name)
			}) {
				Image(systemName: status.icon)
					.foregroundStyle(status.color)
					.accessibilityLabel(status.label)
			}.fontWeight(.medium)
		}
	}

	private func duration(from start: Date, to end: Date) -> String {
		guard end >= start else { return "--" }
		let interval = end.timeIntervalSince(start)
		let formatter = DateComponentsFormatter()
		formatter.allowedUnits = [.minute, .second]
		formatter.unitsStyle = .positional
		formatter.zeroFormattingBehavior = .pad
		return formatter.string(from: interval) ?? "--"
	}
}
