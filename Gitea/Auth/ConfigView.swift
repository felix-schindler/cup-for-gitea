//
//  ConfigView.swift
//  Gitea
//
//  Created by Felix Schindler on 12.05.26.
//

import SwiftUI

struct ConfigView: View {
	@Environment(\.dismiss) var dismiss

	public private(set) var showSetup: Binding<Bool>? = nil

	@State private var newHost = "gitea.com"
	@State private var newToken = ""
	@State private var errorMessage: LocalizedStringKey?

	private func sanitizeHost(_ input: String) -> String {
		let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
		if trimmed.contains("/") {
			if let tempUrl = URL(string: trimmed), let host = tempUrl.host {
				return host
			}
		}
		return trimmed
	}

	var body: some View {
		Form {
			if let errorMessage {
				Section {
					Text(errorMessage)
						.foregroundStyle(.red)
						.font(.footnote)
						.multilineTextAlignment(.center)
				}
			}

			Section(
				content: {
					TextField("gitea.example.com", text: $newHost)
						.keyboardType(.URL)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
				},
				header: {
					Label("Gitea URL", systemImage: "link")
				})

			Section(
				content: {
					TextField("77eabb36d04f1c5c32cd609b8b44c6b3", text: $newToken)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
				},
				header: {
					Label("Access Token", systemImage: "key")
				})

			Section(
				content: {
					VStack(alignment: .leading) {
						Text("activitypub    no access")
						Text("issue          read and write")
						Text("misc           read")
						Text("notification   read and write")
						Text("organization   read and write")
						Text("package        read")
						Text("repository     read and write")
						Text("user           read and write")
					}.monospaced()
				},
				header: {
					Label("Scopes", systemImage: "checkmark.circle.fill")
				})
		}.toolbar {
			AsyncButton("Save") {
				errorMessage = nil
				let host = sanitizeHost(newHost)
				guard host.isNotEmpty else {
					errorMessage = "Please provide a valid host"
					return
				}
				guard newToken.isNotEmpty else {
					errorMessage = "Please provide a valid token"
					return
				}

				do {
					let instance = GiteaInstance(host: host, token: newToken)
					try await Auth.login(
						instance: instance,
						showSetup: showSetup,
						dismiss: dismiss
					)
				} catch {
					errorMessage = "Failed to log in: \(error.localizedDescription)"
				}
			}.buttonStyle(.borderedProminent)
		}
		.scrollDismissesKeyboard(.immediately)
		.navigationTitle("Configure instance")
	}
}

#Preview {
	NavigationStack {
		ConfigView(showSetup: .constant(true))
	}
}
