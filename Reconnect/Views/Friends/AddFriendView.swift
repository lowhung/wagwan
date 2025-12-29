import SwiftUI
import SwiftData
import PhotosUI

struct AddFriendView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var notes = ""
    @State private var selectedInterval: ReminderInterval = .biweekly
    @State private var showingValidationError = false

    // Photo picker state
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var isAvatarBouncing = false

    var existingFriend: Friend?

    private var isEditing: Bool { existingFriend != nil }

    init(friend: Friend? = nil) {
        self.existingFriend = friend
        if let friend = friend {
            _name = State(initialValue: friend.name)
            _phoneNumber = State(initialValue: friend.phoneNumber ?? "")
            _email = State(initialValue: friend.email ?? "")
            _notes = State(initialValue: friend.notes ?? "")
            _selectedInterval = State(initialValue: ReminderInterval(rawValue: friend.reminderIntervalDays) ?? .biweekly)
            _selectedPhotoData = State(initialValue: friend.photoData)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.warmGray.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Avatar preview
                        avatarPreview

                        // Form fields
                        VStack(spacing: Spacing.md) {
                            FormField(
                                title: "Name",
                                placeholder: "Friend's name",
                                text: $name,
                                icon: "person.fill"
                            )

                            FormField(
                                title: "Phone",
                                placeholder: "Phone number (optional)",
                                text: $phoneNumber,
                                icon: "phone.fill",
                                keyboardType: .phonePad
                            )

                            FormField(
                                title: "Email",
                                placeholder: "Email address (optional)",
                                text: $email,
                                icon: "envelope.fill",
                                keyboardType: .emailAddress
                            )

                            // Reminder interval picker
                            intervalPicker

                            FormField(
                                title: "Notes",
                                placeholder: "Any notes about this friend (optional)",
                                text: $notes,
                                icon: "note.text",
                                isMultiline: true
                            )
                        }
                        .padding(.horizontal, Spacing.md)

                        // Save button
                        PrimaryButton(
                            isEditing ? "Save Changes" : "Add Friend",
                            icon: isEditing ? "checkmark" : "plus"
                        ) {
                            saveFriend()
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.md)
                    }
                    .padding(.vertical, Spacing.lg)
                }
            }
            .navigationTitle(isEditing ? "Edit Friend" : "Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.warmGrayDark)
                }
            }
            .alert("Name Required", isPresented: $showingValidationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enter a name for your friend.")
            }
        }
    }

    // MARK: - Subviews

    private var avatarPreview: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            ZStack {
                // Avatar circle with photo or initials
                if let photoData = selectedPhotoData,
                   let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(previewColor.opacity(0.2))

                    Text(previewInitials)
                        .font(.displayLarge)
                        .foregroundStyle(previewColor)
                }

                // Camera badge overlay
                Image(systemName: selectedPhotoData == nil ? "camera.fill" : "pencil")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(Color.coral)
                    .clipShape(Circle())
                    .offset(x: 35, y: 35)
            }
            .frame(width: 100, height: 100)
            .scaleEffect(isAvatarBouncing ? 1.1 : 1.0)
        }
        .buttonStyle(.plain)
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    withAnimation(.bounce) {
                        selectedPhotoData = data
                        isAvatarBouncing = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.bounce) {
                            isAvatarBouncing = false
                        }
                    }
                }
            }
        }
        .animation(.bounce, value: name)
        .contextMenu {
            if selectedPhotoData != nil {
                Button(role: .destructive) {
                    withAnimation(.bounce) {
                        selectedPhotoData = nil
                        selectedPhotoItem = nil
                    }
                } label: {
                    Label("Remove Photo", systemImage: "trash")
                }
            }
        }
    }

    private var previewInitials: String {
        guard !name.isEmpty else { return "?" }
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private var previewColor: Color {
        guard !name.isEmpty else { return .warmGrayDark }
        let colors: [Color] = [.coral, .sage, .lavender, .sunflower]
        let index = abs(name.hashValue) % colors.count
        return colors[index]
    }

    private var intervalPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Label("Reminder Frequency", systemImage: "bell.fill")
                .font(.labelLarge)
                .foregroundStyle(Color.warmGrayDark)

            HStack(spacing: Spacing.xs) {
                ForEach(ReminderInterval.allCases) { interval in
                    IntervalOption(
                        interval: interval,
                        isSelected: selectedInterval == interval
                    ) {
                        withAnimation(.bounce) {
                            selectedInterval = interval
                        }
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
    }

    // MARK: - Actions

    private func saveFriend() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            showingValidationError = true
            return
        }

        if let friend = existingFriend {
            // Update existing
            friend.name = trimmedName
            friend.phoneNumber = phoneNumber.isEmpty ? nil : phoneNumber
            friend.email = email.isEmpty ? nil : email
            friend.notes = notes.isEmpty ? nil : notes
            friend.reminderIntervalDays = selectedInterval.rawValue
            friend.photoData = selectedPhotoData
        } else {
            // Create new
            let friend = Friend(
                name: trimmedName,
                phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
                email: email.isEmpty ? nil : email,
                notes: notes.isEmpty ? nil : notes,
                reminderIntervalDays: selectedInterval.rawValue
            )
            friend.photoData = selectedPhotoData
            modelContext.insert(friend)
        }

        HapticService.shared.success()
        dismiss()
    }
}

// MARK: - Supporting Views

private struct FormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var icon: String
    var keyboardType: UIKeyboardType = .default
    var isMultiline: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Label(title, systemImage: icon)
                .font(.labelLarge)
                .foregroundStyle(Color.warmGrayDark)

            if isMultiline {
                TextField(placeholder, text: $text, axis: .vertical)
                    .font(.bodyLarge)
                    .lineLimit(3...6)
                    .padding(Spacing.sm)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            } else {
                TextField(placeholder, text: $text)
                    .font(.bodyLarge)
                    .keyboardType(keyboardType)
                    .textContentType(contentType)
                    .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                    .padding(Spacing.sm)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            }
        }
    }

    private var contentType: UITextContentType? {
        switch keyboardType {
        case .phonePad: return .telephoneNumber
        case .emailAddress: return .emailAddress
        default: return nil
        }
    }
}

private struct IntervalOption: View {
    let interval: ReminderInterval
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(shortLabel)
                .font(.labelMedium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(isSelected ? Color.coral : Color.warmGray)
                .foregroundStyle(isSelected ? .white : Color.warmGrayDark)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
        }
        .buttonStyle(.plain)
    }

    private var shortLabel: String {
        switch interval {
        case .weekly: return "1 wk"
        case .biweekly: return "2 wk"
        case .monthly: return "1 mo"
        case .quarterly: return "3 mo"
        }
    }
}

#Preview {
    AddFriendView()
        .modelContainer(for: [Friend.self, ContactLog.self], inMemory: true)
}
