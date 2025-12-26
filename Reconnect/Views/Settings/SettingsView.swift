import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var friends: [Friend]

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("defaultReminderInterval") private var defaultReminderInterval = 14

    @State private var showingResetConfirmation = false
    @State private var showingExportSheet = false
    @State private var calendarAccessGranted = false

    var body: some View {
        ZStack {
            Color.warmGray.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // App info header
                    appHeader

                    // Preferences section
                    settingsSection("Preferences") {
                        SettingsRow(
                            icon: "bell.fill",
                            iconColor: .sunflower,
                            title: "Default Reminder",
                            subtitle: ReminderInterval(rawValue: defaultReminderInterval)?.label ?? "Every 2 weeks"
                        ) {
                            reminderPicker
                        }

                        SettingsRow(
                            icon: "calendar",
                            iconColor: .lavender,
                            title: "Calendar Access",
                            subtitle: calendarAccessGranted ? "Granted" : "Not granted"
                        ) {
                            Button("Request Access") {
                                requestCalendarAccess()
                            }
                            .font(.labelMedium)
                            .foregroundStyle(Color.coral)
                        }
                    }

                    // Stats section
                    settingsSection("Your Stats") {
                        StatRow(label: "Total Friends", value: "\(friends.count)")
                        StatRow(label: "Overdue", value: "\(friends.filter { $0.status == .overdue }.count)")
                        StatRow(label: "On Track", value: "\(friends.filter { $0.status == .onTrack }.count)")
                        StatRow(label: "Total Contacts Logged", value: "\(friends.reduce(0) { $0 + $1.contactLogs.count })")
                    }

                    // About section
                    settingsSection("About") {
                        SettingsLinkRow(
                            icon: "questionmark.circle.fill",
                            iconColor: .sage,
                            title: "Help & FAQ"
                        )

                        SettingsLinkRow(
                            icon: "star.fill",
                            iconColor: .sunflower,
                            title: "Rate Reconnect"
                        )

                        SettingsLinkRow(
                            icon: "envelope.fill",
                            iconColor: .lavender,
                            title: "Send Feedback"
                        )

                        SettingsRow(
                            icon: "info.circle.fill",
                            iconColor: .warmGrayDark,
                            title: "Version",
                            subtitle: ""
                        ) {
                            Text("1.0.0")
                                .font(.bodyMedium)
                                .foregroundStyle(Color.warmGrayDark)
                        }
                    }

                    // Danger zone
                    settingsSection("Data") {
                        Button {
                            showingResetConfirmation = true
                        } label: {
                            HStack {
                                Label("Reset Onboarding", systemImage: "arrow.counterclockwise")
                                    .font(.bodyMedium)
                                Spacer()
                            }
                            .foregroundStyle(Color.warmBlack)
                            .padding(Spacing.md)
                        }
                    }
                }
                .padding(Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkCalendarAccess()
        }
        .alert("Reset Onboarding?", isPresented: $showingResetConfirmation) {
            Button("Reset", role: .destructive) {
                hasCompletedOnboarding = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will show the onboarding screens again the next time you open the app.")
        }
    }

    // MARK: - Subviews

    private var appHeader: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.coral.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "heart.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.coral)
            }

            Text("Reconnect")
                .font(.displaySmall)
                .foregroundStyle(Color.warmBlack)

            Text("Stay close to who matters")
                .font(.bodyMedium)
                .foregroundStyle(Color.warmGrayDark)
        }
        .padding(.vertical, Spacing.lg)
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.headlineSmall)
                .foregroundStyle(Color.warmGrayDark)
                .padding(.leading, Spacing.xs)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        }
    }

    private var reminderPicker: some View {
        Menu {
            ForEach(ReminderInterval.allCases) { interval in
                Button {
                    defaultReminderInterval = interval.rawValue
                    HapticService.shared.selection()
                } label: {
                    if interval.rawValue == defaultReminderInterval {
                        Label(interval.label, systemImage: "checkmark")
                    } else {
                        Text(interval.label)
                    }
                }
            }
        } label: {
            Image(systemName: "chevron.right")
                .font(.labelMedium)
                .foregroundStyle(Color.warmGrayDark)
        }
    }

    // MARK: - Actions

    private func checkCalendarAccess() {
        calendarAccessGranted = CalendarService.shared.authorizationStatus == .fullAccess
    }

    private func requestCalendarAccess() {
        Task {
            calendarAccessGranted = await CalendarService.shared.requestAccess()
            if calendarAccessGranted {
                HapticService.shared.success()
            }
        }
    }
}

// MARK: - Supporting Views

private struct SettingsRow<Accessory: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @ViewBuilder let accessory: () -> Accessory

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.bodyMedium)
                .foregroundStyle(iconColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.bodyMedium)
                    .foregroundStyle(Color.warmBlack)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.labelSmall)
                        .foregroundStyle(Color.warmGrayDark)
                }
            }

            Spacer()

            accessory()
        }
        .padding(Spacing.md)
    }
}

private struct SettingsLinkRow: View {
    let icon: String
    let iconColor: Color
    let title: String

    var body: some View {
        Button {
            // TODO: Implement navigation
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.bodyMedium)
                    .foregroundStyle(iconColor)
                    .frame(width: 28)

                Text(title)
                    .font(.bodyMedium)
                    .foregroundStyle(Color.warmBlack)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.labelMedium)
                    .foregroundStyle(Color.warmGrayDark)
            }
            .padding(Spacing.md)
        }
    }
}

private struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.bodyMedium)
                .foregroundStyle(Color.warmBlack)

            Spacer()

            Text(value)
                .font(.headlineSmall)
                .foregroundStyle(Color.coral)
        }
        .padding(Spacing.md)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [Friend.self, ContactLog.self], inMemory: true)
}
