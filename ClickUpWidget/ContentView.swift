import SwiftUI
import Shared
import WidgetKit

extension Notification.Name {
    static let oauthCompleted = Notification.Name("oauthCompleted")
}

struct ContentView: View {
    @Binding var showCreateTask: Bool

    @State private var clientId: String = Secrets.clickUpClientId
    @State private var clientSecret: String = Secrets.clickUpClientSecret
    @State private var isSignedIn: Bool = false
    @State private var hasCredentials: Bool = Secrets.hasCredentials
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    // List picker state
    @State private var availableLists: [ClickUpList] = []
    @State private var selectedList: ClickUpList?
    @State private var loadingLists = false

    // Create task state
    @State private var newTaskName: String = ""
    @State private var creatingTask = false

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
        .frame(minWidth: 340, minHeight: 420)
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

            // Default list picker
            listPickerSection

            // Create task (shown when triggered from widget)
            if showCreateTask {
                createTaskSection
            }

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
        .onAppear {
            if availableLists.isEmpty {
                loadSpacesAndLists()
            }
        }
    }

    private var listPickerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Default List")
                .font(.caption)
                .foregroundColor(.secondary)

            if loadingLists {
                ProgressView()
                    .scaleEffect(0.8)
            } else if availableLists.isEmpty {
                Button("Load Lists") { loadSpacesAndLists() }
                    .font(.caption)
            } else {
                Picker("List", selection: $selectedList) {
                    Text("None").tag(nil as ClickUpList?)
                    ForEach(availableLists) { list in
                        Text(list.name).tag(list as ClickUpList?)
                    }
                }
                .onChange(of: selectedList) { _, list in
                    if let list {
                        SharedConfig.shared.saveDefaultList(listId: list.id, listName: list.name)
                    }
                }
            }
        }
    }

    private var createTaskSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            Text("New Task")
                .font(.headline)

            TextField("Task name", text: $newTaskName)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Create") { createTask() }
                    .buttonStyle(.borderedProminent)
                    .disabled(newTaskName.isEmpty || selectedList == nil || creatingTask)

                Button("Cancel") {
                    newTaskName = ""
                    showCreateTask = false
                }
                .buttonStyle(.bordered)

                if creatingTask {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            if selectedList == nil {
                Text("Select a default list above first")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }

    // MARK: - Actions

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

    private func loadSpacesAndLists() {
        guard let token = ClickUpAPI.shared.currentAuthToken else { return }
        loadingLists = true

        Task {
            do {
                let teams = try await ClickUpService.shared.getTeams(apiKey: token)
                guard let team = teams.first else {
                    await MainActor.run {
                        loadingLists = false
                        alertMessage = "No teams found"
                        showAlert = true
                    }
                    return
                }

                let spaces = try await ClickUpService.shared.getSpaces(apiKey: token, teamId: team.id)
                var allLists: [ClickUpList] = []

                for space in spaces {
                    let folderless = try await ClickUpService.shared.getFolderlessLists(apiKey: token, spaceId: space.id)
                    allLists.append(contentsOf: folderless)

                    let folders = try await ClickUpService.shared.getFolders(apiKey: token, spaceId: space.id)
                    for folder in folders {
                        allLists.append(contentsOf: folder.lists)
                    }
                }

                await MainActor.run {
                    availableLists = allLists
                    // Restore saved default
                    if let config = SharedConfig.shared.load(),
                       let savedId = config.defaultListId {
                        selectedList = allLists.first { $0.id == savedId }
                    }
                    loadingLists = false
                }
            } catch {
                await MainActor.run {
                    loadingLists = false
                    alertMessage = "Failed to load lists: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }

    private func createTask() {
        guard let list = selectedList, !newTaskName.isEmpty,
              let token = ClickUpAPI.shared.currentAuthToken else { return }
        creatingTask = true

        Task {
            do {
                // Get user ID for assignment
                let user = try await ClickUpService.shared.getUser(apiKey: token)
                try await ClickUpService.shared.createTask(
                    apiKey: token,
                    listId: list.id,
                    name: newTaskName,
                    assigneeIds: [user.id]
                )

                await MainActor.run {
                    newTaskName = ""
                    creatingTask = false
                    showCreateTask = false
                    WidgetCenter.shared.reloadAllTimelines()
                }
            } catch {
                await MainActor.run {
                    creatingTask = false
                    alertMessage = "Failed to create task: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}

#Preview {
    ContentView(showCreateTask: .constant(false))
}
