import SwiftUI
import SwiftData

/// One reusable list, parameterized by category (spec §9.1). Reads the local
/// SwiftData store via @Query (reactive to bookmarks/refresh), then applies
/// search/filter/sort locally and instantly.
struct CategoryListView: View {
    @Environment(AppEnvironment.self) private var environment
    let category: Category

    @Query private var entries: [CaseEntry]
    @State private var criteria = FilterCriteria()
    @State private var showingFilters = false

    init(category: Category) {
        self.category = category
        let raw = category.rawValue
        _entries = Query(
            filter: #Predicate<CaseEntry> { $0.categoryRaw == raw },
            sort: \CaseEntry.title
        )
    }

    private var visible: [CaseEntry] { FilterEngine.apply(entries, criteria) }

    var body: some View {
        Group {
            if entries.isEmpty {
                loadingOrEmpty
            } else if visible.isEmpty {
                EmptyStateView(
                    systemImage: "line.3.horizontal.decrease.circle",
                    title: "No matches",
                    message: "No entries match your current search or filters."
                )
            } else {
                List {
                    ForEach(visible) { entry in
                        NavigationLink(value: entry) {
                            CaseRow(entry: entry)
                        }
                        .listRowBackground(Palette.backgroundPrimary)
                        .swipeActions(edge: .leading) {
                            Button {
                                environment.bookmarks.toggle(entry)
                            } label: {
                                Label(
                                    entry.isBookmarked ? "Remove" : "Save",
                                    systemImage: entry.isBookmarked ? "bookmark.slash" : "bookmark"
                                )
                            }
                            .tint(Palette.accentOlive)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(Palette.backgroundPrimary)
        .navigationTitle(category.title)
        .navigationDestination(for: CaseEntry.self) { DetailView(entry: $0) }
        .searchable(text: $criteria.searchText, prompt: "Search \(category.title)")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingFilters = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle\(criteria.activeFilterCount > 0 ? ".fill" : "")")
                }
                .accessibilityLabel("Filters\(criteria.activeFilterCount > 0 ? ", \(criteria.activeFilterCount) active" : "")")
            }
        }
        .sheet(isPresented: $showingFilters) {
            FilterSheet(criteria: $criteria, availableCountries: FilterEngine.availableCountries(entries))
        }
    }

    @ViewBuilder private var loadingOrEmpty: some View {
        // Seed loads synchronously on first launch, so an empty store here means
        // genuinely no data rather than a spinner-worthy wait — but show skeletons
        // briefly in case a refresh is repopulating.
        List {
            ForEach(0..<8, id: \.self) { _ in
                SkeletonRow().listRowBackground(Palette.backgroundPrimary)
            }
        }
        .listStyle(.plain)
    }
}
