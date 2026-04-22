import SwiftUI
import SwiftData

struct ProfileAvatarToolbar: ViewModifier {
    @Query private var profiles: [UserProfile]
    @Query private var quizResults: [QuizResult]
    @Query(filter: #Predicate<InAppNotification> { !$0.isDismissed && !$0.isRead })
    private var unreadNotifications: [InAppNotification]

    @State private var showProfile = false
    @State private var pressed = false

    private var profile: UserProfile? { profiles.first }

    private var personality: MoneyPersonality {
        quizResults.first?.personality ?? .builder
    }

    private var characterLevel: Int {
        CharacterStage.level(from: profile?.xpPoints ?? 0)
    }

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    avatarButton
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Theme.background)
            }
    }

    private var avatarButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                pressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                pressed = false
                showProfile = true
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [personality.color.opacity(0.35), personality.color.opacity(0.18)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 34, height: 34)
                        .overlay(
                            Circle().strokeBorder(personality.color.opacity(0.6), lineWidth: 1.25)
                        )
                        .overlay(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.12), .clear],
                                        startPoint: .top,
                                        endPoint: .center
                                    )
                                )
                        )

                    Text("\(characterLevel)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                }
                .shadow(color: personality.color.opacity(0.25), radius: 6, y: 2)

                if !unreadNotifications.isEmpty {
                    Circle()
                        .fill(Theme.danger)
                        .frame(width: 9, height: 9)
                        .overlay(Circle().strokeBorder(Theme.background, lineWidth: 1.5))
                        .offset(x: 3, y: -3)
                }
            }
            .scaleEffect(pressed ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Profile")
        .accessibilityValue("Level \(characterLevel)")
        .sensoryFeedback(.impact(weight: .light), trigger: showProfile)
    }
}

extension View {
    func profileAvatarToolbar() -> some View {
        modifier(ProfileAvatarToolbar())
    }
}
