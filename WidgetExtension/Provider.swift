import WidgetKit
import SwiftUI
import Shared
import os.log

private let logger = Logger(subsystem: "com.yannickpulver.clickupwidget", category: "Provider")

struct TaskEntry: TimelineEntry {
    let date: Date
    let tasks: [ClickUpTask]
    let error: String?
    let lastUpdated: Date?
}

typealias TaskItem = ClickUpTask

struct TaskTimelineProvider: TimelineProvider {
    @AppStorage("clickup_cached_tasks", store: UserDefaults(suiteName: "group.com.yannickpulver.clickupwidget")) var cachedTasksJSON: String?
    @AppStorage("clickup_last_updated", store: UserDefaults(suiteName: "group.com.yannickpulver.clickupwidget")) var lastUpdatedTimestamp: TimeInterval = 0

    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(
            date: Date(),
            tasks: [
                TaskItem(id: "1", name: "Review PR #123", dueDate: Date().addingTimeInterval(86400), priority: 1),
                TaskItem(id: "2", name: "Update documentation", dueDate: Date().addingTimeInterval(172800), priority: 2),
                TaskItem(id: "3", name: "Fix bug in widget", dueDate: Date().addingTimeInterval(259200), priority: 3)
            ],
            error: nil,
            lastUpdated: Date()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> Void) {
        let entry = placeholder(in: context)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> Void) {
        let currentDate = Date()
        logger.info("getTimeline called")

        // Try to fetch fresh tasks
        fetchTasks { result in
            switch result {
            case .success(let tasks):
                // Cache the tasks
                if let encoded = try? JSONEncoder().encode(tasks),
                   let json = String(data: encoded, encoding: .utf8) {
                    cachedTasksJSON = json
                    lastUpdatedTimestamp = currentDate.timeIntervalSince1970
                }

                let entry = TaskEntry(
                    date: currentDate,
                    tasks: tasks,
                    error: nil,
                    lastUpdated: currentDate
                )

                let timeline = Timeline(entries: [entry], policy: .after(currentDate.addingTimeInterval(900)))
                completion(timeline)

            case .failure(let error):
                // Use cached data or show error
                let cachedTasks = loadCachedTasks()
                let lastUpdated = lastUpdatedTimestamp > 0 ? Date(timeIntervalSince1970: lastUpdatedTimestamp) : nil

                let entry = TaskEntry(
                    date: currentDate,
                    tasks: cachedTasks,
                    error: cachedTasks.isEmpty ? error.localizedDescription : nil,
                    lastUpdated: lastUpdated
                )

                let timeline = Timeline(entries: [entry], policy: .after(currentDate.addingTimeInterval(300)))
                completion(timeline)
            }
        }
    }

    private func fetchTasks(completion: @escaping (Result<[TaskItem], Error>) -> Void) {
        let defaults = UserDefaults(suiteName: "group.com.yannickpulver.clickupwidget")
        defaults?.set("fetchTasks called at \(Date())", forKey: "debug_last_call")

        // Try OAuth token first, then API key
        let oauthToken = try? KeychainHelper.shared.get(key: "clickup_oauth_token")
        let apiKeyToken = try? KeychainHelper.shared.get(key: "clickup_api_key")
        let token: String? = oauthToken ?? apiKeyToken

        defaults?.set("oauth=\(oauthToken != nil), apiKey=\(apiKeyToken != nil)", forKey: "debug_token_status")

        guard let apiKey = token else {
            defaults?.set("No token found", forKey: "debug_last_error")
            completion(.failure(NSError(domain: "TaskWidget", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not signed in. Open ClickUp Widget app to sign in."])))
            return
        }

        Task {
            do {
                // Fetch user and team info directly from API
                let user = try await ClickUpService.shared.getUser(apiKey: apiKey)
                let teams = try await ClickUpService.shared.getTeams(apiKey: apiKey)

                guard let firstTeam = teams.first else {
                    completion(.failure(NSError(domain: "TaskWidget", code: -2, userInfo: [NSLocalizedDescriptionKey: "No teams found"])))
                    return
                }

                let tasks = try await ClickUpService.shared.getTasks(apiKey: apiKey, teamId: firstTeam.id, userId: user.id)
                defaults?.set("Fetched \(tasks.count) tasks", forKey: "debug_last_result")
                completion(.success(Array(tasks.prefix(5))))
            } catch {
                defaults?.set("Error: \(error)", forKey: "debug_last_error")
                completion(.failure(error))
            }
        }
    }

    private func loadCachedTasks() -> [TaskItem] {
        guard let json = cachedTasksJSON,
              let data = json.data(using: .utf8),
              let tasks = try? JSONDecoder().decode([TaskItem].self, from: data) else {
            return []
        }
        return tasks
    }
}

