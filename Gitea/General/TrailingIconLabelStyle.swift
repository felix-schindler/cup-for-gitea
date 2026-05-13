//
//  TrailingIconLabelStyle.swift
//  Gitea
//
//  Created by Felix Schindler on 13.05.26.
//

import SwiftUI

struct TrailingIconLabelStyle: LabelStyle {
	var useSpacer: Bool = true

	func makeBody(configuration: LabelStyleConfiguration) -> some View {
		HStack {
			configuration.title
				.multilineTextAlignment(.leading)
			if useSpacer {
				Spacer()
			}
			configuration.icon
		}
	}
}
