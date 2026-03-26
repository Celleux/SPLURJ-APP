import SwiftUI

struct WelcomeView: View {
    let onGetStarted: () -> Void

    var body: some View {
        OnboardingView(onComplete: onGetStarted)
    }
}
