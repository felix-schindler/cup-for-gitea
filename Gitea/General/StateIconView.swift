//
//  StateIconView.swift
//  Gitea
//
//  Created by Felix Schindler on 10.05.26.
//

import SwiftUI

struct StateIconView: View {
	let icon: String
	let color: Color
	
	init(_ _type: Components.Schemas.NotificationSubject._TypePayload, _ state: Components.Schemas.NotificationSubject.StatePayload) {
		self.icon = switch _type {
		case .issue:
			Icons.issues.rawValue
		case .pull:
			switch state {
			case .open:
				Icons.pull_requests.rawValue
			case .closed:
				Icons.pull_request_closed.rawValue
			case .merged:
				Icons.pull_request_merged.rawValue
			}
		case .commit:
			Icons.commits.rawValue
		case .repository:
			Icons.repositories.rawValue
		}

		self.color = switch state {
		case .open:
			.green
		case .closed:
			.red
		case .merged:
			.purple
		}
	}
	
	var body: some View {
		Image(systemName: self.icon)
			.foregroundStyle(self.color)
	}
}
