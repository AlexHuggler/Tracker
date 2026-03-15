import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var product: Product?

    private let productID = "com.aura.premium.lifetime"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "star.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(AuraTheme.accent)

                        Text("Unlock Aura Premium")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(AuraTheme.primary)

                        Text("One-time purchase. No subscription.")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)

                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        premiumFeature(icon: "infinity", title: "Unlimited History", description: "Access all your episodes, not just the last 30 days")
                        premiumFeature(icon: "pill.fill", title: "Unlimited Medications", description: "Track all your medications and supplements")
                        premiumFeature(icon: "waveform.path.ecg", title: "Pattern Analysis", description: "Discover correlations between triggers and episodes")
                        premiumFeature(icon: "cloud.sun.fill", title: "Weather Integration", description: "Track barometric pressure changes before episodes")
                        premiumFeature(icon: "heart.fill", title: "Health Data", description: "Correlate sleep and activity with episodes")
                        premiumFeature(icon: "doc.text.fill", title: "Doctor Reports", description: "Generate PDF reports for your healthcare provider")
                        premiumFeature(icon: "bell.fill", title: "Med Reminders", description: "Daily reminders for preventive medications")
                        premiumFeature(icon: "icloud.fill", title: "iCloud Sync", description: "Keep your data in sync across devices")
                    }
                    .padding(.horizontal, 24)

                    // Price
                    VStack(spacing: 8) {
                        Text(product?.displayPrice ?? "$7.99")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .foregroundStyle(AuraTheme.accent)
                        Text("one-time purchase")
                            .font(AuraTheme.captionFont)
                            .foregroundStyle(.secondary)
                    }

                    // Error message
                    if let errorMessage {
                        Text(errorMessage)
                            .font(AuraTheme.captionFont)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Purchase button
                    Button {
                        purchase()
                    } label: {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 4)
                            }
                            Text(isPurchasing ? "Processing..." : "Unlock Premium — \(product?.displayPrice ?? "$7.99")")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: AuraTheme.minTouchTarget)
                        .background {
                            RoundedRectangle(cornerRadius: AuraTheme.cornerRadius)
                                .fill(AuraTheme.accent)
                        }
                    }
                    .disabled(isPurchasing)
                    .padding(.horizontal, 24)

                    // Restore
                    Button("Restore Purchase") {
                        restorePurchase()
                    }
                    .font(AuraTheme.captionFont)
                    .foregroundStyle(.secondary)

                    // Privacy note
                    Text("Your data always stays on your device. Premium just unlocks features — it doesn't change how your data is stored.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                product = try? await Product.products(for: [productID]).first
            }
        }
    }

    private func premiumFeature(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(AuraTheme.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AuraTheme.primary)
                Text(description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func purchase() {
        isPurchasing = true
        errorMessage = nil

        Task {
            do {
                let products = try await Product.products(for: [productID])
                guard let product = products.first else {
                    await MainActor.run {
                        errorMessage = "Product not available. Please try again later."
                        isPurchasing = false
                    }
                    return
                }

                let result = try await product.purchase()
                switch result {
                case .success(let verification):
                    switch verification {
                    case .verified:
                        await MainActor.run {
                            appState.isPremium = true
                            HapticsManager.shared.saveSuccess()
                            dismiss()
                        }
                    case .unverified:
                        await MainActor.run {
                            errorMessage = "Purchase could not be verified."
                            isPurchasing = false
                        }
                    }
                case .userCancelled:
                    await MainActor.run { isPurchasing = false }
                case .pending:
                    await MainActor.run {
                        errorMessage = "Purchase is pending approval."
                        isPurchasing = false
                    }
                @unknown default:
                    await MainActor.run { isPurchasing = false }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Purchase failed: \(error.localizedDescription)"
                    isPurchasing = false
                }
            }
        }
    }

    private func restorePurchase() {
        Task {
            for await result in Transaction.currentEntitlements {
                switch result {
                case .verified(let transaction):
                    if transaction.productID == productID {
                        await MainActor.run {
                            appState.isPremium = true
                            HapticsManager.shared.saveSuccess()
                            dismiss()
                        }
                        return
                    }
                case .unverified:
                    continue
                }
            }
        }
    }
}
