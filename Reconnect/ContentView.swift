import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        ZStack {
            LinearGradient.warmBackground.ignoresSafeArea()

            if hasCompletedOnboarding {
                FriendListView()
            } else {
                OnboardingView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Friend.self, ContactLog.self], inMemory: true)
}
