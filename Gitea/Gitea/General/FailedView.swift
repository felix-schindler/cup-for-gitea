//
//  FailedView.swift
//  cup-gitea
//
//  Created by Felix Schindler on 04.09.25.
//

import SwiftUI

struct FailedView: View {
	private let msg: String
	private let icon: String

	init(_ error: Error) {
		self.icon = "exclamationmark.triangle"
		self.msg = error.localizedDescription
	}

	init(
		_ message: String = "Failed to load. Please make sure you're connected to the internet.",
		icon: String = "exclamationmark.triangle"
	) {
		self.msg = message
		self.icon = icon
	}

	public var body: some View {
		NoContentView(msg, systemImage: icon)
			.foregroundStyle(.red)
	}
}
