//
//  UserVisibilityIcon.swift
//  Gitea
//
//  Created by Felix Schindler on 11.05.26.
//

import SwiftUI

struct VisibilityIcon: View {
	private let systemName: String

	init(_ visibility: String) {
		self.systemName =
			switch visibility {
			case "private":
				"lock"
			case "limited":
				"network.badge.shield.half.filled"
			default:
				"network"
			}
	}

	var body: some View {
		Image(systemName: systemName)
	}
}
