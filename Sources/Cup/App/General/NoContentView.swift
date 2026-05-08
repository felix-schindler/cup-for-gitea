//
//  NoContentView.swift
//  cup-gitea
//
//  Created by Felix Schindler on 21.09.25.
//

import SwiftUI

/// Could be replaced by  `ContentUnavailableView` when iOS 16 support is dropped
struct NoContentView: View {
	private let msg: String
	private let systemImage: String
	private let description: String?

	init(_ message: String, systemImage: String, description: String? = nil) {
		self.msg = message
		self.systemImage = systemImage
		self.description = description
	}

	var body: some View {
		VStack {
			Image(systemName: systemImage)
				.resizable()
				.scaledToFill()
				.foregroundStyle(.secondary)
				.frame(width: 40, height: 40)
				.padding(.bottom, 10)
			Text(msg)
				.font(.title2.bold())
				.multilineTextAlignment(.center)
			if let description {
				Text(description)
					.font(.callout)
					.foregroundStyle(.secondary)
					.multilineTextAlignment(.center)
			}
		}
		.padding()
		.frame(maxWidth: .infinity, minHeight: 100)
	}
}
