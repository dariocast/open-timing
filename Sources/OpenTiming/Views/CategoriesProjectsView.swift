import SwiftUI

public struct CategoriesProjectsView: View {
    @ObservedObject var appState: AppState
    @State private var selectedTab: Int = 0
    @State private var showingAddCategorySheet = false
    @State private var showingAddProjectSheet = false
    @State private var categoryToEdit: ActivityCategory?
    @State private var projectToEdit: Project?
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header with Segmented Switcher & Add Button
            HStack {
                Picker("", selection: $selectedTab) {
                    Text("Categories (\(appState.categories.count))").tag(0)
                    Text("Projects (\(appState.projects.count))").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(width: 280)
                
                Spacer()
                
                if selectedTab == 0 {
                    Button(action: { showingAddCategorySheet = true }) {
                        Label("Add Category", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(action: { showingAddProjectSheet = true }) {
                        Label("Add Project", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            
            Divider()
            
            if selectedTab == 0 {
                // Category List
                List {
                    ForEach(appState.categories) { category in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: category.colorHex).opacity(0.2))
                                    .frame(width: 32, height: 32)
                                Image(systemName: category.iconName)
                                    .foregroundColor(Color(hex: category.colorHex))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(category.name)
                                    .font(.headline)
                                Text(category.productivityLabel)
                                    .font(.caption)
                                    .foregroundColor(prodColor(category.productivityScore))
                            }
                            
                            Spacer()
                            
                            Button("Edit") {
                                categoryToEdit = category
                            }
                            .buttonStyle(.bordered)
                            
                            Button(role: .destructive, action: {
                                appState.deleteCategory(category)
                            }) {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            } else {
                // Project List
                if appState.projects.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)
                        Text("No projects yet")
                            .font(.headline)
                        Text("Create projects to track client work, freelance tasks, or specific deliverables.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("Create First Project") {
                            showingAddProjectSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(appState.projects) { project in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: project.colorHex).opacity(0.2))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: project.iconName)
                                        .foregroundColor(Color(hex: project.colorHex))
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(project.name)
                                        .font(.headline)
                                    
                                    if let rate = project.hourlyRate {
                                        Text(String(format: "$%.2f / hour", rate))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Button("Edit") {
                                    projectToEdit = project
                                }
                                .buttonStyle(.bordered)
                                
                                Button(role: .destructive, action: {
                                    appState.deleteProject(project)
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
        }
        .sheet(isPresented: $showingAddCategorySheet) {
            CategoryEditSheet(category: nil) { newCat in
                appState.saveCategory(newCat)
            }
        }
        .sheet(item: $categoryToEdit) { cat in
            CategoryEditSheet(category: cat) { updatedCat in
                appState.saveCategory(updatedCat)
            }
        }
        .sheet(isPresented: $showingAddProjectSheet) {
            ProjectEditSheet(project: nil, categories: appState.categories) { newProj in
                appState.saveProject(newProj)
            }
        }
        .sheet(item: $projectToEdit) { proj in
            ProjectEditSheet(project: proj, categories: appState.categories) { updatedProj in
                appState.saveProject(updatedProj)
            }
        }
    }
    
    private func prodColor(_ score: Int) -> Color {
        if score > 0 { return .green }
        if score < 0 { return .red }
        return .secondary
    }
}

// MARK: - Category Edit Sheet

struct CategoryEditSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var name: String
    @State private var colorHex: String
    @State private var iconName: String
    @State private var productivityScore: Int
    let editingId: UUID?
    let onSave: (ActivityCategory) -> Void
    
    let icons = ["chevron.left.forwardslash.chevron.right", "paintpalette.fill", "doc.text.fill", "bubble.left.and.bubble.right.fill", "gearshape.fill", "tv.fill", "briefcase.fill", "chart.xyaxis.line", "gamecontroller.fill", "cart.fill"]
    let colors = ["#0A84FF", "#BF5AF2", "#5E5CE6", "#30D158", "#FF9F0A", "#FF453A", "#64D2FF", "#FF375F", "#8E8E93"]
    
    init(category: ActivityCategory?, onSave: @escaping (ActivityCategory) -> Void) {
        self.editingId = category?.id
        _name = State(initialValue: category?.name ?? "")
        _colorHex = State(initialValue: category?.colorHex ?? "#0A84FF")
        _iconName = State(initialValue: category?.iconName ?? "folder.fill")
        _productivityScore = State(initialValue: category?.productivityScore ?? 0)
        self.onSave = onSave
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(editingId == nil ? "New Category" : "Edit Category")
                .font(.headline)
            
            TextField("Category Name", text: $name)
                .textFieldStyle(.roundedBorder)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Productivity Level")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("", selection: $productivityScore) {
                    Text("Very Productive (+2)").tag(2)
                    Text("Productive (+1)").tag(1)
                    Text("Neutral (0)").tag(0)
                    Text("Distracting (-1)").tag(-1)
                    Text("Very Distracting (-2)").tag(-2)
                }
                .pickerStyle(.segmented)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Color")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    ForEach(colors, id: \.self) { hex in
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary, lineWidth: colorHex == hex ? 2 : 0)
                            )
                            .onTapGesture {
                                colorHex = hex
                            }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Icon")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 12) {
                    ForEach(icons, id: \.self) { icon in
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .frame(width: 28, height: 28)
                            .background(iconName == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                            .cornerRadius(6)
                            .onTapGesture {
                                iconName = icon
                            }
                    }
                }
            }
            
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Save") {
                    let cat = ActivityCategory(
                        id: editingId ?? UUID(),
                        name: name.isEmpty ? "New Category" : name,
                        colorHex: colorHex,
                        iconName: iconName,
                        productivityScore: productivityScore
                    )
                    onSave(cat)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 440)
    }
}

// MARK: - Project Edit Sheet

struct ProjectEditSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var name: String
    @State private var colorHex: String
    @State private var categoryId: UUID?
    @State private var hourlyRateText: String
    let editingId: UUID?
    let categories: [ActivityCategory]
    let onSave: (Project) -> Void
    
    init(project: Project?, categories: [ActivityCategory], onSave: @escaping (Project) -> Void) {
        self.editingId = project?.id
        self.categories = categories
        _name = State(initialValue: project?.name ?? "")
        _colorHex = State(initialValue: project?.colorHex ?? "#0A84FF")
        _categoryId = State(initialValue: project?.categoryId)
        _hourlyRateText = State(initialValue: project?.hourlyRate.map { String($0) } ?? "")
        self.onSave = onSave
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(editingId == nil ? "New Project" : "Edit Project")
                .font(.headline)
            
            TextField("Project Name", text: $name)
                .textFieldStyle(.roundedBorder)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Category")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("", selection: $categoryId) {
                    Text("None").tag(nil as UUID?)
                    ForEach(categories) { cat in
                        Text(cat.name).tag(cat.id as UUID?)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Hourly Rate ($)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Optional (e.g. 75)", text: $hourlyRateText)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Save") {
                    let rate = Double(hourlyRateText)
                    let proj = Project(
                        id: editingId ?? UUID(),
                        name: name.isEmpty ? "New Project" : name,
                        categoryId: categoryId,
                        colorHex: colorHex,
                        hourlyRate: rate
                    )
                    onSave(proj)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}
