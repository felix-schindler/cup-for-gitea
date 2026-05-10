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

	private init(
		_ message: String,
		icon: String = "exclamationmark.triangle"
	) {
		self.msg = message
		self.icon = icon
	}

	public var body: some View {
		NoContentView(LocalizedStringResource(stringLiteral: msg), systemImage: icon)
			.foregroundStyle(.red)
	}
}
