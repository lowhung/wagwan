import SwiftUI
import SwiftData

struct FriendListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Friend.name) private var friends: [Friend]

    @State private var showingAddFriend = false
    @State private var selectedFriend: Friend?
    @State private var searchText = ""
    @State private var selectedFilter: FilterOption = .all

    enum FilterOption: String, CaseIterable {
        case all = "All"
        case overdue = "Overdue"
        case dueSoon = "Due Soon"
        case onTrack = "On Track"
    }

    private var filteredFriends: [Friend] {
        var result = friends

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        // Apply status filter
        switch selectedFilter {
        case .all:
            break
        case .overdue:
            result = result.filter { $0.status == .overdue }
        case .dueSoon:
            result = result.filter { $0.status == .dueSoon }
        case .onTrack:
            result = result.filter { $0.status == .onTrack }
        }

        // Sort by status priority, then by days until due
        return result.sorted { friend1, friend2 in
            if friend1.status.sortOrder != friend2.status.sortOrder {
                return friend1.status.sortOrder < friend2.status.sortOrder
            }
            return friend1.daysUntilDue < friend2.daysUntilDue
        }
    }

    private var statusCounts: (overdue: Int, dueSoon: Int, onTrack: Int) {
        let overdue = friends.filter { $0.status == .overdue }.count
        let dueSoon = friends.filter { $0.status == .dueSoon }.count
        let onTrack = friends.filter { $0.status == .onTrack }.count
        return (overdue, dueSoon, onTrack)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.warmGray.ignoresSafeArea()

                if friends.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: Spacing.md) {
                            // Status summary
                            statusSummary

                            // Filter pills
                            filterPills

                            // Friend list
                            LazyVStack(spacing: Spacing.sm) {
                                ForEach(filteredFriends) { friend in
                                    FriendCard(friend: friend) {
                                        selectedFriend = friend
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.bottom, Spacing.xxl)
                    }
                }
            }
            .navigationTitle("Friends")
            .searchable(text: $searchText, prompt: "Search friends")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddFriend = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.coral)
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(Color.warmGrayDark)
                    }
                }
            }
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView()
            }
            .sheet(item: $selectedFriend) { friend in
                FriendDetailView(friend: friend)
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.coral.opacity(0.5))

            VStack(spacing: Spacing.xs) {
                Text("No friends yet")
                    .font(.displaySmall)
                    .foregroundStyle(Color.warmBlack)

                Text("Add someone you want to stay in touch with")
                    .font(.bodyMedium)
                    .foregroundStyle(Color.warmGrayDark)
                    .multilineTextAlignment(.center)
            }

            PrimaryButton("Add Your First Friend", icon: "plus") {
                showingAddFriend = true
            }
            .frame(maxWidth: 280)
        }
        .padding(Spacing.xl)
    }

    private var statusSummary: some View {
        HStack(spacing: Spacing.sm) {
            StatusSummaryCard(
                count: statusCounts.overdue,
                label: "Overdue",
                color: .statusOverdue
            )

            StatusSummaryCard(
                count: statusCounts.dueSoon,
                label: "Due Soon",
                color: .statusDueSoon
            )

            StatusSummaryCard(
                count: statusCounts.onTrack,
                label: "On Track",
                color: .statusOnTrack
            )
        }
    }

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(FilterOption.allCases, id: \.self) { option in
                    FilterPill(
                        title: option.rawValue,
                        isSelected: selectedFilter == option
                    ) {
                        withAnimation(.snappy) {
                            selectedFilter = option
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

private struct StatusSummaryCard: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Text("\(count)")
                .font(.displayMedium)
                .foregroundStyle(color)

            Text(label)
                .font(.labelSmall)
                .foregroundStyle(Color.warmGrayDark)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .softShadow()
    }
}

private struct FilterPill: View {
    let title: String
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.labelMedium)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(isSelected ? Color.coral : Color.white)
                .foregroundStyle(isSelected ? .white : Color.warmGrayDark)
                .clipShape(Capsule())
                .softShadow()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FriendListView()
        .modelContainer(for: [Friend.self, ContactLog.self], inMemory: true)
}
