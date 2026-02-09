import SwiftUI
import Shared

@main
struct ClickUpWidgetApp: App {
    @State private var oauthError: String?
    @State private var showOAuthError = false
    @State private var showCreateTask = false

    var body: some Scene {
        WindowGroup {
            ContentView(showCreateTask: $showCreateTask)
                .onOpenURL { url in
                    handleURL(url)
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

    private func handleURL(_ url: URL) {
        guard url.scheme == "clickupwidget" else {
            NSWorkspace.shared.open(url)
            return
        }

        if url.host == "create-task" {
            showCreateTask = true
            return
        }

        // OAuth callback
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
