//
//  NamespaceLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 11.05.26.
//

import SwiftUI

struct NamespaceLoader: View {
	let owner: String
	@State private var org: Result<Components.Schemas.Organization, Error>? = nil

	init(_ owner: String) {
		self.owner = owner
	}

	private func load() async {
		do {
			let org = try await Network.shared.client.orgGet(path: .init(org: owner)).ok.body.json
			self.org = .success(org)
		} catch {
			self.org = .failure(error)
		}
	}

	var body: some View {
		VStack {
			if let org {
				switch org {
				case .success(let success):
					OrgView(org: success)
				case .failure:
					UserLoader(username: owner)
				}
			} else {
				LoadingView("Loading namespace", systemImage: "person.3")
			}
		}.task {
			await load()
		}
	}
}

#Preview {
	VStack(alignment: .leading) {
		NamespaceLoader("Tanuki")
		NamespaceLoader("felix-schindler")
	}
}
