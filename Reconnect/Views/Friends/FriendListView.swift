import SwiftData
import SwiftUI

struct FriendListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Friend.name) private var friends: [Friend]

    @State private var showingAddFriend = false
    @State private var selectedFriend: Friend?
    @State private var searchText = ""
    @State private var selectedFilter: FilterOption = .all
    @State private var showingRefreshMessage = false

    enum FilterOption: String, CaseIterable {
        case all = "All"
        case overdue = "Overdue"
        case dueSoon = "Due Soon"
        case onTrack = "On Track"

        var icon: String? {
            switch self {
            case .all:
                return "square.grid.2x2"
            case .overdue:
                return "exclamationmark.triangle.fill"
            case .dueSoon:
                return "clock.fill"
            case .onTrack:
                return "checkmark.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .all:
                return .coral
            case .overdue:
                return .statusOverdue
            case .dueSoon:
                return .statusDueSoon
            case .onTrack:
                return .statusOnTrack
            }
        }
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

    // Helper to determine if empty is due to search vs filter
    private var isEmptyDueToSearch: Bool {
        !searchText.isEmpty && filteredFriends.isEmpty
    }

    private var isEmptyDueToFilter: Bool {
        searchText.isEmpty && selectedFilter != .all && filteredFriends.isEmpty
    }

    private var emptyFilterMessage: String {
        switch selectedFilter {
        case .overdue:
            return "No overdue friends – you're on top of things!"
        case .dueSoon:
            return "No friends due soon – nice!"
        case .onTrack:
            return "No on track friends right now"
        case .all:
            return ""
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AdaptiveBackground()

                if friends.isEmpty {
                    EmptyFriendsView {
                        showingAddFriend = true
                    }
                } else if isEmptyDueToSearch {
                    NoSearchResultsView(searchText: searchText)
                } else {
                    ScrollView {
                        VStack(spacing: Spacing.md) {
                            // Welcome greeting
                            WelcomeHeader(statusCounts: statusCounts)

                            // Status summary
                            statusSummary

                            // Filter pills
                            filterPills

                            // Friend list or empty filter message
                            if isEmptyDueToFilter {
                                EmptyFilterView(
                                    message: emptyFilterMessage,
                                    filterOption: selectedFilter
                                ) {
                                    withAnimation(.snappy) {
                                        selectedFilter = .all
                                    }
                                }
                            } else {
                                LazyVStack(spacing: Spacing.sm) {
                                    ForEach(Array(filteredFriends.enumerated()), id: \.element.id) { index, friend in
                                        FriendCard(
                                            friend: friend,
                                            onTap: {
                                                selectedFriend = friend
                                            },
                                            onLogContact: {
                                                quickLogContact(for: friend)
                                            },
                                            onCall: friend.phoneNumber != nil ? {
                                                callFriend(friend)
                                            } : nil,
                                            onMessage: friend.phoneNumber != nil ? {
                                                messageFriend(friend)
                                            } : nil
                                        )
                                        .transition(
                                            .asymmetric(
                                                insertion: .scale(scale: 0.9).combined(with: .opacity),
                                                removal: .scale(scale: 0.9).combined(with: .opacity)
                                            )
                                        )
                                    }
                                }
                                .animation(reduceMotion ? .none : .spring(response: 0.4, dampingFraction: 0.8), value: filteredFriends.map(\.id))
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.bottom, Spacing.xxl)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .refreshable {
                        await refreshFriends()
                    }
                }
            }
            .navigationTitle("Friends")
            .searchable(text: $searchText, prompt: "Search friends")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        HapticService.shared.buttonTap()
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
            .overlay(alignment: .top) {
                if showingRefreshMessage {
                    RefreshMessageView()
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Subviews

    private var statusSummary: some View {
        HStack(spacing: Spacing.sm) {
            StatusSummaryCard(
                count: statusCounts.overdue,
                label: "Overdue",
                color: .statusOverdue,
                icon: "exclamationmark.triangle.fill",
                isSelected: selectedFilter == .overdue
            ) {
                withAnimation(reduceMotion ? .none : .snappy) {
                    selectedFilter = selectedFilter == .overdue ? .all : .overdue
                }
            }

            StatusSummaryCard(
                count: statusCounts.dueSoon,
                label: "Due Soon",
                color: .statusDueSoon,
                icon: "clock.fill",
                isSelected: selectedFilter == .dueSoon
            ) {
                withAnimation(reduceMotion ? .none : .snappy) {
                    selectedFilter = selectedFilter == .dueSoon ? .all : .dueSoon
                }
            }

            StatusSummaryCard(
                count: statusCounts.onTrack,
                label: "On Track",
                color: .statusOnTrack,
                icon: "checkmark.circle.fill",
                isSelected: selectedFilter == .onTrack
            ) {
                withAnimation(reduceMotion ? .none : .snappy) {
                    selectedFilter = selectedFilter == .onTrack ? .all : .onTrack
                }
            }
        }
    }

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(FilterOption.allCases, id: \.self) { option in
                    FilterPill(
                        title: option.rawValue,
                        icon: option.icon,
                        count: countForFilter(option),
                        color: option.color,
                        isSelected: selectedFilter == option,
                        reduceMotion: reduceMotion
                    ) {
                        withAnimation(reduceMotion ? .none : .snappy) {
                            selectedFilter = option
                        }
                    }
                }
            }
        }
    }

    private func countForFilter(_ option: FilterOption) -> Int? {
        switch option {
        case .all:
            return nil
        case .overdue:
            return statusCounts.overdue
        case .dueSoon:
            return statusCounts.dueSoon
        case .onTrack:
            return statusCounts.onTrack
        }
    }

    // MARK: - Quick Actions

    private func quickLogContact(for friend: Friend) {
        let log = ContactLog(contactedAt: Date(), method: .other, notes: nil)
        log.friend = friend
        friend.contactLogs.append(log)
        friend.lastContactedAt = Date()
        HapticService.shared.success()
    }

    private func callFriend(_ friend: Friend) {
        guard let phone = friend.phoneNumber,
              let url = URL(string: "tel:\(phone)") else { return }
        UIApplication.shared.open(url)
    }

    private func messageFriend(_ friend: Friend) {
        guard let phone = friend.phoneNumber,
              let url = URL(string: "sms:\(phone)") else { return }
        UIApplication.shared.open(url)
    }

    private func refreshFriends() async {
        // Add a small delay for the animation to feel natural
        try? await Task.sleep(nanoseconds: 600_000_000)

        // Trigger haptic feedback
        await MainActor.run {
            HapticService.shared.success()

            // Show the refresh message briefly
            withAnimation(.snappy) {
                showingRefreshMessage = true
            }
        }

        // Hide the message after a moment
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        await MainActor.run {
            withAnimation(.snappy) {
                showingRefreshMessage = false
            }
        }
    }
}

// MARK: - Refresh Message View

private struct RefreshMessageView: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.sage)
                .scaleEffect(isAnimating ? 1.0 : 0.5)

            Text("All up to date!")
                .font(.headlineSmall)
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(Color.cardBackground)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.top, Spacing.xl)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Supporting Views

private struct WelcomeHeader: View {
    let statusCounts: (overdue: Int, dueSoon: Int, onTrack: Int)

    private var greeting: (text: String, emoji: String) {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return ("Good morning", "☀️")
        case 12..<17:
            return ("Good afternoon", "🌤")
        case 17..<21:
            return ("Good evening", "🌙")
        default:
            return ("Good night", "✨")
        }
    }

    private var encouragingMessage: String {
        let total = statusCounts.overdue + statusCounts.dueSoon + statusCounts.onTrack

        if total == 0 {
            return "Ready to add some friends?"
        } else if statusCounts.overdue == 0 && statusCounts.dueSoon == 0 {
            return "Everyone's feeling the love!"
        } else if statusCounts.overdue == 0 {
            return "You're staying connected nicely"
        } else if statusCounts.overdue == 1 {
            return "A friend misses you – say hi?"
        } else if statusCounts.overdue <= 3 {
            return "A few friends miss you – why not say hi?"
        } else {
            return "Let's reconnect with some friends today"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(spacing: Spacing.xs) {
                Text(greeting.text)
                    .font(.displaySmall)
                    .foregroundStyle(Color.textPrimary)
                Text(greeting.emoji)
                    .font(.system(size: 22))
            }

            Text(encouragingMessage)
                .font(.bodyMedium)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Spacing.xs)
    }
}

private struct StatusSummaryCard: View {
    let count: Int
    let label: String
    let color: Color
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false
    @State private var previousCount: Int = 0
    @State private var isBouncing = false

    private var isOverdue: Bool {
        label == "Overdue"
    }

    var body: some View {
        Button(action: {
            HapticService.shared.selection()
            action()
        }) {
            VStack(spacing: Spacing.xxs) {
                ZStack {
                    if isOverdue && count > 0 {
                        Circle()
                            .fill(color.opacity(0.2))
                            .frame(width: 36, height: 36)
                            .scaleEffect(isPulsing ? 1.3 : 1.0)
                            .opacity(isPulsing ? 0 : 0.6)
                    }

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(color)
                        .scaleEffect(isBouncing ? 1.2 : 1.0)
                }
                .frame(height: 28)

                Text("\(count)")
                    .font(.displayMedium)
                    .foregroundStyle(color)
                    .scaleEffect(isBouncing ? 1.15 : 1.0)
                    .contentTransition(.numericText())

                Text(label)
                    .font(.labelSmall)
                    .foregroundStyle(Color.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(isSelected ? color.opacity(0.15) : Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
            .softShadow()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label): \(count) friends. Tap to filter.")
        .accessibilityHint(
            isSelected
                ? "Currently filtered" : "Double tap to show only \(label.lowercased()) friends"
        )
        .onAppear {
            previousCount = count
            if isOverdue && count > 0 && !reduceMotion {
                startPulseAnimation()
            }
        }
        .onChange(of: count) { oldValue, newValue in
            if oldValue != newValue && !reduceMotion {
                triggerBounce()
            }
            if isOverdue && !reduceMotion {
                if newValue > 0 && oldValue == 0 {
                    startPulseAnimation()
                }
            }
        }
    }

    private func startPulseAnimation() {
        guard !reduceMotion else { return }
        withAnimation(
            .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: false)
        ) {
            isPulsing = true
        }
    }

    private func triggerBounce() {
        guard !reduceMotion else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            isBouncing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isBouncing = false
            }
        }
    }
}

private struct FilterPill: View {
    let title: String
    let icon: String?
    let count: Int?
    let color: Color
    let isSelected: Bool
    var reduceMotion: Bool = false
    var action: () -> Void

    @State private var isPressed = false

    private var displayColor: Color {
        isSelected ? color : Color.textSecondary
    }

    private var backgroundColor: Color {
        isSelected ? color.opacity(0.15) : Color.cardBackground
    }

    private var borderColor: Color {
        isSelected ? color : Color.clear
    }

    var body: some View {
        Button(action: {
            HapticService.shared.selection()
            action()
        }) {
            HStack(spacing: Spacing.xxs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(displayColor)
                }

                Text(title)
                    .font(.labelMedium)
                    .foregroundStyle(displayColor)

                if let count = count, count > 0 {
                    Text("\(count)")
                        .font(.labelSmall)
                        .foregroundStyle(isSelected ? .white : displayColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? color : color.opacity(0.2))
                        )
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background(backgroundColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(borderColor, lineWidth: 1.5)
            )
            .softShadow()
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title)\(count.map { ", \($0) friends" } ?? "")")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(reduceMotion ? .none : .spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Empty Filter View

private struct EmptyFilterView: View {
    let message: String
    let filterOption: FriendListView.FilterOption
    let onClearFilter: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    private var iconName: String {
        switch filterOption {
        case .overdue:
            return "checkmark.seal.fill"
        case .dueSoon:
            return "clock.badge.checkmark.fill"
        case .onTrack:
            return "person.crop.circle.badge.questionmark.fill"
        case .all:
            return "sparkles"
        }
    }

    private var iconColor: Color {
        switch filterOption {
        case .overdue:
            return .statusOnTrack
        case .dueSoon:
            return .statusOnTrack
        case .onTrack:
            return .warmGrayDark
        case .all:
            return .coral
        }
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 80, height: 80)
                    .scaleEffect(isAnimating ? 1.05 : 1.0)

                Image(systemName: iconName)
                    .font(.system(size: 32))
                    .foregroundStyle(iconColor)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
            }

            Text(message)
                .font(.bodyMedium)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                onClearFilter()
            } label: {
                Text("Show all friends")
                    .font(.labelMedium)
                    .foregroundStyle(Color.coral)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, Spacing.xl)
        .frame(maxWidth: .infinity)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(
                .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Empty Friends View

private struct EmptyFriendsView: View {
    var onAddFriend: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Add someone special to stay connected with")
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textSecondary)
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
            if reduceMotion {
                isAnimating = false
                heartsVisible = true
            } else {
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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                    .foregroundStyle(Color.textPrimary)

                if searchText.isEmpty {
                    Text("Try adjusting your filters")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("No one matches \"\(searchText)\"")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)

                    Text("Try a different search term")
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary.opacity(0.8))
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
        .padding(Spacing.xl)
        .onAppear {
            guard !reduceMotion else { return }
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
