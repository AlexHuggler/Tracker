import SwiftUI

struct OnboardingFlowView: View {
    @Environment(AppState.self) private var appState
    @State private var currentPage = 0

    var body: some View {
        TabView(selection: $currentPage) {
            WelcomePage(onContinue: { currentPage = 1 })
                .tag(0)

            ConditionSetupView(onContinue: { currentPage = 2 })
                .tag(1)

            PermissionsPage(onContinue: { currentPage = 3 })
                .tag(2)

            ReadyPage(onStart: {
                appState.hasCompletedOnboarding = true
            })
            .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}

// MARK: - Welcome Page

struct WelcomePage: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "brain.head.profile")
                .font(.system(size: 72))
                .foregroundStyle(AuraTheme.accent)

            Text("Aura")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(AuraTheme.primary)

            Text("Track pain. Find patterns.\nTake control.")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            VStack(spacing: 12) {
                featureRow(icon: "bolt.fill", text: "Log episodes in 3 taps")
                featureRow(icon: "chart.xyaxis.line", text: "Discover trigger patterns")
                featureRow(icon: "doc.text.fill", text: "Generate doctor-ready reports")
                featureRow(icon: "lock.shield.fill", text: "Your data stays on your device")
            }
            .padding(.horizontal, 40)

            Spacer()

            Button(action: onContinue) {
                Text("Get Started")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: AuraTheme.minTouchTarget)
                    .background {
                        RoundedRectangle(cornerRadius: AuraTheme.cornerRadius)
                            .fill(AuraTheme.accent)
                    }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(AuraTheme.accent)
                .frame(width: 30)

            Text(text)
                .font(AuraTheme.bodyFont)
                .foregroundStyle(AuraTheme.primary)

            Spacer()
        }
    }
}

// MARK: - Permissions Page

struct PermissionsPage: View {
    let onContinue: () -> Void
    @State private var healthKitRequested = false
    @State private var notificationsRequested = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "hand.raised.fill")
                .font(.system(size: 48))
                .foregroundStyle(AuraTheme.accent)

            Text("Permissions")
                .font(AuraTheme.headingFont)
                .foregroundStyle(AuraTheme.primary)

            Text("These are optional. Aura works great without them.")
                .font(AuraTheme.bodyFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 16) {
                permissionCard(
                    icon: "heart.fill",
                    title: "Health Data",
                    description: "Read sleep data to find sleep-episode correlations. Your data stays on your device.",
                    isGranted: healthKitRequested
                ) {
                    Task {
                        _ = try? await HealthKitService.shared.requestAuthorization()
                        healthKitRequested = true
                    }
                }

                permissionCard(
                    icon: "bell.fill",
                    title: "Notifications",
                    description: "Receive medication reminders for preventive treatments.",
                    isGranted: notificationsRequested
                ) {
                    Task {
                        _ = await NotificationManager.shared.requestAuthorization()
                        notificationsRequested = true
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: AuraTheme.minTouchTarget)
                    .background {
                        RoundedRectangle(cornerRadius: AuraTheme.cornerRadius)
                            .fill(AuraTheme.accent)
                    }
            }
            .padding(.horizontal, 24)

            Button("Skip for now", action: onContinue)
                .font(AuraTheme.captionFont)
                .foregroundStyle(.secondary)
                .padding(.bottom, 40)
        }
    }

    private func permissionCard(
        icon: String,
        title: String,
        description: String,
        isGranted: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: { if !isGranted { action() } }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(isGranted ? AuraTheme.painMild : AuraTheme.accent)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AuraTheme.primary)
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: isGranted ? "checkmark.circle.fill" : "plus.circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isGranted ? AuraTheme.painMild : AuraTheme.accent)
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: AuraTheme.cornerRadius)
                    .fill(Color(.systemBackground))
                    .shadow(color: AuraTheme.cardShadow, radius: 4, y: 2)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Ready Page

struct ReadyPage: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(AuraTheme.accent)

            Text("You're all set!")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(AuraTheme.primary)

            Text("Start logging when you need to.\nPatterns will emerge over time.")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button(action: onStart) {
                Text("Start Using Aura")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: AuraTheme.minTouchTarget)
                    .background {
                        RoundedRectangle(cornerRadius: AuraTheme.cornerRadius)
                            .fill(AuraTheme.accent)
                    }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}
