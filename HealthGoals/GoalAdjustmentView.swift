import SwiftUI

struct GoalAdjustmentView: View {
    let model: OnboardingModel
    let goal: WeeklyGoal
    let isActive: Bool
    @State private var isConfirmingDeletion = false
    @State private var input: String
    @Environment(\.dismiss) private var dismiss

    init(model: OnboardingModel, goal: WeeklyGoal, isActive: Bool = false) {
        self.model = model
        self.goal = goal
        self.isActive = isActive
        // The field intentionally starts from the draft captured when the sheet opens.
        _input = State(initialValue: String(goal.value))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(LocalizedStringKey(goal.metric == .steps ? "metric.steps" : "metric.activity"))
                    TextField("goal.input", text: $input)
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("goal.input")
                    Text("goal.inputExplanation").font(.footnote)
                    if isActive { Text("goal.currentWeekEffect").font(.footnote) }
                }
                Section {
                    Button(LocalizedStringKey(isActive ? "goal.save" : "goal.apply")) {
                        let saved = isActive ? model.editGoal(metric: goal.metric, to: input)
                            : model.adjustDraft(to: input, metric: goal.metric)
                        if saved { dismiss() }
                    }
                    .disabled(!isValid)
                    .accessibilityIdentifier("goal.apply")
                }
                if isActive {
                    Section {
                        Button("goal.delete", role: .destructive) { isConfirmingDeletion = true }
                            .accessibilityIdentifier("goal.delete")
                    }
                }
            }
            .navigationTitle("goal.adjustTitle")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
            }
        }
        .tint(Color("GoalAccent"))
        .alert(
            LocalizedStringKey(goal.metric == .steps ? "goal.deleteStepsTitle" : "goal.deleteActivityTitle"),
            isPresented: $isConfirmingDeletion
        ) {
            Button("common.cancel", role: .cancel) {}
            Button("goal.delete", role: .destructive) {
                model.deleteGoal(metric: goal.metric)
                dismiss()
            }
        } message: { Text("goal.deleteExplanation") }
    }
}

private extension GoalAdjustmentView {
    var isValid: Bool {
        guard let value = Int(input.trimmingCharacters(in: .whitespacesAndNewlines)) else { return false }
        return WeeklyGoal(metric: goal.metric, value: value) != nil
    }
}
