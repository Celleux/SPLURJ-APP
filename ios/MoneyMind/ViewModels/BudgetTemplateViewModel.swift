import SwiftUI
import SwiftData

@Observable
class BudgetTemplateViewModel {
    var selectedTemplate: BudgetTemplateType?
    var monthlyIncome: String = ""
    var allocations: [BudgetAllocation] = []
    var currentStep: SetupStep = .selectTemplate
    var appeared = false
    var savingsPercentage: Double = 20
    var hapticTrigger = false

    enum SetupStep: Int, CaseIterable {
        case selectTemplate
        case enterIncome
        case reviewCategories
        case confirm
    }

    var incomeValue: Double {
        Double(monthlyIncome) ?? 0
    }

    var totalAllocated: Double {
        allocations.reduce(0) { $0 + $1.amount }
    }

    var unassigned: Double {
        max(incomeValue - totalAllocated, 0)
    }

    var isFullyAssigned: Bool {
        abs(incomeValue - totalAllocated) < 0.01
    }

    var canProceedFromIncome: Bool {
        incomeValue > 0
    }

    var canConfirm: Bool {
        !allocations.isEmpty && allocations.allSatisfy { $0.amount >= 0 }
    }

    func selectTemplate(_ template: BudgetTemplateType) {
        selectedTemplate = template
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            currentStep = .enterIncome
        }
    }

    func generateAllocations() {
        guard let template = selectedTemplate else { return }
        let income = incomeValue

        allocations = template.defaultCategories.map { cat in
            BudgetAllocation(
                name: cat.name,
                icon: cat.icon,
                colorHex: cat.colorHex,
                amount: (income * cat.percentage / 100).rounded(),
                percentage: cat.percentage
            )
        }

        if template == .payYourselfFirst {
            let savingsAmount = (income * savingsPercentage / 100).rounded()
            let remaining = income - savingsAmount
            allocations = template.defaultCategories.map { cat in
                let amount: Double
                if cat.name == "Savings" {
                    amount = savingsAmount
                } else {
                    let nonSavingsTotal = template.defaultCategories.filter { $0.name != "Savings" }.reduce(0.0) { $0 + $1.percentage }
                    amount = nonSavingsTotal > 0 ? (remaining * cat.percentage / nonSavingsTotal).rounded() : 0
                }
                return BudgetAllocation(
                    name: cat.name,
                    icon: cat.icon,
                    colorHex: cat.colorHex,
                    amount: amount,
                    percentage: cat.percentage
                )
            }
        }
    }

    func proceedToReview() {
        generateAllocations()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            currentStep = .reviewCategories
        }
    }

    func proceedToConfirm() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            currentStep = .confirm
        }
    }

    func goBack() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            if let prev = SetupStep(rawValue: currentStep.rawValue - 1) {
                currentStep = prev
            }
        }
    }

    func updateAllocation(at index: Int, amount: Double) {
        guard allocations.indices.contains(index) else { return }
        allocations[index].amount = amount
        if incomeValue > 0 {
            allocations[index].percentage = (amount / incomeValue) * 100
        }
    }

    func saveBudgets(modelContext: ModelContext, existingBudgets: [BudgetCategory]) {
        for existing in existingBudgets {
            modelContext.delete(existing)
        }

        for (i, alloc) in allocations.enumerated() {
            let budget = BudgetCategory(
                name: alloc.name,
                icon: alloc.icon,
                colorHex: alloc.colorHex,
                monthlyLimit: alloc.amount,
                sortOrder: i
            )
            modelContext.insert(budget)
        }

        hapticTrigger.toggle()
    }

    func reset() {
        selectedTemplate = nil
        monthlyIncome = ""
        allocations = []
        currentStep = .selectTemplate
        appeared = false
        savingsPercentage = 20
    }

    func needsRingData() -> (needs: Double, wants: Double, savings: Double) {
        let income = incomeValue
        guard income > 0 else { return (0, 0, 0) }

        var needs: Double = 0
        var wants: Double = 0
        var savings: Double = 0

        let needsCategories = ["Housing", "Food", "Transport", "Bills"]
        let savingsCategories = ["Savings"]

        for alloc in allocations {
            if needsCategories.contains(alloc.name) {
                needs += alloc.amount
            } else if savingsCategories.contains(alloc.name) {
                savings += alloc.amount
            } else {
                wants += alloc.amount
            }
        }

        return (needs / income, wants / income, savings / income)
    }
}
