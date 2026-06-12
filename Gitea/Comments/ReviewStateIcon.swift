//
//  ReviewStateIcon.swift
//  Gitea
//
//  Created by Felix Schindler on 12.06.26.
//

import SwiftUI

struct ReviewStateIcon: View {
	let state: Components.Schemas.PullReview.StatePayload

	private var icon: String {
		switch state {
		case .approved: "checkmark.circle"
		case .pending: "clock"
		case .comment: "bubble.left"
		case .requestChanges: "pencil"
		case .requestReview: "person"
		}
	}

	private var color: Color {
		switch state {
		case .approved: .green
		case .pending: .yellow
		case .comment: .blue
		case .requestChanges: .orange
		case .requestReview: .purple
		}
	}

	private var label: String {
		switch state {
		case .approved: "Approved"
		case .pending: "Pending"
		case .comment: "Commented"
		case .requestChanges: "Changes Requested"
		case .requestReview: "Review Requested"
		}
	}

	var body: some View {
		Label(label, systemImage: icon)
			.foregroundStyle(color)
	}
}
