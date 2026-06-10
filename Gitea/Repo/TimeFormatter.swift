//
//  TimeFormatter.swift
//  Gitea
//
//  Created by Felix Schindler on 10.06.26.
//

import Foundation

@MainActor
class TimeFormatter {
	static let shared = TimeFormatter()
	private let formatter: DateComponentsFormatter

	private init() {
		self.formatter = DateComponentsFormatter()
		self.formatter.allowedUnits = [.hour, .minute]
		self.formatter.unitsStyle = .abbreviated
		self.formatter.zeroFormattingBehavior = .dropTrailing
	}

	func format(_ seconds: Int64) -> String {
		formatter.string(from: TimeInterval(seconds)) ?? "0m"
	}
}
