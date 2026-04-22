import SwiftUI

struct HRVStateOfMindCard: View {
    let service: HealthKitService
    let onConnect: () -> Void

    var body: some View {
        switch service.authState {
        case .authorized:
            authorizedContent
        case .notDetermined:
            connectPrompt
        case .denied, .unavailable:
            EmptyView()
        }
    }

    private var authorizedContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(titleColor)
                    .frame(width: 28, height: 28)
                    .background(titleColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text("State of Mind")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                if service.isStressDetected {
                    Label("Dip", systemImage: "exclamationmark.triangle.fill")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.warning)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.warning.opacity(0.12), in: .capsule)
                }
            }

            if service.recentHRV.isEmpty {
                Text("No HRV samples yet. Wear your Apple Watch to start seeing your baseline.")
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                HStack(alignment: .bottom, spacing: 18) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(latestLabel)
                            .font(Typography.displaySmall)
                            .foregroundStyle(titleColor)
                        Text("Latest HRV")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.textSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(baselineLabel)
                            .font(Typography.headingMedium)
                            .foregroundStyle(Theme.textPrimary)
                        Text("7-day baseline")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                sparkline
                    .frame(height: 36)
            }

            if service.isStressDetected {
                Text("Your HRV dipped below your baseline today \u{2014} great moment for a breath exercise before any big spending.")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .splurjCard(.elevated)
    }

    private var sparkline: some View {
        GeometryReader { proxy in
            let values = service.recentHRV.map { $0.value }
            let minV = values.min() ?? 0
            let maxV = values.max() ?? 1
            let range = max(1, maxV - minV)
            let step = values.count > 1 ? proxy.size.width / CGFloat(values.count - 1) : 0

            Path { path in
                for (index, value) in values.enumerated() {
                    let x = CGFloat(index) * step
                    let y = proxy.size.height - CGFloat((value - minV) / range) * proxy.size.height
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(
                LinearGradient(
                    colors: [titleColor.opacity(0.6), titleColor],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
        }
    }

    private var connectPrompt: some View {
        Button(action: onConnect) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Theme.accentSecondary.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.accentSecondary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Detect stress before it spends")
                        .font(Typography.headingSmall)
                        .foregroundStyle(Theme.textPrimary)
                    Text("Connect Apple Health to read HRV")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary.opacity(0.5))
            }
            .padding(14)
            .splurjCard(.interactive)
        }
        .buttonStyle(.plain)
    }

    private var titleColor: Color {
        service.isStressDetected ? Theme.warning : Theme.accentSecondary
    }

    private var latestLabel: String {
        guard let latest = service.latestHRV else { return "\u{2014}" }
        return "\(Int(latest)) ms"
    }

    private var baselineLabel: String {
        guard service.baselineHRV > 0 else { return "\u{2014}" }
        return "\(Int(service.baselineHRV)) ms"
    }
}
