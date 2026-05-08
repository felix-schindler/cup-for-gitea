//
//  LoadingView.swift
//  cup-gitea
//
//  Created by Felix Schindler on 21.09.25.
//

import SwiftUI

struct LoadingView: View {
	private let msg: String
	private let systemImage: String
	private let color: Color

	init(_ message: String, systemImage: String, color: Color = .secondary) {
		self.msg = message
		self.systemImage = systemImage
		self.color = color
	}

	var body: some View {
		VStack {
			ProgressView(label: {
				Label(
					title: {
						Text(msg)
					},
					icon: {
						Image(systemName: systemImage)
							.foregroundStyle(color)
					})
			})
		}.frame(maxWidth: .infinity, minHeight: 100)
	}
}
