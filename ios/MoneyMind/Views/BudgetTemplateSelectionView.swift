import SwiftUI
import SwiftData

struct BudgetTemplateSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var budgets: [BudgetCategory]
    @Query private var quizResults: [QuizResult]
    @State private var vm = BudgetTemplateViewModel()
    @State private var showIncomeEntry: Bool = false
    @State private var selectedTemplate: BudgetTemplateType?

    private var personality: MoneyPersonality {
        quizResults.first?.personality ?? .builder
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Text("Budget Templates")
                            .font(Typography.displayMedium)
                            .foregroundStyle(Theme.textPrimary)
                        Text("Choose a method that fits your style")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.top, 8)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(BudgetTemplateType.allCases) { template in
                            templateCard(template)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .alert("Enter Monthly Income", isPresented: $showIncomeEntry) {
                TextField("Monthly income", text: $vm.monthlyIncome)
                    .keyboardType(.decimalPad)
                Button("Create Budget") {
                    if vm.canProceedFromIncome {
                        vm.generateAllocations()
                        vm.saveBudgets(modelContext: modelContext, existingBudgets: budgets)
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let t = selectedTemplate {
                    Text("Enter your monthly income to set up your \(t.rawValue) budget.")
                }
            }
        }
    }

    private func templateCard(_ template: BudgetTemplateType) -> some View {
        Button {
            vm.selectTemplate(template)
            selectedTemplate = template
            showIncomeEntry = true
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(template.accentColor.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: template.icon)
                        .font(Typography.displaySmall)
                        .foregroundStyle(template.accentColor)
                }

                Text(template.rawValue)
                    .font(Typography.headingSmall)
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(template.subtitle)
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if template.recommendedPersonality == personality {
                    Text("Recommended")
                        .font(Typography.labelSmall)
                        .foregroundStyle(personality.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(personality.color.opacity(0.12), in: .capsule)
                }

                Spacer(minLength: 0)

                HStack(spacing: 4) {
                    Text("Select")
                        .font(Typography.labelMedium)
                    Image(systemName: "arrow.right")
                        .font(Typography.labelSmall)
                }
                .foregroundStyle(template.accentColor)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 200)
            .splurjCard(.elevated)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selectedTemplate)
    }
}
