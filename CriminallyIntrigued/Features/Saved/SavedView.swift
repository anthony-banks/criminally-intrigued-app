import SwiftUI
import SwiftData

/// Aggregates bookmarks across all categories (spec §9.5). Offline-capable.
struct SavedView: View {
    @Environment(AppEnvironment.self) private var environment

    @Query(
        filter: #Predicate<CaseEntry> { $0.isBookmarked == true },
        sort: \CaseEntry.title
    )
    private var saved: [CaseEntry]

    var body: some View {
        Group {
            if saved.isEmpty {
                EmptyStateView(
                    systemImage: "bookmark",
                    title: "No saved cases",
                    message: "Swipe a row or tap the bookmark in any article to save it here."
                )
            } else {
                List {
                    ForEach(saved) { entry in
                        NavigationLink(value: entry) {
                            CaseRow(entry: entry)
                        }
                        .listRowBackground(Palette.backgroundPrimary)
                        .swipeActions {
                            Button(role: .destructive) {
                                environment.bookmarks.toggle(entry)
                            } label: {
                                Label("Remove", systemImage: "bookmark.slash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(Palette.backgroundPrimary)
        .navigationTitle("Saved")
        .navigationDestination(for: CaseEntry.self) { DetailView(entry: $0) }
    }
}
