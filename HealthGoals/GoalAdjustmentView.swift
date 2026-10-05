import SwiftUI

struct GoalAdjustmentView: View {
    let model: OnboardingModel
    let goal: WeeklyGoal
    @State private var input: String
    @Environment(\.dismiss) private var dismiss

    init(model: OnboardingModel, goal: WeeklyGoal) {
        self.model = model
        self.goal = goal
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
                }
                Section {
                    Button("goal.apply") {
                        if model.adjustDraft(to: input) { dismiss() }
                    }
                    .disabled(!isValid)
                    .accessibilityIdentifier("goal.apply")
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
    }
}

private extension GoalAdjustmentView {
    var isValid: Bool {
        guard let value = Int(input.trimmingCharacters(in: .whitespacesAndNewlines)) else { return false }
        return WeeklyGoal(metric: goal.metric, value: value) != nil
    }
}
