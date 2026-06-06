import SwiftUI

struct ContributionGraphView: View {
	let data: [Components.Schemas.UserHeatmapData]

	private let columns = 53
	private let cellSize: CGFloat = 10
	private let spacing: CGFloat = 2

	private var calendar: Calendar {
		Calendar.current
	}

	private var contributionsByDate: [Date: Int] {
		Dictionary(
			data.map { entry in
				let date = Date(timeIntervalSince1970: TimeInterval(entry.timestamp))
				let day = calendar.startOfDay(for: date)
				return (day, Int(entry.contributions))
			}, uniquingKeysWith: +)
	}

	private var endDate: Date {
		let today = calendar.startOfDay(for: Date())
		let weekday = calendar.component(.weekday, from: today)
		let daysToSaturday = (8 - weekday) % 7
		return calendar.date(byAdding: .day, value: daysToSaturday == 0 ? 0 : daysToSaturday, to: today) ?? today
	}

	private var startDate: Date {
		let totalDays = columns * 7 - 1
		return calendar.date(byAdding: .day, value: -totalDays, to: endDate) ?? endDate
	}

	private var maxContributions: Int {
		max(contributionsByDate.values.max() ?? 0, 1)
	}

	private var totalContributions: Int {
		data.reduce(0) { $0 + Int($1.contributions) }
	}

	private let cellColors: [Color] = [
		Color(.systemGray6),
		Color.green.opacity(0.3),
		Color.green.opacity(0.5),
		Color.green.opacity(0.7),
		Color.green.opacity(1.0),
	]

	private func color(for count: Int) -> Color {
		guard count > 0 else { return cellColors[0] }
		let bucket: Int
		switch maxContributions {
		case 1: bucket = 4
		case 2: bucket = count == 1 ? 2 : 4
		case 3: bucket = count == 1 ? 2 : count == 2 ? 3 : 4
		default:
			let ratio = Double(count) / Double(maxContributions)
			bucket = ratio < 0.25 ? 1 : ratio < 0.5 ? 2 : ratio < 0.75 ? 3 : 4
		}
		return cellColors[bucket]
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			(Text("\(totalContributions)")
				.foregroundStyle(.primary)
				+ Text(" contributions in the last year")
				.foregroundStyle(.secondary))
				.font(.footnote)

			ScrollView(.horizontal, showsIndicators: false) {
				ScrollViewReader { proxy in
					HStack(alignment: .top, spacing: 0) {
						dayLabels
						VStack(alignment: .leading, spacing: 2) {
							monthLabels
							grid
						}
					}
					.fixedSize()
					.onAppear {
						proxy.scrollTo(columns - 1, anchor: .trailing)
					}
				}
			}
		}
		.padding(.vertical, 4)
	}

	private var monthLabels: some View {
		let cellWidth = cellSize + spacing
		let intervals = 4

		return HStack(spacing: spacing) {
			ForEach(Array(stride(from: 0, to: columns, by: intervals).enumerated()), id: \.offset) { _, col in
				if let weekStart = calendar.date(byAdding: .day, value: col * 7, to: startDate) {
					let month = calendar.component(.month, from: weekStart)
					Text(DateFormatter().shortMonthSymbols[month - 1])
						.font(.system(size: 8))
						.foregroundStyle(.secondary)
						.frame(width: cellWidth * CGFloat(min(intervals, columns - col)), alignment: .leading)
				}
			}
		}
		.padding(.leading, 24)
	}

	private var dayLabels: some View {
		let labels = ["Mon", "", "Wed", "", "Fri", ""]
		return VStack(spacing: spacing) {
			Color.clear.frame(height: 8)
			ForEach(labels, id: \.self) { label in
				if label.isNotEmpty {
					Text(label)
						.font(.system(size: 7))
						.foregroundStyle(.tertiary)
						.frame(height: cellSize)
				} else {
					Color.clear.frame(height: cellSize)
				}
			}
		}
		.frame(width: 22)
	}

	private var grid: some View {
		HStack(spacing: spacing) {
			ForEach(0..<columns, id: \.self) { col in
				VStack(spacing: spacing) {
					ForEach(0..<7, id: \.self) { row in
						let dayOffset = col * 7 + row
						if let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate),
							date <= endDate
						{
							let count = contributions(for: date)
							RoundedRectangle(cornerRadius: 2)
								.fill(color(for: count))
								.frame(width: cellSize, height: cellSize)
						}
					}
				}
				.id(col)
			}
		}
	}

	private func contributions(for date: Date) -> Int {
		contributionsByDate[calendar.startOfDay(for: date)] ?? 0
	}
}
