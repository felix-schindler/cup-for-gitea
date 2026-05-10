//
//  HapticFeedback.swift
//  Gitea
//
//  Created by Felix Schindler on 10.05.26.
//

import UIKit

@MainActor
class HapticFeedback {
	static func play(_ feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle) {
		UIImpactFeedbackGenerator(style: feedbackStyle).impactOccurred()
	}

	static func notify(_ feedbackType: UINotificationFeedbackGenerator.FeedbackType) {
		UINotificationFeedbackGenerator().notificationOccurred(feedbackType)
	}
}
