import WidgetKit
import SwiftUI
import AppIntents

struct RefreshIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Tasks"
    static var description = IntentDescription("Refresh ClickUp tasks")

    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadAllTimelines()
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
