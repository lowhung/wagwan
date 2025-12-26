import SwiftData
import SwiftUI

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
                LinearGradient.warmBackground.ignoresSafeArea()

                if friends.isEmpty {
                    EmptyFriendsView {
                        showingAddFriend = true
                    }
                } else if filteredFriends.isEmpty {
                    NoSearchResultsView(searchText: searchText)
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

// MARK: - Empty Friends View

private struct EmptyFriendsView: View {
    var onAddFriend: () -> Void

    @State private var isAnimating = false
    @State private var heartsVisible = false

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Playful illustration using SF Symbols and shapes
            ZStack {
                // Background decorative circles
                Circle()
                    .fill(Color.lavender.opacity(0.3))
                    .frame(width: 160, height: 160)
                    .scaleEffect(isAnimating ? 1.05 : 1.0)

                Circle()
                    .fill(Color.coralLight.opacity(0.4))
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 0.95 : 1.0)

                // Main icon
                Image(systemName: "person.2.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.coral, Color.coralDark],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .offset(y: isAnimating ? -3 : 3)

                // Floating hearts
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(floatingHeartColor(for: index))
                        .offset(floatingHeartOffset(for: index))
                        .opacity(heartsVisible ? 1 : 0)
                        .scaleEffect(heartsVisible ? 1 : 0.5)
                }

                // Sparkles
                Image(systemName: "sparkle")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.sunflower)
                    .offset(x: 55, y: -35)
                    .opacity(isAnimating ? 1 : 0.5)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)

                Image(systemName: "sparkle")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.sage)
                    .offset(x: -50, y: -40)
                    .opacity(isAnimating ? 0.5 : 1)
                    .scaleEffect(isAnimating ? 0.8 : 1.2)
            }
            .frame(height: 180)

            VStack(spacing: Spacing.sm) {
                Text("Your friend list is waiting to bloom")
                    .font(.displaySmall)
                    .foregroundStyle(Color.warmBlack)
                    .multilineTextAlignment(.center)

                Text("Add someone special to stay connected with")
                    .font(.bodyMedium)
                    .foregroundStyle(Color.warmGrayDark)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.lg)

            PrimaryButton("Add Your First Friend", icon: "plus") {
                onAddFriend()
            }
            .frame(maxWidth: 280)
        }
        .padding(Spacing.xl)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.3)) {
                heartsVisible = true
            }
        }
    }

    private func floatingHeartColor(for index: Int) -> Color {
        let colors: [Color] = [.coral, .lavenderDark, .sage]
        return colors[index % colors.count]
    }

    private func floatingHeartOffset(for index: Int) -> CGSize {
        let offsets: [CGSize] = [
            CGSize(width: -45, height: -20),
            CGSize(width: 50, height: -10),
            CGSize(width: 0, height: -55),
        ]
        return offsets[index % offsets.count]
    }
}

// MARK: - No Search Results View

private struct NoSearchResultsView: View {
    let searchText: String

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Playful magnifying glass illustration
            ZStack {
                // Background circle
                Circle()
                    .fill(Color.sageLight.opacity(0.4))
                    .frame(width: 140, height: 140)

                // Magnifying glass with friendly face
                ZStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 60, weight: .light))
                        .foregroundStyle(Color.warmGrayDark)
                        .rotationEffect(.degrees(isAnimating ? -5 : 5))

                    // Friendly question marks floating around
                    Image(systemName: "questionmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.coral.opacity(0.7))
                        .offset(x: 35, y: -25)
                        .scaleEffect(isAnimating ? 1.1 : 0.9)

                    Image(systemName: "questionmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.lavenderDark.opacity(0.7))
                        .offset(x: -30, y: -30)
                        .scaleEffect(isAnimating ? 0.9 : 1.1)
                }
            }
            .frame(height: 160)

            VStack(spacing: Spacing.sm) {
                Text("No friends found")
                    .font(.displaySmall)
                    .foregroundStyle(Color.warmBlack)

                if searchText.isEmpty {
                    Text("Try adjusting your filters")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.warmGrayDark)
                        .multilineTextAlignment(.center)
                } else {
                    Text("No one matches \"\(searchText)\"")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.warmGrayDark)
                        .multilineTextAlignment(.center)

                    Text("Try a different search term")
                        .font(.bodySmall)
                        .foregroundStyle(Color.warmGrayDark.opacity(0.8))
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
        .padding(Spacing.xl)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}

#Preview("Empty Friends") {
    ZStack {
        LinearGradient.warmBackground.ignoresSafeArea()
        EmptyFriendsView {
            print("Add friend tapped")
        }
    }
}

#Preview("No Search Results") {
    ZStack {
        LinearGradient.warmBackground.ignoresSafeArea()
        NoSearchResultsView(searchText: "John")
    }
}

#Preview("Full List") {
    FriendListView()
        .modelContainer(for: [Friend.self, ContactLog.self], inMemory: true)
}
