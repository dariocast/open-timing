import SwiftUI

public struct RulesView: View {
    @ObservedObject var appState: AppState
    @State private var showingAddRuleSheet = false
    @State private var ruleToEdit: TrackingRule?
    @State private var showAppliedAlert = false
    
    private var categoryMap: [UUID: ActivityCategory] {
        Dictionary(uniqueKeysWithValues: appState.categories.map { ($0.id, $0) })
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Categorization Rules")
                        .font(.system(size: 24, weight: .bold))
                    Text("Automatically assign activities to categories and projects based on app, window title, or website domain.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    appState.reapplyRules()
                    showAppliedAlert = true
                }) {
                    Label("Apply to All Past History", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.bordered)
                
                Button(action: { showingAddRuleSheet = true }) {
                    Label("Add Rule", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            
            Divider()
            
            // Rules List
            if appState.rules.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary)
                    Text("No rules defined")
                        .font(.headline)
                    Text("Add rules to automate your categorization workflow.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Add Rule") {
                        showingAddRuleSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }
            } else {
                List {
                    ForEach(appState.rules) { rule in
                        HStack(spacing: 12) {
                            Toggle("", isOn: Binding(
                                get: { rule.isEnabled },
                                set: { newVal in
                                    var updated = rule
                                    updated.isEnabled = newVal
                                    appState.saveRule(updated)
                                }
                            ))
                            .labelsHidden()
                            .toggleStyle(.switch)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text(rule.name)
                                        .font(.headline)
                                    
                                    Text("Priority: \(rule.priority)")
                                        .font(.system(size: 10, weight: .bold))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(Color.secondary.opacity(0.15))
                                        .cornerRadius(4)
                                }
                                
                                HStack(spacing: 4) {
                                    Text("When **\(rule.targetField.rawValue)** \(rule.matchType.rawValue.lowercased())")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\"\(rule.pattern)\"")
                                        .font(.system(size: 11, design: .monospaced))
                                        .padding(.horizontal, 4)
                                        .background(Color.secondary.opacity(0.1))
                                        .cornerRadius(3)
                                }
                            }
                            
                            Spacer()
                            
                            // Category Tag
                            if let catId = rule.targetCategoryId, let cat = categoryMap[catId] {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color(hex: cat.colorHex))
                                        .frame(width: 8, height: 8)
                                    Text(cat.name)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: cat.colorHex).opacity(0.15))
                                .cornerRadius(6)
                            }
                            
                            Button("Edit") {
                                ruleToEdit = rule
                            }
                            .buttonStyle(.bordered)
                            
                            Button(role: .destructive, action: {
                                appState.deleteRule(rule)
                            }) {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .alert("Rules Re-applied", isPresented: $showAppliedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("All historical activities have been re-evaluated and categorized according to your current active rules.")
        }
        .sheet(isPresented: $showingAddRuleSheet) {
            RuleEditSheet(rule: nil, categories: appState.categories, projects: appState.projects) { newRule in
                appState.saveRule(newRule)
            }
        }
        .sheet(item: $ruleToEdit) { rule in
            RuleEditSheet(rule: rule, categories: appState.categories, projects: appState.projects) { updatedRule in
                appState.saveRule(updatedRule)
            }
        }
    }
}

// MARK: - Rule Edit Sheet

struct RuleEditSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var name: String
    @State private var targetField: RuleField
    @State private var matchType: RuleMatchType
    @State private var pattern: String
    @State private var targetCategoryId: UUID?
    @State private var targetProjectId: UUID?
    @State private var priority: Int
    @State private var isEnabled: Bool
    
    let editingId: UUID?
    let categories: [ActivityCategory]
    let projects: [Project]
    let onSave: (TrackingRule) -> Void
    
    init(rule: TrackingRule?, categories: [ActivityCategory], projects: [Project], onSave: @escaping (TrackingRule) -> Void) {
        self.editingId = rule?.id
        self.categories = categories
        self.projects = projects
        _name = State(initialValue: rule?.name ?? "")
        _targetField = State(initialValue: rule?.targetField ?? .appName)
        _matchType = State(initialValue: rule?.matchType ?? .contains)
        _pattern = State(initialValue: rule?.pattern ?? "")
        _targetCategoryId = State(initialValue: rule?.targetCategoryId)
        _targetProjectId = State(initialValue: rule?.targetProjectId)
        _priority = State(initialValue: rule?.priority ?? 10)
        _isEnabled = State(initialValue: rule?.isEnabled ?? true)
        self.onSave = onSave
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(editingId == nil ? "New Categorization Rule" : "Edit Rule")
                .font(.headline)
            
            TextField("Rule Name (e.g. VS Code -> Dev)", text: $name)
                .textFieldStyle(.roundedBorder)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Target Field")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("", selection: $targetField) {
                        ForEach(RuleField.allCases, id: \.self) { field in
                            Text(field.rawValue).tag(field)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Match Condition")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("", selection: $matchType) {
                        ForEach(RuleMatchType.allCases, id: \.self) { match in
                            Text(match.rawValue).tag(match)
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Pattern Value")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("e.g. Xcode, github.com, or regex", text: $pattern)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Assign Category")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("", selection: $targetCategoryId) {
                        Text("None").tag(nil as UUID?)
                        ForEach(categories) { cat in
                            Text(cat.name).tag(cat.id as UUID?)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Assign Project")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("", selection: $targetProjectId) {
                        Text("None").tag(nil as UUID?)
                        ForEach(projects) { proj in
                            Text(proj.name).tag(proj.id as UUID?)
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Priority (Higher evaluated first)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Stepper("Priority: \(priority)", value: $priority, in: 0...100)
            }
            
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Save Rule") {
                    let r = TrackingRule(
                        id: editingId ?? UUID(),
                        name: name.isEmpty ? "Rule for \(pattern)" : name,
                        targetField: targetField,
                        matchType: matchType,
                        pattern: pattern,
                        targetCategoryId: targetCategoryId,
                        targetProjectId: targetProjectId,
                        priority: priority,
                        isEnabled: isEnabled
                    )
                    onSave(r)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(pattern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 480)
    }
}
