import Contacts
import ContactsUI
import PhotosUI
import SwiftData
import SwiftUI

struct AddFriendView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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

    // Focus management
    enum Field: Hashable {
        case name, phone, email, notes
    }
    @FocusState private var focusedField: Field?

    // Contact picker
    @State private var showingContactPicker = false

    var existingFriend: Friend?

    private var isEditing: Bool { existingFriend != nil }

    init(friend: Friend? = nil) {
        self.existingFriend = friend
        if let friend = friend {
            _name = State(initialValue: friend.name)
            _phoneNumber = State(initialValue: friend.phoneNumber ?? "")
            _email = State(initialValue: friend.email ?? "")
            _notes = State(initialValue: friend.notes ?? "")
            _selectedInterval = State(
                initialValue: ReminderInterval(rawValue: friend.reminderIntervalDays) ?? .biweekly)
            _selectedPhotoData = State(initialValue: friend.photoData)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Avatar preview
                        avatarPreview

                        // Import from Contacts button (only for new friends)
                        if !isEditing {
                            Button {
                                showingContactPicker = true
                            } label: {
                                Label(
                                    "Import from Contacts",
                                    systemImage: "person.crop.circle.badge.plus"
                                )
                                .font(.labelLarge)
                                .foregroundStyle(Color.coral)
                            }
                            .buttonStyle(.plain)
                        }

                        // Form fields
                        VStack(spacing: Spacing.md) {
                            FormField(
                                title: "Name",
                                placeholder: "Friend's name",
                                text: $name,
                                icon: "person.fill",
                                helperText: "Who do you want to stay in touch with?",
                                focusedField: $focusedField,
                                field: .name,
                                onSubmit: { focusedField = .phone }
                            )

                            FormField(
                                title: "Phone",
                                placeholder: "Phone number (optional)",
                                text: $phoneNumber,
                                icon: "phone.fill",
                                keyboardType: .phonePad,
                                helperText: "So you can call them with one tap",
                                validation: .phone,
                                focusedField: $focusedField,
                                field: .phone,
                                onSubmit: { focusedField = .email }
                            )

                            FormField(
                                title: "Email",
                                placeholder: "Email address (optional)",
                                text: $email,
                                icon: "envelope.fill",
                                keyboardType: .emailAddress,
                                helperText: "For quick email check-ins",
                                validation: .email,
                                focusedField: $focusedField,
                                field: .email,
                                onSubmit: { focusedField = .notes }
                            )

                            // Reminder interval picker
                            intervalPicker

                            FormField(
                                title: "Notes",
                                placeholder: "Any notes about this friend (optional)",
                                text: $notes,
                                icon: "note.text",
                                isMultiline: true,
                                helperText: "Birthday? Favorite coffee? Anything helpful!",
                                showCharacterCount: true,
                                maxCharacters: 200,
                                focusedField: $focusedField,
                                field: .notes,
                                onSubmit: { focusedField = nil }
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
                .scrollDismissesKeyboard(.interactively)
                .onAppear {
                    // Auto-focus name field for new friends
                    if !isEditing {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            focusedField = .name
                        }
                    }
                }
                .onTapGesture {
                    focusedField = nil
                }
            }
            .navigationTitle(isEditing ? "Edit Friend" : "Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.textSecondary)
                }
            }
            .alert("Name Required", isPresented: $showingValidationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enter a name for your friend.")
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactPicker { contact in
                    importContact(contact)
                }
            }
        }
    }

    // MARK: - Contact Import

    private func importContact(_ contact: CNContact) {
        // Import name
        let fullName = [contact.givenName, contact.familyName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        if !fullName.isEmpty {
            name = fullName
        }

        // Import phone (primary)
        if let phone = contact.phoneNumbers.first?.value.stringValue {
            phoneNumber = phone
        }

        // Import email (primary)
        if let emailValue = contact.emailAddresses.first?.value as String? {
            email = emailValue
        }

        // Import photo
        if let imageData = contact.thumbnailImageData ?? contact.imageData {
            selectedPhotoData = imageData
            withAnimation(reduceMotion ? .none : .bounce) {
                isAvatarBouncing = true
            }
            if !reduceMotion {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.bounce) {
                        isAvatarBouncing = false
                    }
                }
            }
        }

        HapticService.shared.success()
    }

    // MARK: - Subviews

    private var avatarPreview: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            ZStack {
                // Avatar circle with photo or initials
                if let photoData = selectedPhotoData,
                    let uiImage = UIImage(data: photoData)
                {
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
                    withAnimation(reduceMotion ? .none : .bounce) {
                        selectedPhotoData = data
                        isAvatarBouncing = !reduceMotion
                    }
                    if !reduceMotion {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.bounce) {
                                isAvatarBouncing = false
                            }
                        }
                    }
                }
            }
        }
        .animation(reduceMotion ? .none : .bounce, value: name)
        .contextMenu {
            if selectedPhotoData != nil {
                Button(role: .destructive) {
                    withAnimation(reduceMotion ? .none : .bounce) {
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
        guard !name.isEmpty else { return .textSecondary }
        let colors: [Color] = [.coral, .sage, .lavender, .sunflower]
        let index = abs(name.hashValue) % colors.count
        return colors[index]
    }

    private var intervalPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("How often do you want to reconnect?", systemImage: "bell.fill")
                .font(.labelLarge)
                .foregroundStyle(Color.textSecondary)

            HStack(spacing: Spacing.xs) {
                ForEach(ReminderInterval.allCases) { interval in
                    IntervalOption(
                        interval: interval,
                        isSelected: selectedInterval == interval
                    ) {
                        withAnimation(reduceMotion ? .none : .bounce) {
                            selectedInterval = interval
                        }
                    }
                }
            }

            // Descriptive text for selected interval
            Text(selectedInterval.description)
                .font(.labelSmall)
                .foregroundStyle(Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, Spacing.xxs)
                .animation(.snappy, value: selectedInterval)
        }
        .padding(Spacing.md)
        .background(Color.cardBackground)
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

private enum FieldValidation {
    case none
    case phone
    case email

    func validate(_ text: String) -> ValidationResult {
        guard !text.isEmpty else { return .empty }

        switch self {
        case .none:
            return .valid
        case .phone:
            let digits = text.filter { $0.isNumber }
            if digits.count >= 7 {
                return .valid
            } else {
                return .invalid("Add a few more digits")
            }
        case .email:
            let emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
            if text.contains(emailRegex) {
                return .valid
            } else {
                return .invalid("Hmm, that doesn't look quite right")
            }
        }
    }
}

private enum ValidationResult: Equatable {
    case empty
    case valid
    case invalid(String)
}

private struct FormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var icon: String
    var keyboardType: UIKeyboardType = .default
    var isMultiline: Bool = false
    var helperText: String? = nil
    var validation: FieldValidation = .none
    var showCharacterCount: Bool = false
    var maxCharacters: Int = 0
    var focusedField: FocusState<AddFriendView.Field?>.Binding?
    var field: AddFriendView.Field?
    var onSubmit: (() -> Void)?

    @FocusState private var isFocused: Bool

    private var isLastField: Bool {
        field == .notes
    }

    @ViewBuilder
    private var multilineField: some View {
        TextField(placeholder, text: $text, axis: .vertical)
            .font(.bodyLarge)
            .lineLimit(3...6)
            .padding(Spacing.sm)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(isFocused ? Color.coral.opacity(0.5) : Color.clear, lineWidth: 2)
            )
            .focused($isFocused)
            .submitLabel(.done)
            .onSubmit { onSubmit?() }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(isLastField ? "Done" : "Next") {
                        onSubmit?()
                    }
                    .foregroundStyle(Color.coral)
                }
            }
            .onChange(of: isFocused) { _, newValue in
                if let focusedField = focusedField, let field = field {
                    if newValue {
                        focusedField.wrappedValue = field
                    }
                }
            }
    }

    @ViewBuilder
    private var singleLineField: some View {
        HStack {
            TextField(placeholder, text: $text)
                .font(.bodyLarge)
                .keyboardType(keyboardType)
                .textContentType(contentType)
                .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                .focused($isFocused)
                .submitLabel(isLastField ? .done : .next)
                .onSubmit { onSubmit?() }

            // Validation indicator
            if !text.isEmpty && validation != .none {
                Image(
                    systemName: validationResult == .valid
                        ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
                )
                .foregroundStyle(validationResult == .valid ? Color.sage : Color.coral.opacity(0.7))
                .font(.body)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(Spacing.sm)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .stroke(isFocused ? Color.coral.opacity(0.5) : Color.clear, lineWidth: 2)
        )
        .animation(.snappy, value: validationResult)
        .onChange(of: isFocused) { _, newValue in
            if let focusedField = focusedField, let field = field {
                if newValue {
                    focusedField.wrappedValue = field
                }
            }
        }
    }

    private var validationResult: ValidationResult {
        validation.validate(text)
    }

    private var displayHelperText: String? {
        if case .invalid(let message) = validationResult {
            return message
        }
        return helperText
    }

    private var helperTextColor: Color {
        if case .invalid = validationResult {
            return .coral
        }
        return .textSecondary.opacity(0.7)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Label(title, systemImage: icon)
                .font(.labelLarge)
                .foregroundStyle(Color.textSecondary)

            if isMultiline {
                multilineField
            } else {
                singleLineField
            }

            // Helper text and character count
            HStack {
                if let helper = displayHelperText {
                    Text(helper)
                        .font(.labelSmall)
                        .foregroundStyle(helperTextColor)
                        .transition(.opacity)
                }

                Spacer()

                if showCharacterCount && maxCharacters > 0 {
                    Text("\(text.count)/\(maxCharacters)")
                        .font(.labelSmall)
                        .foregroundStyle(
                            text.count > maxCharacters
                                ? Color.coral : Color.textSecondary.opacity(0.5))
                }
            }
            .animation(.snappy, value: validationResult)
        }
        .onChange(of: focusedField?.wrappedValue) { _, newValue in
            if let field = field {
                isFocused = newValue == field
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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticService.shared.selection()
            action()
        }) {
            VStack(spacing: Spacing.xxs) {
                // Visual calendar with dots
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.coral.opacity(0.15) : Color.appBackground)
                        .frame(width: 36, height: 32)

                    VStack(spacing: 3) {
                        // Calendar header bar
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isSelected ? Color.coral : Color.warmGrayDark.opacity(0.4))
                            .frame(width: 28, height: 4)

                        // Dots representing frequency
                        HStack(spacing: 3) {
                            ForEach(0..<dotCount, id: \.self) { _ in
                                Circle()
                                    .fill(
                                        isSelected ? Color.coral : Color.warmGrayDark.opacity(0.5)
                                    )
                                    .frame(width: 5, height: 5)
                            }
                        }
                    }
                }

                Text(shortLabel)
                    .font(.labelSmall)
                    .foregroundStyle(isSelected ? Color.coral : Color.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .fill(isSelected ? Color.coral.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .stroke(isSelected ? Color.coral : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(interval.label), \(isSelected ? "selected" : "not selected")")
        .onLongPressGesture(
            minimumDuration: .infinity,
            pressing: { pressing in
                withAnimation(reduceMotion ? .none : .spring(response: 0.2, dampingFraction: 0.6)) {
                    isPressed = pressing
                }
            }, perform: {})
    }

    private var shortLabel: String {
        switch interval {
        case .weekly: return "Weekly"
        case .biweekly: return "2 weeks"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        }
    }

    private var dotCount: Int {
        switch interval {
        case .weekly: return 4
        case .biweekly: return 3
        case .monthly: return 2
        case .quarterly: return 1
        }
    }
}

// MARK: - Contact Picker

struct ContactPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    var onSelectContact: (CNContact) -> Void

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context)
    {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CNContactPickerDelegate {
        let parent: ContactPicker

        init(_ parent: ContactPicker) {
            self.parent = parent
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            parent.onSelectContact(contact)
            parent.dismiss()
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.dismiss()
        }
    }
}

#Preview {
    AddFriendView()
        .modelContainer(for: [Friend.self, ContactLog.self], inMemory: true)
}
