//
//  AvatarImage.swift
//  GitLab
//
//  Created by Felix Schindler on 10.06.23.
//

import CachedAsyncImage
import SwiftUI

enum AvatarSize {
	case tiny,
		small,
		medium,
		big
}

struct AvatarImage: View {
	private let url: URL

	private let radius: CGFloat
	private let width: CGFloat
	private let height: CGFloat

	private var request: URLRequest {
		var req = URLRequest(url: self.url)
		req.setValue("token \(Network.shared.token ?? "")", forHTTPHeaderField: "Authorization")
		return req
	}

	public init(
		_ url: URL, radius: CGFloat = 10, width: CGFloat = 50,
		height: CGFloat = 50
	) {
		self.url = url
		self.radius = radius
		self.width = width
		self.height = height
	}

	public init(_ url: URL, size: AvatarSize) {
		self.url = url

		switch size {
		case .tiny:
			self.radius = 5
			self.width = 17.5
			self.height = 17.5
		case .small:
			self.radius = 5
			self.width = 25
			self.height = 25
		case .medium:
			self.radius = 7.5
			self.width = 37.5
			self.height = 37.5
		case .big:
			self.radius = 10
			self.width = 50
			self.height = 50
		}
	}

	public var body: some View {
		CachedAsyncImage(urlRequest: self.request, urlCache: .avatarCache) { phase in
			switch phase {
			case .empty:
				ProgressView()
			case .success(let image):
				image
					.resizable()
					.scaledToFit()
					.cornerRadius(self.radius)
			case .failure:
				Image(systemName: "exclamationmark.triangle")
					.resizable()
					.scaledToFit()
			@unknown default:
				EmptyView()
			}
		}.frame(width: width, height: height, alignment: .leading)
	}
}

#Preview {
	VStack {
		AvatarImage(
			URL(
				string:
					"https://gitlab.com/uploads/-/system/project/avatar/33025310/Tanuki-200kb.png"
			)!, size: .tiny)
		AvatarImage(
			URL(
				string:
					"https://gitlab.com/uploads/-/system/project/avatar/33025310/Tanuki-200kb.png"
			)!, size: .small)
		AvatarImage(
			URL(
				string:
					"https://gitlab.com/uploads/-/system/project/avatar/33025310/Tanuki-200kb.png"
			)!, size: .medium)
		AvatarImage(
			URL(
				string:
					"https://gitlab.com/uploads/-/system/project/avatar/33025310/Tanuki-200kb.png"
			)!, size: .big)
		AvatarImage(URL(string: "https://schindlerfelix.de/favicon.ico")!)
		AvatarImage(
			URL(string: "https://gitlab.com/uploads/-/system/project/avatar/39986149/flexbase.png")!
		)
		AvatarImage(
			URL(
				string:
					"https://gitlab.com/uploads/-/system/user/avatar/9005085/avatar.png"
			)!)
	}
}
