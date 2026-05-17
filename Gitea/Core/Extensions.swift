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

	@ViewBuilder
	func adaptiveButtonStyle() -> some View {
		if #available(iOS 26.0, *) {
			self.buttonStyle(.glass)
		} else {
			self.buttonStyle(.bordered)
		}
	}

	@ViewBuilder
	func adaptiveButtonStyleProminent() -> some View {
		if #available(iOS 26.0, *) {
			self.buttonStyle(.glassProminent)
		} else {
			self.buttonStyle(.borderedProminent)
		}
	}
}

extension Color {
	// Source - https://stackoverflow.com/a/56874327
	// Posted by kontiki, modified by community. See post 'Timeline' for change history
	// Retrieved 2026-04-14, License - CC BY-SA 4.0
	init(hex: String) {
		let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
		var int: UInt64 = 0
		Scanner(string: hex).scanHexInt64(&int)
		let a: UInt64
		let r: UInt64
		let g: UInt64
		let b: UInt64
		switch hex.count {
		case 3:  // RGB (12-bit)
			(a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
		case 6:  // RGB (24-bit)
			(a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
		case 8:  // ARGB (32-bit)
			(a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
		default:
			(a, r, g, b) = (1, 1, 1, 0)
		}

		self.init(
			.sRGB,
			red: Double(r) / 255,
			green: Double(g) / 255,
			blue: Double(b) / 255,
			opacity: Double(a) / 255
		)
	}

	var hex: String {
		guard let components = cgColor?.components, components.count >= 3 else {
			return "#000000"
		}
		let r = Int(components[0] * 255)
		let g = Int(components[1] * 255)
		let b = Int(components[2] * 255)
		let a = components.count >= 4 ? Int(round(components[3] * 255)) : 255
		return String(format: "#%02X%02X%02X%02X", r, g, b, a)
	}

	func adaptiveText() -> Color {
		guard let components = cgColor?.components else { return .black }
		let red = components[0]
		let green = components[1]
		let blue = components[2]
		let brightness = red * 0.299 + green * 0.587 + blue * 0.114
		return brightness > 0.5 ? .black : .white
	}
}
