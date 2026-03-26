import SwiftUI
import SwiftData

struct ImplementationIntentionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \ImplementationIntention.createdAt, order: .reverse) private var intentions: [ImplementationIntention]
    @State private var characterVM = CharacterViewModel()

    @State private var flowStep: Int = 0
    @State private var selectedTrigger: String = ""
    @State private var customTrigger: String = ""
    @State private var selectedResponse: String = ""
    @State private var customResponse: String = ""
    @State private var signatureLines: [[CGPoint]] = []
    @State private var isDrawing = false
    @State private var isCompleted = false
    @State private var showCreateFlow = false

    private var profile: UserProfile? { profiles.first }

    private let triggers = [
        "When I feel the urge to gamble",
        "When I open Amazon",
        "When friends invite me to the casino",
        "When I feel stressed about money"
    ]

    private let responses = [
        "I will open Urge Surf",
        "I will call my accountability partner",
        "I will check my wallet growth",
        "I will do 4-7-8 breathing"
    ]

    private var activeTrigger: String {
        selectedTrigger == "custom" ? customTrigger : selectedTrigger
    }

    private var activeResponse: String {
        selectedResponse == "custom" ? customResponse : selectedResponse
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if showCreateFlow {
                    createFlowContent
                } else {
                    intentionsListContent
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Button(showCreateFlow ? "Back" : "Close") {
                if showCreateFlow {
                    withAnimation(.spring(response: 0.3)) {
                        showCreateFlow = false
                        resetFlow()
                    }
                } else {
                    dismiss()
                }
            }
            .foregroundStyle(Theme.textSecondary)

            Spacer()

            Text("If-Then Plans")
                .font(Typography.headingMedium)
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            if showCreateFlow {
                Text("Step \(flowStep + 1)/3")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary)
            } else {
                Circle().fill(.clear).frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var intentionsListContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                Button {
                    withAnimation(.spring(response: 0.4)) {
                        showCreateFlow = true
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(Typography.displaySmall)
                            .foregroundStyle(Theme.accentGreen)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Create Your If-Then Plan")
                                .font(Typography.headingSmall)
                                .foregroundStyle(Theme.textPrimary)
                            Text("Build an automatic coping response")
                                .font(Typography.labelSmall)
                                .foregroundStyle(Theme.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.textSecondary.opacity(0.5))
                    }
                    .padding(16)
                    .background(Theme.accentGreen.opacity(0.08), in: .rect(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Theme.accentGreen.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
                .accessibilityLabel("Create a new if-then plan")

                if intentions.isEmpty {
                    emptyState
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Plans")
                            .font(Typography.headingSmall)
                            .foregroundStyle(Theme.textSecondary)

                        ForEach(intentions) { intention in
                            intentionRow(intention)
                        }
                    }
                }

                Text("Based on Gollwitzer's research: Implementation intentions reduce unwanted behavior by 70%+.")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 80)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "lightbulb.fill")
                .font(Typography.displayMedium)
                .foregroundStyle(Theme.accentGreen.opacity(0.4))

            Text("No plans yet")
                .font(Typography.headingMedium)
                .foregroundStyle(Theme.textSecondary)

            Text("Create your first If-Then plan to build automatic coping responses for when urges strike.")
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }

    private func intentionRow(_ intention: ImplementationIntention) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: intention.hasSigned ? "signature" : "lightbulb.fill")
                    .foregroundStyle(Theme.accentGreen)
                    .font(Typography.labelSmall)

                Text("IF: \(intention.trigger)")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textPrimary)
            }

            Text("THEN: \(intention.response)")
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.teal)
                .padding(.leading, 24)

            HStack {
                Text(intention.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary)

                Spacer()

                if intention.timesActivated > 0 {
                    Text("Used \(intention.timesActivated)x")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.gold)
                }
            }
        }
        .padding(14)
        .splurjCard(.interactive)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var createFlowContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                flowProgressBar

                switch flowStep {
                case 0: triggerSelection
                case 1: responseSelection
                default: commitmentStep
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 80)
        }
    }

    private var flowProgressBar: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(i <= flowStep ? Theme.accentGreen : Theme.cardSurface)
                    .frame(height: 4)
                    .animation(.spring(response: 0.3), value: flowStep)
            }
        }
        .padding(.top, 8)
    }

    private var triggerSelection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("When this happens...")
                .font(Typography.displaySmall)
                .foregroundStyle(Theme.textPrimary)

            Text("Select the trigger that leads to your urge")
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.textSecondary)

            ForEach(triggers, id: \.self) { trigger in
                Button {
                    selectedTrigger = trigger
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(selectedTrigger == trigger ? Theme.accentGreen : Theme.cardSurface)
                            .frame(width: 22, height: 22)
                            .overlay(
                                selectedTrigger == trigger
                                    ? Circle().fill(.white).frame(width: 8, height: 8)
                                    : nil
                            )

                        Text(trigger)
                            .font(Typography.bodyMedium)
                            .foregroundStyle(selectedTrigger == trigger ? Theme.textPrimary : Theme.textSecondary)

                        Spacer()
                    }
                    .padding(14)
                    .background(
                        selectedTrigger == trigger ? Theme.accentGreen.opacity(0.08) : Theme.cardSurface,
                        in: .rect(cornerRadius: 12)
                    )
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.selection, trigger: selectedTrigger)
                .accessibilityLabel(trigger)
            }

            Button {
                selectedTrigger = "custom"
            } label: {
                HStack(spacing: 12) {
                    Circle()
                        .fill(selectedTrigger == "custom" ? Theme.accentGreen : Theme.cardSurface)
                        .frame(width: 22, height: 22)
                        .overlay(
                            selectedTrigger == "custom"
                                ? Circle().fill(.white).frame(width: 8, height: 8)
                                : nil
                        )

                    Text("Custom trigger...")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.textSecondary)

                    Spacer()
                }
                .padding(14)
                .background(
                    selectedTrigger == "custom" ? Theme.accentGreen.opacity(0.08) : Theme.cardSurface,
                    in: .rect(cornerRadius: 12)
                )
            }
            .buttonStyle(.plain)

            if selectedTrigger == "custom" {
                TextField("Describe your trigger...", text: $customTrigger)
                    .font(Typography.bodyMedium)
                    .padding(12)
                    .splurjCard(.outlined)
                    .foregroundStyle(Theme.textPrimary)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if !activeTrigger.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.4)) { flowStep = 1 }
                } label: {
                    Text("Next")
                        .font(Typography.headingMedium)
                        .foregroundStyle(Theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accentGradient, in: .rect(cornerRadius: 12))
                }
                .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
                .transition(.opacity)
            }
        }
    }

    private var responseSelection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("I will do this instead...")
                .font(Typography.displaySmall)
                .foregroundStyle(Theme.textPrimary)

            Text("Choose your automatic coping response")
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.textSecondary)

            ForEach(responses, id: \.self) { response in
                Button {
                    selectedResponse = response
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(selectedResponse == response ? Theme.teal : Theme.cardSurface)
                            .frame(width: 22, height: 22)
                            .overlay(
                                selectedResponse == response
                                    ? Circle().fill(.white).frame(width: 8, height: 8)
                                    : nil
                            )

                        Text(response)
                            .font(Typography.bodyMedium)
                            .foregroundStyle(selectedResponse == response ? Theme.textPrimary : Theme.textSecondary)

                        Spacer()
                    }
                    .padding(14)
                    .background(
                        selectedResponse == response ? Theme.teal.opacity(0.08) : Theme.cardSurface,
                        in: .rect(cornerRadius: 12)
                    )
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.selection, trigger: selectedResponse)
                .accessibilityLabel(response)
            }

            Button {
                selectedResponse = "custom"
            } label: {
                HStack(spacing: 12) {
                    Circle()
                        .fill(selectedResponse == "custom" ? Theme.teal : Theme.cardSurface)
                        .frame(width: 22, height: 22)
                        .overlay(
                            selectedResponse == "custom"
                                ? Circle().fill(.white).frame(width: 8, height: 8)
                                : nil
                        )

                    Text("Custom response...")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.textSecondary)

                    Spacer()
                }
                .padding(14)
                .background(
                    selectedResponse == "custom" ? Theme.teal.opacity(0.08) : Theme.cardSurface,
                    in: .rect(cornerRadius: 12)
                )
            }
            .buttonStyle(.plain)

            if selectedResponse == "custom" {
                TextField("Describe your response...", text: $customResponse)
                    .font(Typography.bodyMedium)
                    .padding(12)
                    .splurjCard(.outlined)
                    .foregroundStyle(Theme.textPrimary)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if !activeResponse.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.4)) { flowStep = 2 }
                } label: {
                    Text("Next")
                        .font(Typography.headingMedium)
                        .foregroundStyle(Theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accentGradient, in: .rect(cornerRadius: 12))
                }
                .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
                .transition(.opacity)
            }
        }
    }

    private var commitmentStep: some View {
        VStack(spacing: 20) {
            Text("Your Commitment")
                .font(Typography.displaySmall)
                .foregroundStyle(Theme.textPrimary)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Text("IF")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.emergency)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.emergency.opacity(0.12), in: .capsule)

                    Text(activeTrigger)
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.textPrimary)
                }

                HStack(spacing: 8) {
                    Text("THEN")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.accentGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.accentGreen.opacity(0.12), in: .capsule)

                    Text(activeResponse)
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.textPrimary)
                }
            }
            .padding(16)
            .splurjCard(.hero)

            VStack(alignment: .leading, spacing: 8) {
                Text("Sign your commitment")
                    .font(Typography.headingSmall)
                    .foregroundStyle(Theme.textSecondary)

                signatureCanvas
            }

            if !isCompleted {
                Button {
                    saveIntention()
                } label: {
                    Text("I Commit to This Plan")
                        .font(Typography.headingMedium)
                        .foregroundStyle(Theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accentGradient, in: .rect(cornerRadius: 12))
                }
                .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
            }

            if isCompleted {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(Typography.displayLarge)
                        .foregroundStyle(Theme.accentGreen)

                    Text("Plan Created!")
                        .font(Typography.headingLarge)
                        .foregroundStyle(Theme.textPrimary)

                    Text("+50 XP")
                        .font(Typography.headingMedium)
                        .foregroundStyle(Theme.gold)
                }
                .transition(.scale.combined(with: .opacity))
                .sensoryFeedback(.success, trigger: isCompleted)
            }
        }
    }

    private var signatureCanvas: some View {
        ZStack(alignment: .bottomTrailing) {
            Canvas { context, size in
                for line in signatureLines {
                    guard line.count > 1 else { continue }
                    var path = Path()
                    path.move(to: line[0])
                    for point in line.dropFirst() {
                        path.addLine(to: point)
                    }
                    context.stroke(path, with: .color(Theme.textPrimary), lineWidth: 2.5)
                }
            }
            .frame(height: 120)
            .splurjCard(.outlined)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Theme.textSecondary.opacity(0.2), lineWidth: 1)
            )
            .overlay(
                signatureLines.isEmpty
                    ? Text("Draw your signature here")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary.opacity(0.5))
                    : nil
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let point = value.location
                        if !isDrawing {
                            isDrawing = true
                            signatureLines.append([point])
                        } else {
                            signatureLines[signatureLines.count - 1].append(point)
                        }
                    }
                    .onEnded { _ in
                        isDrawing = false
                    }
            )

            if !signatureLines.isEmpty {
                Button {
                    signatureLines = []
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                        .padding(8)
                        .background(Theme.background.opacity(0.8), in: .circle)
                }
                .padding(8)
            }
        }
    }

    private func saveIntention() {
        let intention = ImplementationIntention(
            intention: "IF \(activeTrigger), THEN \(activeResponse)",
            trigger: activeTrigger,
            response: activeResponse,
            hasSigned: !signatureLines.isEmpty
        )
        modelContext.insert(intention)

        if let profile {
            characterVM.syncFromProfile(profile)
            characterVM.onImplementationIntention(profile: profile)
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            isCompleted = true
        }

        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.spring(response: 0.3)) {
                showCreateFlow = false
                resetFlow()
            }
        }
    }

    private func resetFlow() {
        flowStep = 0
        selectedTrigger = ""
        customTrigger = ""
        selectedResponse = ""
        customResponse = ""
        signatureLines = []
        isCompleted = false
    }
}
