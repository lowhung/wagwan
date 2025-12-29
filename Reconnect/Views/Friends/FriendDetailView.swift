import SwiftData
import SwiftUI

struct FriendDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Bindable var friend: Friend

    @State private var showingEditSheet = false
    @State private var showingLogContact = false
    @State private var showingDeleteConfirmation = false
    @State private var showingCallOptions = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.warmGray.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Header with avatar and status
                        headerSection

                        // Quick actions
                        quickActions

                        // Contact info
                        if friend.phoneNumber != nil || friend.email != nil {
                            contactInfoSection
                        }

                        // Stats
                        statsSection

                        // Notes
                        if let notes = friend.notes, !notes.isEmpty {
                            notesSection(notes)
                        }

                        // Contact history
                        historySection

                        // Danger zone
                        deleteButton
                    }
                    .padding(Spacing.md)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color.warmGrayDark)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Text("Edit")
                            .foregroundStyle(Color.coral)
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                AddFriendView(friend: friend)
            }
            .sheet(isPresented: $showingLogContact) {
                LogContactView(friend: friend)
            }
            .confirmationDialog("Contact \(friend.name)", isPresented: $showingCallOptions) {
                if let phone = friend.phoneNumber, let url = URL(string: "tel:\(phone)") {
                    Button("Call") {
                        UIApplication.shared.open(url)
                    }
                    Button("Message") {
                        if let smsUrl = URL(string: "sms:\(phone)") {
                            UIApplication.shared.open(smsUrl)
                        }
                    }
                }
                if let email = friend.email, let url = URL(string: "mailto:\(email)") {
                    Button("Email") {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Delete Friend?", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteFriend()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently remove \(friend.name) and all contact history.")
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: Spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(friend.avatarColor.opacity(0.2))

                if let photoData = friend.photoData,
                    let uiImage = UIImage(data: photoData)
                {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                } else {
                    Text(friend.initials)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(friend.avatarColor)
                }
            }
            .frame(width: 120, height: 120)

            // Name and status
            VStack(spacing: Spacing.xs) {
                Text(friend.name)
                    .font(.displayMedium)
                    .foregroundStyle(Color.warmBlack)

                StatusBadge(status: friend.status)
            }
        }
        .padding(.top, Spacing.md)
    }

    private var quickActions: some View {
        HStack(spacing: Spacing.md) {
            if friend.phoneNumber != nil || friend.email != nil {
                IconButton(icon: "phone.fill", color: .sage, size: 56, accessibilityLabel: "Contact \(friend.name)") {
                    showingCallOptions = true
                }
            }

            PrimaryButton("Log Contact", icon: "checkmark.circle.fill", color: .coral) {
                showingLogContact = true
            }

            IconButton(icon: "calendar.badge.plus", color: .lavender, size: 56, accessibilityLabel: "Add calendar reminder for \(friend.name)") {
                createCalendarReminder()
            }
        }
    }

    private var contactInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Contact Info")
                .font(.headlineSmall)
                .foregroundStyle(Color.warmGrayDark)

            VStack(spacing: Spacing.xs) {
                if let phone = friend.phoneNumber {
                    ContactInfoRow(icon: "phone.fill", value: phone, color: .sage) {
                        if let url = URL(string: "tel:\(phone)") {
                            UIApplication.shared.open(url)
                        }
                    }
                }

                if let email = friend.email {
                    ContactInfoRow(icon: "envelope.fill", value: email, color: .lavender) {
                        if let url = URL(string: "mailto:\(email)") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }
            .padding(Spacing.md)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Stats")
                .font(.headlineSmall)
                .foregroundStyle(Color.warmGrayDark)

            HStack(spacing: Spacing.sm) {
                StatCard(
                    value: friend.daysSinceLastContact.map { "\($0)" } ?? "—",
                    label: "Days since contact",
                    color: .coral
                )

                StatCard(
                    value: "\(friend.contactLogs.count)",
                    label: "Total contacts",
                    color: .sage
                )

                StatCard(
                    value: intervalLabel,
                    label: "Reminder",
                    color: .lavender
                )
            }
        }
    }

    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Notes")
                .font(.headlineSmall)
                .foregroundStyle(Color.warmGrayDark)

            Text(notes)
                .font(.bodyMedium)
                .foregroundStyle(Color.warmBlack)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.md)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Recent Activity")
                .font(.headlineSmall)
                .foregroundStyle(Color.warmGrayDark)

            if friend.contactLogs.isEmpty {
                Text("No contact history yet")
                    .font(.bodyMedium)
                    .foregroundStyle(Color.warmGrayDark)
                    .frame(maxWidth: .infinity)
                    .padding(Spacing.lg)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            } else {
                VStack(spacing: 0) {
                    ForEach(friend.contactLogs.sorted { $0.contactedAt > $1.contactedAt }.prefix(5))
                    { log in
                        HistoryRow(log: log)

                        if log.id
                            != friend.contactLogs.sorted(by: { $0.contactedAt > $1.contactedAt })
                            .prefix(5).last?.id
                        {
                            Divider()
                                .padding(.horizontal, Spacing.md)
                        }
                    }
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            }
        }
    }

    private var deleteButton: some View {
        Button {
            showingDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash.fill")
                Text("Delete Friend")
            }
            .font(.headlineSmall)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(Spacing.md)
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        }
        .padding(.top, Spacing.lg)
    }

    // MARK: - Helpers

    private var intervalLabel: String {
        switch friend.reminderIntervalDays {
        case 7: return "Weekly"
        case 14: return "2 weeks"
        case 30: return "Monthly"
        case 90: return "Quarterly"
        default: return "\(friend.reminderIntervalDays)d"
        }
    }

    private func deleteFriend() {
        modelContext.delete(friend)
        HapticService.shared.impact(.medium)
        dismiss()
    }

    private func createCalendarReminder() {
        Task {
            await CalendarService.shared.createReminder(for: friend)
            HapticService.shared.success()
        }
    }
}

// MARK: - Supporting Views

private struct ContactInfoRow: View {
    let icon: String
    let value: String
    let color: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.bodyMedium)
                    .foregroundStyle(color)
                    .frame(width: 24)

                Text(value)
                    .font(.bodyMedium)
                    .foregroundStyle(Color.warmBlack)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.labelSmall)
                    .foregroundStyle(Color.warmGrayDark)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct StatCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Text(value)
                .font(.displaySmall)
                .foregroundStyle(color)

            Text(label)
                .font(.labelSmall)
                .foregroundStyle(Color.warmGrayDark)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.sm)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
}

private struct HistoryRow: View {
    let log: ContactLog

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: log.method.icon)
                .font(.bodyMedium)
                .foregroundStyle(Color.coral)
                .frame(width: 32, height: 32)
                .background(Color.coral.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(log.method.label)
                    .font(.bodyMedium)
                    .foregroundStyle(Color.warmBlack)

                Text(log.contactedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.labelSmall)
                    .foregroundStyle(Color.warmGrayDark)
            }

            Spacer()
        }
        .padding(Spacing.md)
    }
}

// MARK: - Log Contact View

struct LogContactView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let friend: Friend

    @State private var selectedMethod: ContactMethod = .call
    @State private var notes = ""
    @State private var contactDate = Date()
    @State private var showConfetti = false
    @FocusState private var isNotesFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.warmGray.ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    // Method picker
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("How did you connect?")
                            .font(.headlineSmall)
                            .foregroundStyle(Color.warmGrayDark)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: Spacing.xs)
                        {
                            ForEach(ContactMethod.allCases) { method in
                                MethodButton(
                                    method: method,
                                    isSelected: selectedMethod == method
                                ) {
                                    withAnimation(reduceMotion ? .none : .bounce) {
                                        selectedMethod = method
                                    }
                                }
                            }
                        }
                    }

                    // Date picker
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("When?")
                            .font(.headlineSmall)
                            .foregroundStyle(Color.warmGrayDark)

                        DatePicker(
                            "",
                            selection: $contactDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .tint(.coral)
                        .padding(Spacing.sm)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Notes (optional)")
                            .font(.headlineSmall)
                            .foregroundStyle(Color.warmGrayDark)

                        TextField("What did you talk about?", text: $notes, axis: .vertical)
                            .font(.bodyMedium)
                            .lineLimit(2...4)
                            .padding(Spacing.sm)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.medium)
                                    .stroke(isNotesFocused ? Color.coral.opacity(0.5) : Color.clear, lineWidth: 2)
                            )
                            .focused($isNotesFocused)
                            .submitLabel(.done)
                            .onSubmit { isNotesFocused = false }
                    }

                    Spacer()

                    PrimaryButton("Log Contact", icon: "checkmark.circle.fill") {
                        logContact()
                    }
                }
                .padding(Spacing.md)
                .onTapGesture {
                    isNotesFocused = false
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Log Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.warmGrayDark)
                }
            }
            .confettiCelebration(isActive: $showConfetti) {
                dismiss()
            }
        }
    }

    private func logContact() {
        let log = ContactLog(
            contactedAt: contactDate,
            method: selectedMethod,
            notes: notes.isEmpty ? nil : notes
        )
        log.friend = friend
        friend.contactLogs.append(log)
        friend.lastContactedAt = contactDate

        HapticService.shared.success()
        showConfetti = true
    }
}

private struct MethodButton: View {
    let method: ContactMethod
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xxs) {
                Image(systemName: method.icon)
                    .font(.title3)
                Text(method.label)
                    .font(.labelSmall)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(isSelected ? Color.coral : Color.white)
            .foregroundStyle(isSelected ? .white : Color.warmGrayDark)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FriendDetailView(
        friend: {
            let f = Friend(
                name: "Sarah Chen", phoneNumber: "555-1234", email: "sarah@example.com",
                notes: "Met at the coffee shop. Loves hiking and photography.",
                reminderIntervalDays: 14)
            f.lastContactedAt = Calendar.current.date(byAdding: .day, value: -10, to: Date())
            return f
        }()
    )
    .modelContainer(for: [Friend.self, ContactLog.self], inMemory: true)
}
