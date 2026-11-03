import SwiftUI

@main
struct OneMartApp: App {
    /// The single source of truth for the whole app, owned here and injected
    /// into every screen through the environment.
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}

/// Switches between the app's four phases. Splash and the auth screens are
/// full-screen takeovers; `.main` is the five-tab shell.
struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            AppColor.backgroundPrimary.ignoresSafeArea()

            switch appState.phase {
            case .splash:
                SplashScreen()
                    .transition(.opacity)
            case .login:
                LoginScreen()
                    .transition(.opacity)
            case .signup:
                SignUpScreen()
                    .transition(.opacity)
            case .main:
                RootTabView()
                    .transition(.opacity)
            }
        }
        .animation(AppMotion.adaptive(AppMotion.easeStandard, reduceMotion: reduceMotion), value: appState.phase)
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
}
