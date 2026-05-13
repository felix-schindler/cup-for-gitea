//
//  SmallLabelView.swift
//  Gitea
//
//  Created by Felix Schindler on 13.05.26.
//

import SwiftUI

struct SmallLabelView: View {
	let label: Components.Schemas.Label

	var body: some View {
		HStack(spacing: 6) {
			Circle()
				.fill(Color(hex: label.color))
				.frame(width: 12, height: 12)
			Text(label.name.emojized())
		}
	}
}
