import WidgetKit
import SwiftUI
import AppIntents
import Shared

struct RefreshIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Tasks"
    static var description = IntentDescription("Refresh ClickUp tasks")

    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct MarkTaskDoneIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Task Done"
    static var description = IntentDescription("Mark a ClickUp task as complete")

    @Parameter(title: "Task ID")
    var taskId: String

    init() {}

    init(taskId: String) {
        self.taskId = taskId
    }

    func perform() async throws -> some IntentResult {
        let oauthToken = try? KeychainHelper.shared.get(key: "clickup_oauth_token")
        let apiKeyToken = try? KeychainHelper.shared.get(key: "clickup_api_key")
        guard let token = oauthToken ?? apiKeyToken else { return .result() }

        try await ClickUpService.shared.updateTaskStatus(apiKey: token, taskId: taskId, status: "complete")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct CreateTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Task"
    static var description = IntentDescription("Open app to create a new ClickUp task")

    func perform() async throws -> some IntentResult {
        if let url = URL(string: "clickupwidget://create-task") {
            await NSWorkspace.shared.open(url)
        }
        return .result()
    }
}

@main
struct ClickUpWidgetBundle: WidgetBundle {
    var body: some Widget {
        TaskWidget()
    }
}

struct TaskWidget: Widget {
    let kind: String = "TaskWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskTimelineProvider()) { entry in
            TaskWidgetView(entry: entry)
        }
        .configurationDisplayName("ClickUp Tasks")
        .description("Your assigned tasks from ClickUp")
        .supportedFamilies([.systemMedium])
    }
}
