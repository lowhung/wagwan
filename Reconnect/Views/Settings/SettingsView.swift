import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var friends: [Friend]

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("defaultReminderInterval") private var defaultReminderInterval = 14

    @State private var showingResetConfirmation = false
    @State private var showingExportSheet = false
    @State private var calendarAccessGranted = false
    @State private var showingHelpSheet = false

    @Environment(\.requestReview) private var requestReview

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

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
                        ) {
                            showingHelpSheet = true
                        }

                        SettingsLinkRow(
                            icon: "star.fill",
                            iconColor: .sunflower,
                            title: "Rate Reconnect"
                        ) {
                            requestAppReview()
                        }

                        SettingsLinkRow(
                            icon: "envelope.fill",
                            iconColor: .lavender,
                            title: "Send Feedback"
                        ) {
                            openFeedbackEmail()
                        }

                        SettingsRow(
                            icon: "info.circle.fill",
                            iconColor: .textSecondary,
                            title: "Version",
                            subtitle: ""
                        ) {
                            Text(appVersion)
                                .font(.bodyMedium)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }

                    // Danger zone
                    settingsSection("Data") {
                        Button {
                            HapticService.shared.warning()
                            showingResetConfirmation = true
                        } label: {
                            HStack {
                                Label("Reset Onboarding", systemImage: "arrow.counterclockwise")
                                    .font(.bodyMedium)
                                Spacer()
                            }
                            .foregroundStyle(Color.textPrimary)
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
        .sheet(isPresented: $showingHelpSheet) {
            HelpView()
                .styledSheet()
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
                .foregroundStyle(Color.textPrimary)

            Text("Stay close to who matters")
                .font(.bodyMedium)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.vertical, Spacing.lg)
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.headlineSmall)
                .foregroundStyle(Color.textSecondary)
                .padding(.leading, Spacing.xs)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.cardBackground)
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
                .foregroundStyle(Color.textSecondary)
        }
    }

    // MARK: - Computed Properties

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
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

    private func requestAppReview() {
        requestReview()
    }

    private func openFeedbackEmail() {
        let email = "feedback@reconnect.app"
        let subject = "Reconnect Feedback"
        let body = "\n\n---\nApp Version: \(appVersion)\niOS: \(UIDevice.current.systemVersion)\nDevice: \(UIDevice.current.model)"

        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: "mailto:\(email)?subject=\(subjectEncoded)&body=\(bodyEncoded)") {
            UIApplication.shared.open(url)
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
                    .foregroundStyle(Color.textPrimary)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.labelSmall)
                        .foregroundStyle(Color.textSecondary)
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
    let action: () -> Void

    var body: some View {
        Button {
            HapticService.shared.buttonTap()
            action()
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.bodyMedium)
                    .foregroundStyle(iconColor)
                    .frame(width: 28)

                Text(title)
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.labelMedium)
                    .foregroundStyle(Color.textSecondary)
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
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Text(value)
                .font(.headlineSmall)
                .foregroundStyle(Color.coral)
        }
        .padding(Spacing.md)
    }
}

// MARK: - Help View

private struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        // Header
                        VStack(spacing: Spacing.sm) {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(Color.sage)

                            Text("Help & FAQ")
                                .font(.displaySmall)
                                .foregroundStyle(Color.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, Spacing.md)

                        // FAQ Items
                        FAQItem(
                            question: "How do I add a friend?",
                            answer: "Tap the + button in the top right corner of the main screen. Fill in their name and contact details, then choose how often you'd like to be reminded to reach out."
                        )

                        FAQItem(
                            question: "What do the status colors mean?",
                            answer: "Green (On Track) means you're within your reminder window. Yellow (Due Soon) means it's almost time to reach out. Red (Overdue) means you've passed your reminder date."
                        )

                        FAQItem(
                            question: "How do streaks work?",
                            answer: "Your streak increases each time you log a contact within your reminder interval. If you miss a check-in window, your streak resets. Keep the streak alive to build consistent habits!"
                        )

                        FAQItem(
                            question: "Can I add calendar reminders?",
                            answer: "Yes! Tap on a friend, then tap the calendar icon. This will create an event in your calendar with a reminder. Make sure to grant calendar access in Settings."
                        )

                        FAQItem(
                            question: "How do I log a contact?",
                            answer: "Open a friend's profile and tap 'Log Contact'. Choose how you connected (call, text, in person, etc.), select the date, and optionally add notes about your conversation."
                        )

                        FAQItem(
                            question: "Can I edit or delete a friend?",
                            answer: "Yes! Tap on a friend to open their profile, then tap 'Edit' in the top right to modify their details. To remove them, scroll to the bottom and tap 'Remove from list'."
                        )
                    }
                    .padding(Spacing.md)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color.coral)
                }
            }
        }
    }
}

private struct FAQItem: View {
    let question: String
    let answer: String

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                HapticService.shared.selection()
            } label: {
                HStack {
                    Text(question)
                        .font(.headlineSmall)
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.labelMedium)
                        .foregroundStyle(Color.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(Spacing.md)
            }

            if isExpanded {
                Text(answer)
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textSecondary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.md)
            }
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [Friend.self, ContactLog.self], inMemory: true)
}
