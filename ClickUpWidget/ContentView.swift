import SwiftUI
import Shared

extension Notification.Name {
    static let oauthCompleted = Notification.Name("oauthCompleted")
}

struct ContentView: View {
    @State private var clientId: String = Secrets.clickUpClientId
    @State private var clientSecret: String = Secrets.clickUpClientSecret
    @State private var isSignedIn: Bool = false
    @State private var hasCredentials: Bool = Secrets.hasCredentials
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)

            Text("ClickUp Widget")
                .font(.title2)
                .fontWeight(.bold)

            if !hasCredentials {
                credentialsForm
            } else if !isSignedIn {
                signInView
            } else {
                signedInView
            }

            Spacer()
        }
        .padding(32)
        .frame(minWidth: 340, minHeight: 320)
        .onAppear {
            checkAuthState()
        }
        .onReceive(NotificationCenter.default.publisher(for: .oauthCompleted)) { _ in
            checkAuthState()
        }
        .alert("ClickUp", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }

    private var credentialsForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OAuth App Setup")
                .font(.headline)

            Text("Create an OAuth app at ClickUp and enter credentials:")
                .font(.caption)
                .foregroundColor(.secondary)

            TextField("Client ID", text: $clientId)
                .textFieldStyle(.roundedBorder)

            SecureField("Client Secret", text: $clientSecret)
                .textFieldStyle(.roundedBorder)

            Button(action: saveCredentials) {
                Text("Save")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(clientId.isEmpty || clientSecret.isEmpty)

            Link("Open ClickUp API Settings", destination: URL(string: "https://app.clickup.com/settings/apps")!)
                .font(.caption)
        }
    }

    private var signInView: some View {
        VStack(spacing: 12) {
            Button(action: signIn) {
                HStack {
                    Image(systemName: "person.circle.fill")
                    Text("Sign in with ClickUp")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button(action: resetCredentials) {
                Text("Change OAuth App")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
    }

    private var signedInView: some View {
        VStack(spacing: 12) {
            Label("Connected", systemImage: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.headline)

            Text("Your tasks will appear in the widget")
                .font(.caption)
                .foregroundColor(.secondary)

            Button(action: signOut) {
                Text("Sign Out")
            }
            .buttonStyle(.bordered)

            Button(action: resetCredentials) {
                Text("Change OAuth App")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
    }

    private func checkAuthState() {
        hasCredentials = Secrets.hasCredentials
        ClickUpAPI.shared.loadOAuthToken()
        isSignedIn = ClickUpAPI.shared.oauthToken != nil
    }

    private func saveCredentials() {
        Secrets.clickUpClientId = clientId
        Secrets.clickUpClientSecret = clientSecret
        hasCredentials = true
    }

    private func resetCredentials() {
        Secrets.clickUpClientId = ""
        Secrets.clickUpClientSecret = ""
        clientId = ""
        clientSecret = ""
        hasCredentials = false
        if isSignedIn {
            try? ClickUpAPI.shared.clearOAuthToken()
            isSignedIn = false
        }
    }

    private func signIn() {
        Task {
            let url = await OAuthService.shared.authorizationURL
            NSWorkspace.shared.open(url)
        }
    }

    private func signOut() {
        do {
            try ClickUpAPI.shared.clearOAuthToken()
            isSignedIn = false
        } catch {
            alertMessage = "Failed to sign out: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

#Preview {
    ContentView()
}
