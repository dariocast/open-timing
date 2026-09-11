import SwiftUI

public enum CategoryProjectSheet: Identifiable {
    case addCategory
    case editCategory(ActivityCategory)
    case addProject
    case editProject(Project)
    
    public var id: String {
        switch self {
        case .addCategory:
            return "add_cat"
        case .editCategory(let cat):
            return "edit_cat_\(cat.id)"
        case .addProject:
            return "add_proj"
        case .editProject(let proj):
            return "edit_proj_\(proj.id)"
        }
    }
}

public struct CategoriesProjectsView: View {
    @ObservedObject var appState: AppState
    @State private var selectedTab: Int = 0
    @State private var activeSheet: CategoryProjectSheet?
    
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
                    Button(action: { activeSheet = .addCategory }) {
                        Label("Add Category", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(action: { activeSheet = .addProject }) {
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
                                    .frame(width: 34, height: 34)
                                Image(systemName: category.iconName)
                                    .foregroundColor(Color(hex: category.colorHex))
                                    .font(.system(size: 15, weight: .semibold))
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
                                activeSheet = .editCategory(category)
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
                            activeSheet = .addProject
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
                                        .frame(width: 34, height: 34)
                                    Image(systemName: project.iconName)
                                        .foregroundColor(Color(hex: project.colorHex))
                                        .font(.system(size: 15, weight: .semibold))
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
                                    activeSheet = .editProject(project)
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
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .addCategory:
                CategoryEditSheet(category: nil) { newCat in
                    appState.saveCategory(newCat)
                }
            case .editCategory(let cat):
                CategoryEditSheet(category: cat) { updatedCat in
                    appState.saveCategory(updatedCat)
                }
            case .addProject:
                ProjectEditSheet(project: nil, categories: appState.categories) { newProj in
                    appState.saveProject(newProj)
                }
            case .editProject(let proj):
                ProjectEditSheet(project: proj, categories: appState.categories) { updatedProj in
                    appState.saveProject(updatedProj)
                }
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
    @State private var selectedColor: Color
    
    let editingId: UUID?
    let onSave: (ActivityCategory) -> Void
    
    let presetIcons = [
        "chevron.left.forwardslash.chevron.right",
        "paintpalette.fill",
        "doc.text.fill",
        "bubble.left.and.bubble.right.fill",
        "gearshape.fill",
        "tv.fill",
        "briefcase.fill",
        "chart.xyaxis.line",
        "gamecontroller.fill",
        "cart.fill",
        "book.fill",
        "music.note",
        "globe",
        "envelope.fill",
        "hammer.fill",
        "folder.fill"
    ]
    
    let presetColors = [
        "#0A84FF", // Blue
        "#BF5AF2", // Purple
        "#5E5CE6", // Indigo
        "#30D158", // Green
        "#FF9F0A", // Orange
        "#FF453A", // Red
        "#64D2FF", // Cyan
        "#FF375F", // Pink
        "#8E8E93", // Gray
        "#FFD60A"  // Yellow
    ]
    
    init(category: ActivityCategory?, onSave: @escaping (ActivityCategory) -> Void) {
        self.editingId = category?.id
        let initialHex = category?.colorHex ?? "#0A84FF"
        _name = State(initialValue: category?.name ?? "")
        _colorHex = State(initialValue: initialHex)
        _iconName = State(initialValue: category?.iconName ?? "folder.fill")
        _productivityScore = State(initialValue: category?.productivityScore ?? 0)
        _selectedColor = State(initialValue: Color(hex: initialHex))
        self.onSave = onSave
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header with Preview
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: colorHex).opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: iconName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: colorHex))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(editingId == nil ? "New Category" : "Edit Category")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text(name.isEmpty ? "Category Name Preview" : name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.bottom, 4)
            
            Divider()
            
            // Name Field
            VStack(alignment: .leading, spacing: 6) {
                Text("Category Name")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                TextField("e.g. Software Development", text: $name)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Productivity Level
            VStack(alignment: .leading, spacing: 6) {
                Text("Productivity Score")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Picker("", selection: $productivityScore) {
                    Label("Very Productive (+2)", systemImage: "sparkles").tag(2)
                    Label("Productive (+1)", systemImage: "arrow.up.circle.fill").tag(1)
                    Label("Neutral (0)", systemImage: "minus.circle.fill").tag(0)
                    Label("Distracting (-1)", systemImage: "arrow.down.circle.fill").tag(-1)
                    Label("Very Distracting (-2)", systemImage: "flame.fill").tag(-2)
                }
                .pickerStyle(.menu)
            }
            
            // Color Palette & ColorPicker
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Color")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Spacer()
                    ColorPicker("Custom", selection: $selectedColor, supportsOpacity: false)
                        .labelsHidden()
                        .onChange(of: selectedColor) { _, newColor in
                            colorHex = newColor.toHex()
                        }
                }
                
                HStack(spacing: 8) {
                    ForEach(presetColors, id: \.self) { hex in
                        Button(action: {
                            colorHex = hex
                            selectedColor = Color(hex: hex)
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 24, height: 24)
                                if colorHex.uppercased() == hex.uppercased() {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Icon Picker Grid
            VStack(alignment: .leading, spacing: 8) {
                Text("Icon")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 8), spacing: 8) {
                    ForEach(presetIcons, id: \.self) { icon in
                        Button(action: {
                            iconName = icon
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(iconName == icon ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(iconName == icon ? Color.accentColor : Color.clear, lineWidth: 1.5)
                                    )
                                Image(systemName: icon)
                                    .font(.system(size: 14))
                                    .foregroundColor(iconName == icon ? .accentColor : .primary)
                            }
                            .frame(height: 32)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Spacer()
            
            Divider()
            
            // Buttons
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save Category") {
                    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    let finalName = trimmedName.isEmpty ? "New Category" : trimmedName
                    let cat = ActivityCategory(
                        id: editingId ?? UUID(),
                        name: finalName,
                        colorHex: colorHex,
                        iconName: iconName,
                        productivityScore: productivityScore
                    )
                    onSave(cat)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 460, height: 480)
    }
}

// MARK: - Project Edit Sheet

struct ProjectEditSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var name: String
    @State private var colorHex: String
    @State private var categoryId: UUID?
    @State private var hourlyRateText: String
    @State private var selectedColor: Color
    
    let editingId: UUID?
    let categories: [ActivityCategory]
    let onSave: (Project) -> Void
    
    let presetColors = [
        "#0A84FF", "#BF5AF2", "#5E5CE6", "#30D158", "#FF9F0A", "#FF453A", "#64D2FF", "#FF375F", "#8E8E93"
    ]
    
    init(project: Project?, categories: [ActivityCategory], onSave: @escaping (Project) -> Void) {
        self.editingId = project?.id
        self.categories = categories
        let initialHex = project?.colorHex ?? "#0A84FF"
        _name = State(initialValue: project?.name ?? "")
        _colorHex = State(initialValue: initialHex)
        _categoryId = State(initialValue: project?.categoryId)
        _hourlyRateText = State(initialValue: project?.hourlyRate.map { String($0) } ?? "")
        _selectedColor = State(initialValue: Color(hex: initialHex))
        self.onSave = onSave
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(editingId == nil ? "New Project" : "Edit Project")
                .font(.title3)
                .fontWeight(.bold)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Project Name")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                TextField("e.g. Website Redesign", text: $name)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Associated Category")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Picker("", selection: $categoryId) {
                    Text("None").tag(nil as UUID?)
                    ForEach(categories) { cat in
                        HStack {
                            Circle().fill(Color(hex: cat.colorHex)).frame(width: 8, height: 8)
                            Text(cat.name)
                        }.tag(cat.id as UUID?)
                    }
                }
                .pickerStyle(.menu)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Hourly Rate ($ / hour)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                TextField("e.g. 80.00", text: $hourlyRateText)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Color")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                HStack(spacing: 8) {
                    ForEach(presetColors, id: \.self) { hex in
                        Button(action: {
                            colorHex = hex
                            selectedColor = Color(hex: hex)
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 24, height: 24)
                                if colorHex.uppercased() == hex.uppercased() {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Spacer()
            
            Divider()
            
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save Project") {
                    let rate = Double(hourlyRateText)
                    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    let finalName = trimmedName.isEmpty ? "New Project" : trimmedName
                    let proj = Project(
                        id: editingId ?? UUID(),
                        name: finalName,
                        categoryId: categoryId,
                        colorHex: colorHex,
                        hourlyRate: rate
                    )
                    onSave(proj)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 440, height: 400)
    }
}
