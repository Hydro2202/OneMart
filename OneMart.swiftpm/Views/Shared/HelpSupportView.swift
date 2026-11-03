import SwiftUI

/// Real FAQ content (expandable, OneMart-specific) plus mocked contact
/// options. Tapping a contact option shows an inline confirmation instead of
/// doing nothing — there's no backend to actually reach in this prototype.
struct HelpSupportView: View {
    @State private var expandedID: UUID?
    @State private var contactConfirmation: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                contactSection
                faqSection
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
        .animation(AppMotion.easeStandard, value: contactConfirmation)
    }

    // MARK: - Contact

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            SectionHeader(title: "Contact Support")

            if let contactConfirmation {
                InlineBanner(kind: .success, message: contactConfirmation)
            }

            HStack(spacing: AppSpacing.sm) {
                contactButton(icon: "bubble.left.and.bubble.right.fill", title: "Live Chat", tint: AppColor.coral) {
                    contactConfirmation = "Connecting you to a support agent — usual reply time is under 5 minutes."
                }
                contactButton(icon: "envelope.fill", title: "Email Us", tint: AppColor.jade) {
                    contactConfirmation = "A copy of this conversation will be sent to support@onemart.ph."
                }
                contactButton(icon: "phone.fill", title: "Call", tint: AppColor.amber) {
                    contactConfirmation = "Support hotline: 1-800-ONE-MART, daily 7AM–11PM."
                }
            }
        }
    }

    private func contactButton(icon: String, title: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 48, height: 48)
                    .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: AppRadius.sm))
                Text(title)
                    .appTextStyle(AppTextStyle.caption, color: AppColor.textPrimary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.pressable)
    }

    // MARK: - FAQ

    private var faqSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            SectionHeader(title: "Frequently Asked Questions")

            VStack(spacing: AppSpacing.xs) {
                ForEach(Self.faqs) { faq in
                    faqRow(faq)
                }
            }
        }
    }

    private func faqRow(_ faq: FAQ) -> some View {
        let isExpanded = expandedID == faq.id
        return VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Button {
                withAnimation(AppMotion.springSnappy) {
                    expandedID = isExpanded ? nil : faq.id
                }
            } label: {
                HStack(alignment: .top, spacing: AppSpacing.sm) {
                    Text(faq.question)
                        .appTextStyle(AppTextStyle.bodyEmphasis)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: AppSpacing.xs)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppColor.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(faq.answer)
                    .appTextStyle(AppTextStyle.callout, color: AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.subtle)
    }

    private struct FAQ: Identifiable {
        let id = UUID()
        let question: String
        let answer: String
    }

    private static let faqs: [FAQ] = [
        FAQ(
            question: "Why can't I add items from two different restaurants?",
            answer: "Your food cart can only hold dishes from one restaurant at a time, since everything in it ships in a single delivery. Adding from a new restaurant will ask to clear what's already there first."
        ),
        FAQ(
            question: "How does escrow protection work on Shop and Community?",
            answer: "When you pay through OneMart, your money is held safely and only released to the seller once you confirm the item arrived as described. If something's wrong, you can raise a dispute before funds are released."
        ),
        FAQ(
            question: "Can I top up my OneMart Wallet without a bank account?",
            answer: "Yes — the Top Up screen supports GCash, PayMaya, GoTyme, over-the-counter partners, and bank transfer, in addition to cards."
        ),
        FAQ(
            question: "How do I track my food order or parcel?",
            answer: "A tracking bar appears above the tab bar the moment an order is placed and stays visible no matter which tab you're on — tap it to jump straight to the full tracking screen."
        ),
        FAQ(
            question: "Is it safe to meet a Community seller in person?",
            answer: "Always meet in a public, well-lit place, and bring someone with you if you can. You can also skip the meet-up entirely by paying through OneMart and booking a Send delivery instead."
        ),
        FAQ(
            question: "Can I cancel a ride after a driver is found?",
            answer: "Yes, up until the driver confirms pickup. Frequent last-minute cancellations may affect your rider matching priority."
        )
    ]
}

#Preview {
    NavigationStack {
        HelpSupportView()
    }
    .environmentObject(AppState.previewSignedIn)
}
