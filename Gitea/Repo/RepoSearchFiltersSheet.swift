import SwiftUI

struct RepoSearchFiltersSheet: View {
    @Binding var filters: RepoSearchFilters
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Sort & Order") {
                Picker("Sort by", selection: $filters.sort) {
                    ForEach(RepoSearchFilters.SortOption.allCases, id: \.self) { option in
                        Text(option == .bestMatch ? "Best Match" : option.rawValue.capitalized)
                            .tag(option)
                    }
                }
                Picker("Order", selection: $filters.order) {
                    ForEach(RepoSearchFilters.OrderOption.allCases, id: \.self) { option in
                        Text(option.rawValue.capitalized).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Type") {
                Picker("Mode", selection: $filters.mode) {
                    ForEach(RepoSearchFilters.ModeFilter.allCases, id: \.self) { option in
                        Text(option == .all ? "All" : option.rawValue.capitalized)
                            .tag(option)
                    }
                }
            }

            Section("Visibility") {
                Picker("Privacy", selection: $filters.isPrivate) {
                    ForEach(RepoSearchFilters.PrivateFilter.allCases, id: \.self) { option in
                        Text(option.rawValue.capitalized).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Archived", selection: Binding(
                    get: { filters.archived.map { $0 ? "archived" : "active" } ?? "all" },
                    set: { value in
                        switch value {
                        case "archived": filters.archived = true
                        case "active": filters.archived = false
                        default: filters.archived = nil
                        }
                    }
                )) {
                    Text("All").tag("all")
                    Text("Active").tag("active")
                    Text("Archived").tag("archived")
                }

                Toggle("Templates", isOn: Binding(
                    get: { filters.template ?? true },
                    set: { filters.template = $0 }
                ))
            }

            Section("Search") {
                Toggle("Limit to topic", isOn: $filters.topic)
                Toggle("Include description", isOn: $filters.includeDesc)
            }

            Section("Pagination") {
                TextField("Page limit", text: $filters.limitText)
                    .keyboardType(.numberPad)
            }
        }
        .navigationTitle("Filters")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Reset") {
                    filters = RepoSearchFilters()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", systemImage: "checkmark") {
                    dismiss()
                }
            }
        }
    }
}
