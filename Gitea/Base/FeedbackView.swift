//
//  FeedbackView.swift
//  Gitea
//
//  Created by Felix Schindler on 26.05.26.
//

import SwiftUI

struct FeedbackView: View {
	@Environment(\.dismiss) private var dismiss

	@State
	private var email = ""

	@State
	private var desc = "\n"

	@State
	private var accepted = false

	@State
	private var alert: AlertInfo?

	private struct AlertInfo: Identifiable {
		let id = UUID()
		let title: String
		let message: String
		var dismissOnOk: Bool
	}

	private func submit() async {
		do {
			var request = URLRequest(
				url: URL(
					string: "https://pb.schindlerfelix.de/api/collections/cup_feedback/records"
				)!)
			request.httpMethod = "POST"
			request.setValue("application/json", forHTTPHeaderField: "Content-Type")
			request.httpBody = try JSONSerialization.data(withJSONObject: [
				"from": email,
				"text": desc,
			])

			let (_, response) = try await URLSession.shared.data(for: request)
			guard let httpResponse = response as? HTTPURLResponse,
				(200...299).contains(httpResponse.statusCode)
			else {
				throw URLError(.badServerResponse)
			}

			HapticFeedback.notify(.success)
			alert = AlertInfo(
				title: "Thank you!",
				message: "Your feedback has been submitted",
				dismissOnOk: true
			)
		} catch let error {
			HapticFeedback.notify(.error)
			alert = AlertInfo(
				title: "Failed to submit feedback",
				message: error.localizedDescription,
				dismissOnOk: false
			)
		}
	}

	var body: some View {
		VStack {
			List {
				TextField("Email address (optional)", text: $email)
					.keyboardType(.emailAddress)
					.autocorrectionDisabled()
					.textInputAutocapitalization(.never)
				VStack(alignment: .leading) {
					Text("Description")
						.foregroundStyle(.secondary)
						.font(.footnote)
					TextEditor(text: $desc)
				}
				Toggle(
					"I have read and accept the privacy information",
					isOn: $accepted
				)
			}.toolbar {
				AsyncButton("Submit", systemImage: "checkmark") {
					await submit()
				}
				.disabled(!accepted)
			}

			Link(
				"Privacy information \u{2197}",
				destination: URL(
					string: "https://schindlerfelix.de/projects/cup/privacy"
				)!
			)
			.padding()
		}
		.navigationTitle("Feedback")
		.alert(
			item: $alert
		) { alert in
			if alert.dismissOnOk {
				Alert(
					title: Text(alert.title),
					message: Text(alert.message),
					dismissButton: .default(Text("OK")) {
						dismiss()
					}
				)
			} else {
				Alert(
					title: Text(alert.title),
					message: Text(alert.message)
				)
			}
		}
	}
}

#Preview {
	NavigationView {
		FeedbackView()
	}
}
