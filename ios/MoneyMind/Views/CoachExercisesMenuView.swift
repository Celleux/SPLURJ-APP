import SwiftUI

struct CoachExercisesMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showACT = false

    private let purple = Color(red: 0.6, green: 0.3, blue: 0.9)

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Guided Exercises")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.top, 8)

                Button {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        showACT = true
                    }
                } label: {
                    ExerciseMenuRow(
                        icon: "leaf.fill",
                        title: "ACT Exercises",
                        subtitle: "Values, defusion & willingness",
                        color: Theme.teal
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("ACT Exercises")

                Spacer()
            }
            .padding(.horizontal)
            .background(Theme.background.ignoresSafeArea())
            .fullScreenCover(isPresented: $showACT) {
                ACTExercisesView()
            }
        }
    }
}

private struct ExerciseMenuRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(Typography.displaySmall)
                .foregroundStyle(color)
                .frame(width: 48, height: 48)
                .background(color.opacity(0.12), in: .rect(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Typography.headingSmall)
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle)
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textSecondary.opacity(0.4))
        }
        .padding(16)
        .splurjCard(.interactive)
    }
}
