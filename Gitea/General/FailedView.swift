//
//  FailedView.swift
//  cup-gitea
//
//  Created by Felix Schindler on 04.09.25.
//

import SwiftUI

struct FailedView: View {
	private let message: LocalizedStringResource
	private let description: LocalizedStringResource?
	private let icon: String

	init(_ error: Error) {
		self.message = LocalizedStringResource(stringLiteral: error.userDescription)
		self.description = nil
		self.icon = "exclamationmark.triangle"
	}

	init(
		_ message: LocalizedStringResource,
		icon: String = "exclamationmark.triangle",
		description: LocalizedStringResource? = nil
	) {
		self.message = message
		self.description = description
		self.icon = icon
	}

	public var body: some View {
		NoContentView(message, systemImage: icon, description: description)
			.foregroundStyle(.red)
	}
}
