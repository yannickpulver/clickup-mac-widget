import SwiftUI
import Shared

@main
struct ClickUpWidgetApp: App {
    @State private var oauthError: String?
    @State private var showOAuthError = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleOAuthCallback(url)
                }
                .handlesExternalEvents(preferring: ["*"], allowing: ["*"])
                .alert("OAuth Error", isPresented: $showOAuthError) {
                    Button("OK") { }
                } message: {
                    Text(oauthError ?? "Unknown error")
                }
        }
        .handlesExternalEvents(matching: ["*"])
    }

    private func handleOAuthCallback(_ url: URL) {
        // Only handle OAuth callbacks (clickupwidget:// scheme)
        guard url.scheme == "clickupwidget" else {
            // Not an OAuth callback, let system handle it (e.g., open in browser)
            NSWorkspace.shared.open(url)
            return
        }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else {
            oauthError = "Invalid callback URL"
            showOAuthError = true
            return
        }

        guard let code = queryItems.first(where: { $0.name == "code" })?.value else {
            oauthError = "Missing authorization code"
            showOAuthError = true
            return
        }

        Task {
            do {
                let accessToken = try await OAuthService.shared.exchangeCodeForToken(code)
                ClickUpAPI.shared.setOAuthToken(accessToken)
                NotificationCenter.default.post(name: .oauthCompleted, object: nil)
            } catch {
                oauthError = error.localizedDescription
                showOAuthError = true
            }
        }
    }
}
