import SwiftUI

/// Animated launch sequence.
///
/// The build-up is deliberately staged: **One** arrives first (dark, the neutral
/// half of the wordmark), **Mart** lands right after in amber to complete
/// "OneMart", and only then does the real `OneMartLogo` artwork spring into
/// place — the artwork already contains the finished lockup (mark + wordmark +
/// tagline), so the animated text is a build-up that settles *into* it rather
/// than a second copy of it.
///
/// Reduce Motion swaps every spring/offset for a plain cross-fade while keeping
/// the same beats.
struct SplashScreen: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showsOne = false
    @State private var showsMart = false
    @State private var showsLockup = false
    @State private var glowPulse = false

    // Beat timings (seconds from appear).
    private let oneBeat: Double = 0.15
    private let martBeat: Double = 0.55
    private let lockupBeat: Double = 1.15
    private let advanceBeat: Double = 2.4

    var body: some View {
        ZStack {
            AppColor.backgroundPrimary
                .ignoresSafeArea()

            ambientGlow

            VStack(spacing: AppSpacing.md) {
                ZStack {
                    wordmarkBuildUp
                        .opacity(showsLockup ? 0 : 1)
                        .scaleEffect(showsLockup && !reduceMotion ? 0.92 : 1)

                    logoLockup
                        .opacity(showsLockup ? 1 : 0)
                        .scaleEffect(logoScale)
                }
                .frame(height: 200)
            }

            VStack {
                Spacer()
                loaderDots
                    .opacity(showsLockup ? 1 : 0)
                    .padding(.bottom, AppSpacing.xxl)
            }
        }
        .task {
            await runSequence()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("OneMart — All-in-One Digital Ecosystem")
    }

    // MARK: - Pieces

    private var wordmarkBuildUp: some View {
        HStack(spacing: 0) {
            Text("One")
                .font(AppFont.rounded(52, weight: .heavy))
                .foregroundStyle(AppColor.textPrimary)
                .opacity(showsOne ? 1 : 0)
                .offset(x: showsOne || reduceMotion ? 0 : -28)

            Text("Mart")
                .font(AppFont.rounded(52, weight: .heavy))
                .foregroundStyle(AppColor.amber)
                .opacity(showsMart ? 1 : 0)
                .offset(x: showsMart || reduceMotion ? 0 : 28)
                .scaleEffect(showsMart || reduceMotion ? 1 : 0.8)
        }
    }

    private var logoLockup: some View {
        Image("OneMartLogo")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 260)
            .accessibilityHidden(true)
    }

    private var logoScale: CGFloat {
        guard !reduceMotion else { return 1 }
        return showsLockup ? 1 : 0.78
    }

    private var ambientGlow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [AppColor.amber.opacity(0.22), AppColor.amber.opacity(0)],
                    center: .center,
                    startRadius: 4,
                    endRadius: 190
                )
            )
            .frame(width: 380, height: 380)
            .scaleEffect(glowPulse && !reduceMotion ? 1.08 : 0.94)
            .opacity(showsOne ? 1 : 0)
            .allowsHitTesting(false)
    }

    private var loaderDots: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(AppColor.coral.opacity(0.7))
                    .frame(width: 7, height: 7)
                    .scaleEffect(glowPulse && !reduceMotion ? 1.0 : 0.55)
                    .animation(
                        reduceMotion
                            ? .easeInOut(duration: 0.2)
                            : .easeInOut(duration: 0.6).repeatForever().delay(Double(index) * 0.18),
                        value: glowPulse
                    )
            }
        }
    }

    // MARK: - Sequence

    @MainActor
    private func runSequence() async {
        withAnimation(AppMotion.adaptive(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), reduceMotion: reduceMotion)) {
            glowPulse = true
        }

        await sleep(oneBeat)
        withAnimation(AppMotion.adaptive(AppMotion.springBouncy, reduceMotion: reduceMotion)) {
            showsOne = true
        }

        await sleep(martBeat - oneBeat)
        withAnimation(AppMotion.adaptive(AppMotion.springBouncy, reduceMotion: reduceMotion)) {
            showsMart = true
        }

        await sleep(lockupBeat - martBeat)
        withAnimation(AppMotion.adaptive(AppMotion.springBouncy, reduceMotion: reduceMotion)) {
            showsLockup = true
        }

        await sleep(advanceBeat - lockupBeat)
        withAnimation(AppMotion.easeStandard) {
            appState.phase = .login
        }
    }

    private func sleep(_ seconds: Double) async {
        guard seconds > 0 else { return }
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}

#Preview {
    SplashScreen()
        .environmentObject(AppState())
}
