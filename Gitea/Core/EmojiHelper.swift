//
//  EmojiCodes.swift
//  GitLab
//
//  Created by Felix Schindler on 02.11.21.
//

import Foundation

class EmojiHelper {
	private static let emojiCodes: [String: String] = {
		guard let url = Bundle.main.url(forResource: "emoji", withExtension: "json"),
			let data = try? Data(contentsOf: url),
			let codes = try? JSONDecoder().decode([String: String].self, from: data)
		else {
			print("WARNING: Failed to load emoji.json")
			return [:]
		}
		return codes
	}()

	public static func emojizedStringWithString(text: String) -> String {
		var resultText = text
		do {
			let regex = try NSRegularExpression(
				pattern: "(:[a-z0-9-+_]+:)", options: .caseInsensitive)
			let matchingRange = NSMakeRange(0, resultText.count)
			regex.enumerateMatches(
				in: resultText, options: .reportCompletion,
				range: matchingRange,
				using: {
					(
						result: NSTextCheckingResult!,
						flags: NSRegularExpression.MatchingFlags,
						stop: UnsafeMutablePointer<ObjCBool>
					) -> Void in
					if (result != nil)
						&& (result.resultType == .regularExpression)
					{
						let range = result.range
						if range.location != NSNotFound {
							let code = (text as NSString).substring(with: range)
							let unicode = EmojiHelper.emojiAliases(key: code)
							if unicode.isNotEmpty {
								resultText = resultText.replacingOccurrences(
									of: code, with: unicode)
							}
						}
					}
				})
		} catch {
			print("RegExp error")
		}

		return resultText
	}

	public static func emojiAliases(key: String) -> String {
		var value: String?
		let regex = try! NSRegularExpression(
			pattern: "(:[a-z0-9-+_]+:)", options: .caseInsensitive)

		if regex.firstMatch(
			in: key, options: [], range: NSMakeRange(0, key.utf8.count)) != nil
		{
			value = emojiCodes[key]
		}

		return value ?? key
	}
}
