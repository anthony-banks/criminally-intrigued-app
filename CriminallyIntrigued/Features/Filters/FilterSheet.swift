import SwiftUI

/// Single filter + sort sheet shared by every list (spec §9.3). Filters compose
/// and can be reset; unknown-data entries are handled by FilterEngine.
struct FilterSheet: View {
    @Binding var criteria: FilterCriteria
    let availableCountries: [String]

    @Environment(\.dismiss) private var dismiss

    private let victimThresholds = [1, 5, 10, 20, 50]

    var body: some View {
        NavigationStack {
            Form {
                Section("Sort") {
                    Picker("Order", selection: $criteria.sort) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Victim count") {
                    Picker("Minimum", selection: $criteria.minVictimCount) {
                        Text("Any").tag(Int?.none)
                        ForEach(victimThresholds, id: \.self) { value in
                            Text("\(value)+").tag(Int?.some(value))
                        }
                    }
                    Text("Entries without a recorded count are hidden when a minimum is set.")
                        .font(.caption)
                        .foregroundStyle(Palette.labelSecondary)
                }

                if !availableCountries.isEmpty {
                    Section("Country") {
                        ForEach(availableCountries, id: \.self) { country in
                            Button {
                                toggleCountry(country)
                            } label: {
                                HStack {
                                    Text(country).foregroundStyle(Palette.labelPrimary)
                                    Spacer()
                                    if criteria.countries.contains(country) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Palette.accentOlive)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") { criteria = FilterCriteria(searchText: criteria.searchText) }
                        .disabled(!criteria.isActive)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func toggleCountry(_ country: String) {
        if criteria.countries.contains(country) {
            criteria.countries.remove(country)
        } else {
            criteria.countries.insert(country)
        }
    }
}
