//
//  Extensions.swift
//  cup-gitea
//
//  Created by Felix Schindler on 09.05.26.
//

import SwiftUI

extension String {
	var isNotEmpty: Bool {
		!self.isEmpty
	}

	func emojized() -> String {
		return EmojiHelper.emojizedStringWithString(text: self)
	}
}

extension Array {
	var isNotEmpty: Bool {
		!self.isEmpty
	}
}

extension Date {
	func toString(
		_ dateStyle: DateFormatter.Style = .medium,
		timeStyle: DateFormatter.Style = .none
	) -> String {
		let dateFormat = DateFormatter()
		dateFormat.dateStyle = dateStyle
		dateFormat.timeStyle = timeStyle
		return dateFormat.string(from: self)
	}
}

extension URLCache {
	static let avatarCache = URLCache(
		memoryCapacity: 100 * 1024 * 1024,  // 100 MB in RAM
		diskCapacity: 300 * 1024 * 1024  // 300 MB on disk
	)
}

extension View {
	func modifier(@ViewBuilder _ closure: (Self) -> some View) -> some View {
		closure(self)
	}
}
