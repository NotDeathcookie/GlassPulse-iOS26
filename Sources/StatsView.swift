import Charts
import SwiftData
import SwiftUI

struct DailyCategoryMinutes: Identifiable {
    let id = UUID()
    let dayLabel: String
    let date: Date
    let category: String
    let minutes: Int
}

@MainActor
struct StatsView: View {
    var motionManager: MotionManager

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FocusSessionRecord.completedAt, order: .reverse)
    private var sessions: [FocusSessionRecord]

    private var totalMinutes: Int {
        sessions.reduce(0) { $0 + max(1, $1.durationSeconds / 60) }
    }

    private var currentStreakDays: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(sessions.map { calendar.startOfDay(for: $0.completedAt) })
        var streak = 0
        var checkDay = calendar.startOfDay(for: .now)
        if !uniqueDays.contains(checkDay),
           let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDay),
           uniqueDays.contains(yesterday) {
            checkDay = yesterday
        }
        while uniqueDays.contains(checkDay) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDay) else { break }
            checkDay = prev
        }
        return streak
    }

    private var weeklyChartData: [DailyCategoryMinutes] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        var items: [DailyCategoryMinutes] = []
        for offset in (0..<7).reversed() {
            guard let dayStart = calendar.date(byAdding: .day, value: -offset, to: today),
                  let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { continue }
            let label = formatter.string(from: dayStart)
            let daySessions = sessions.filter { $0.completedAt >= dayStart && $0.completedAt < dayEnd }

            for cat in SessionCategory.allCases {
                let mins = daySessions
                    .filter { $0.category == cat.rawValue }
                    .reduce(0) { $0 + max(1, $1.durationSeconds / 60) }
                items.append(DailyCategoryMinutes(dayLabel: label, date: dayStart, category: cat.rawValue, minutes: mins))
            }
        }
        return items
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedAuroraBackdrop(
                    accent: .mint,
                    pitch: motionManager.pitch,
                    roll: motionManager.roll
                )

                ScrollView {
                    VStack(spacing: 18) {
                        // Summary Metrics Row
                        HStack(spacing: 12) {
                            metricCard(title: "Streak", value: "\(currentStreakDays)d", icon: "flame.fill", tint: .orange)
                            metricCard(title: "Sessions", value: "\(sessions.count)", icon: "checkmark.seal.fill", tint: .cyan)
                            metricCard(title: "Focus Time", value: "\(totalMinutes)m", icon: "clock.fill", tint: .mint)
                        }

                        // Swift Charts 7-Day Breakdown
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("Last 7 Days by Category", systemImage: "chart.bar.fill")
                                    .font(.headline)
                                Spacer()
                                Button("Seed Demo") {
                                    seedSampleSessions()
                                }
                                .font(.caption.weight(.semibold))
                                .buttonStyle(.glass)
                            }

                            Chart(weeklyChartData) { entry in
                                BarMark(
                                    x: .value("Day", entry.dayLabel),
                                    y: .value("Minutes", entry.minutes)
                                )
                                .foregroundStyle(by: .value("Category", entry.category))
                                .cornerRadius(6)
                            }
                            .chartForegroundStyleScale([
                                SessionCategory.code.rawValue: SessionCategory.code.color,
                                SessionCategory.study.rawValue: SessionCategory.study.color,
                                SessionCategory.workout.rawValue: SessionCategory.workout.color,
                                SessionCategory.design.rawValue: SessionCategory.design.color
                            ])
                            .frame(height: 210)
                        }
                        .padding(18)
                        .glassEffect(.regular, in: .rect(cornerRadius: 24))

                        // Recent Session Log
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Sessions (SwiftData)")
                                .font(.headline)

                            if sessions.isEmpty {
                                Text("Complete a focus session or tap 'Seed Demo' above to preview your weekly chart.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .padding(.vertical, 8)
                            } else {
                                ForEach(sessions.prefix(15)) { record in
                                    let cat = SessionCategory(rawValue: record.category) ?? .code
                                    HStack(spacing: 12) {
                                        Image(systemName: cat.icon)
                                            .font(.subheadline.weight(.bold))
                                            .foregroundStyle(cat.color)
                                            .frame(width: 34, height: 34)
                                            .background(cat.color.opacity(0.18), in: .circle)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(record.category)
                                                .font(.subheadline.weight(.semibold))
                                            Text(record.completedAt.formatted(date: .abbreviated, time: .shortened))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()

                                        Text("\(max(1, record.durationSeconds / 60)) min")
                                            .font(.subheadline.monospacedDigit().weight(.bold))
                                            .foregroundStyle(cat.color)

                                        Button(role: .destructive) {
                                            modelContext.delete(record)
                                            try? modelContext.save()
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.caption)
                                        }
                                        .buttonStyle(.borderless)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .padding(18)
                        .glassEffect(.regular, in: .rect(cornerRadius: 24))
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func metricCard(title: String, value: String, icon: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
            Text(value)
                .font(.title3.monospacedDigit().weight(.bold))
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private func seedSampleSessions() {
        let calendar = Calendar.current
        let samples: [(Int, SessionCategory, Int)] = [
            (0, .code, 25), (0, .study, 15),
            (1, .workout, 30), (1, .code, 50),
            (2, .design, 40),
            (3, .code, 45), (3, .study, 25),
            (4, .workout, 20),
            (5, .code, 60),
            (6, .study, 35)
        ]
        for (daysAgo, cat, mins) in samples {
            if let date = calendar.date(byAdding: .day, value: -daysAgo, to: .now) {
                modelContext.insert(
                    FocusSessionRecord(category: cat.rawValue, durationSeconds: mins * 60, completedAt: date)
                )
            }
        }
        try? modelContext.save()
    }
}
