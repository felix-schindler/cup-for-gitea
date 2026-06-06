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

	private var status: ActionStatus {
		ActionStatus(conclusion: run.conclusion ?? "", status: run.status)
	}

	var body: some View {
		Label(
			title: {
				VStack(alignment: .leading) {
					HStack {
						Text(run.displayTitle)
							.font(.subheadline)
							.fontWeight(.medium)
							.lineLimit(1)
						Spacer()
						Text("#\(run.runNumber)")
							.font(.footnote)
							.foregroundStyle(.secondary)
							.monospacedDigit()
					}

					ScrollView(.horizontal) {
						HStack {
							PillView(verbatim: run.event)
							if let headBranch = run.headBranch {
								PillView(verbatim: headBranch)
							}
							Spacer()
							Text(run.startedAt.toString(timeStyle: .short))
								.font(.caption2)
								.foregroundStyle(.secondary)
						}.font(.footnote)
					}
				}
			},
			icon: {
				Image(systemName: status.icon)
					.foregroundStyle(status.color)
			})
	}
}
