import WidgetKit
import SwiftUI

nonisolated struct SplurjEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

nonisolated struct SplurjProvider: TimelineProvider {
    func placeholder(in context: Context) -> SplurjEntry {
        SplurjEntry(date: .now, data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SplurjEntry) -> Void) {
        let data = WidgetData.load() ?? .placeholder
        completion(SplurjEntry(date: .now, data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SplurjEntry>) -> Void) {
        let data = WidgetData.load() ?? .placeholder
        let entry = SplurjEntry(date: .now, data: data)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - Widget Color Helpers

nonisolated struct WidgetColors: Sendable {
    static let card = Color(red: 17/255, green: 24/255, blue: 39/255)
    static let elevated = Color(red: 26/255, green: 34/255, blue: 54/255)
    static let accent = Color(red: 108/255, green: 92/255, blue: 231/255)
    static let secondary = Color(red: 0, green: 210/255, blue: 1)
    static let danger = Color(red: 1, green: 82/255, blue: 82/255)
    static let textSecondary = Color(red: 148/255, green: 163/255, blue: 184/255)
    static let textMuted = Color(red: 100/255, green: 116/255, blue: 139/255)
    static let border = Color(red: 30/255, green: 41/255, blue: 59/255)

    static func personalityColor(hex: UInt) -> Color {
        Color(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }

    static func categoryColor(hex: String) -> Color {
        let scanner = Scanner(string: hex)
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)
        return personalityColor(hex: UInt(value))
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: SplurjEntry

    private var personalityColor: Color {
        WidgetColors.personalityColor(hex: entry.data.personalityColorHex)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Daily Budget")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(WidgetColors.textMuted)
                Spacer()
                Circle()
                    .fill(personalityColor)
                    .frame(width: 6, height: 6)
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(WidgetColors.border, lineWidth: 4)
                Circle()
                    .trim(from: 0, to: min(entry.data.budgetProgress, 1.0))
                    .stroke(
                        AngularGradient(
                            colors: [personalityColor, WidgetColors.secondary],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 1) {
                    Text(formattedAmount(entry.data.budgetRemaining))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(entry.data.isOverBudget ? WidgetColors.danger : .white)
                        .privacySensitive()
                    Text("left")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(WidgetColors.textMuted)
                }
            }
            .frame(width: 72, height: 72)
            .frame(maxWidth: .infinity)

            Spacer()

            if entry.data.isOverBudget {
                Text("Over budget!")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(WidgetColors.danger)
            }
        }
        .containerBackground(WidgetColors.card, for: .widget)
        .widgetURL(URL(string: "splurj://wallet"))
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: SplurjEntry

    private var personalityColor: Color {
        WidgetColors.personalityColor(hex: entry.data.personalityColorHex)
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Budget")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(WidgetColors.textMuted)

                Text(formattedAmount(entry.data.budgetRemaining))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(entry.data.isOverBudget ? WidgetColors.danger : .white)
                    .privacySensitive()

                Text("remaining")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(WidgetColors.textSecondary)

                Spacer()

                ZStack {
                    Circle()
                        .stroke(WidgetColors.border, lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: min(entry.data.budgetProgress, 1.0))
                        .stroke(
                            LinearGradient(
                                colors: [personalityColor, WidgetColors.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(entry.data.budgetProgress * 100))%")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(width: 40, height: 40)
            }

            Divider()
                .background(WidgetColors.border)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(entry.data.categories.prefix(3).enumerated()), id: \.offset) { _, cat in
                    CategoryRowWidget(category: cat, totalBudget: entry.data.totalBudget)
                }

                Spacer()

                Text("Tap to add expense")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(WidgetColors.textMuted)
            }
        }
        .containerBackground(WidgetColors.card, for: .widget)
        .widgetURL(URL(string: "splurj://add-expense"))
    }
}

struct CategoryRowWidget: View {
    let category: WidgetData.CategoryData
    let totalBudget: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.system(size: 9))
                    .foregroundStyle(WidgetColors.categoryColor(hex: category.colorHex))
                Text(category.name)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Text(formattedAmount(category.spent))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(category.spent > category.limit ? WidgetColors.danger : .white)
                    .privacySensitive()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(WidgetColors.border)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(WidgetColors.categoryColor(hex: category.colorHex))
                        .frame(width: geo.size.width * min(1.0, category.limit > 0 ? category.spent / category.limit : 0))
                }
            }
            .frame(height: 3)
        }
    }
}

// MARK: - Large Widget

struct LargeWidgetView: View {
    let entry: SplurjEntry

    private var personalityColor: Color {
        WidgetColors.personalityColor(hex: entry.data.personalityColorHex)
    }

    private var maxDaily: Double {
        entry.data.weeklySpending.map(\.amount).max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Balance")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(WidgetColors.textMuted)
                    Text(formattedAmount(entry.data.totalIncome - entry.data.totalSpent))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .privacySensitive()
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(WidgetColors.border, lineWidth: 3.5)
                    Circle()
                        .trim(from: 0, to: min(entry.data.budgetProgress, 1.0))
                        .stroke(
                            LinearGradient(
                                colors: [personalityColor, WidgetColors.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text(formattedAmount(entry.data.budgetRemaining))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(entry.data.isOverBudget ? WidgetColors.danger : .white)
                            .privacySensitive()
                        Text("left")
                            .font(.system(size: 8, weight: .medium, design: .rounded))
                            .foregroundStyle(WidgetColors.textMuted)
                    }
                }
                .frame(width: 52, height: 52)
            }

            Text("This Week")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(WidgetColors.textSecondary)

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(entry.data.weeklySpending.enumerated()), id: \.offset) { _, day in
                    VStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                day.isToday
                                    ? LinearGradient(colors: [personalityColor, WidgetColors.secondary], startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(colors: [WidgetColors.elevated, WidgetColors.elevated], startPoint: .top, endPoint: .bottom)
                            )
                            .frame(height: max(4, CGFloat(day.amount / max(maxDaily, 1)) * 50))
                        Text(day.dayLabel)
                            .font(.system(size: 8, weight: day.isToday ? .bold : .regular, design: .rounded))
                            .foregroundStyle(day.isToday ? .white : WidgetColors.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 64)

            Divider()
                .background(WidgetColors.border)

            VStack(spacing: 5) {
                ForEach(Array(entry.data.categories.prefix(3).enumerated()), id: \.offset) { _, cat in
                    LargeCategoryRow(category: cat)
                }
            }
        }
        .containerBackground(WidgetColors.card, for: .widget)
        .widgetURL(URL(string: "splurj://home"))
    }
}

struct LargeCategoryRow: View {
    let category: WidgetData.CategoryData

    private var progress: Double {
        guard category.limit > 0 else { return 0 }
        return min(1.0, category.spent / category.limit)
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: category.icon)
                .font(.system(size: 10))
                .foregroundStyle(WidgetColors.categoryColor(hex: category.colorHex))
                .frame(width: 16)

            Text(category.name)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 60, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(WidgetColors.border)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(WidgetColors.categoryColor(hex: category.colorHex))
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 4)

            Text("\(formattedAmount(category.spent))/\(formattedAmount(category.limit))")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(category.spent > category.limit ? WidgetColors.danger : WidgetColors.textSecondary)
                .privacySensitive()
        }
    }
}

// MARK: - Lock Screen Circular

struct CircularWidgetView: View {
    let entry: SplurjEntry

    var body: some View {
        Gauge(value: min(entry.data.budgetProgress, 1.0)) {
            Image(systemName: "dollarsign")
        } currentValueLabel: {
            Text(shortAmount(entry.data.budgetRemaining))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .privacySensitive()
        }
        .gaugeStyle(.accessoryCircular)
        .widgetURL(URL(string: "splurj://wallet"))
    }
}

// MARK: - Lock Screen Rectangular

struct RectangularWidgetView: View {
    let entry: SplurjEntry

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 16))
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 1) {
                Text("\(entry.data.noSpendStreak)-day streak")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Text("No unnecessary spending")
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .widgetURL(URL(string: "splurj://challenges"))
    }
}

// MARK: - Lock Screen Inline

struct InlineWidgetView: View {
    let entry: SplurjEntry

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "dollarsign.circle.fill")
            Text("Budget: \(formattedAmount(entry.data.budgetRemaining)) remaining")
                .privacySensitive()
        }
        .widgetURL(URL(string: "splurj://wallet"))
    }
}

// MARK: - Adaptive Widget View

struct SplurjWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SplurjEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        case .accessoryCircular:
            CircularWidgetView(entry: entry)
        case .accessoryRectangular:
            RectangularWidgetView(entry: entry)
        case .accessoryInline:
            InlineWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Definition

struct SplurjBudgetWidget: Widget {
    let kind = "SplurjBudget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SplurjProvider()) { entry in
            SplurjWidgetView(entry: entry)
        }
        .configurationDisplayName("Splurj Budget")
        .description("Track your spending and budget at a glance.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
        ])
        .contentMarginsDisabled()
    }
}

// MARK: - Formatting Helpers

private func formattedAmount(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "USD"
    formatter.maximumFractionDigits = 0
    return formatter.string(from: NSNumber(value: amount)) ?? "$0"
}

private func shortAmount(_ amount: Double) -> String {
    if amount >= 1000 {
        return "$\(Int(amount / 1000))k"
    }
    return "$\(Int(amount))"
}
