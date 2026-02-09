import SwiftUI
import WidgetKit
import Shared
import AppIntents

struct TaskWidgetView: View {
    let entry: TaskEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.blue)
                Text("ClickUp")
                    .font(.system(size: 11, weight: .semibold))
                Spacer()
                Link(destination: URL(string: "clickupwidget://create-task")!) {
                    Image(systemName: "plus")
                        .font(.system(size: 10))
                }
                Button(intent: RefreshIntent()) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
            }

            // Content
            if !entry.tasks.isEmpty {
                tasksList
            } else if let error = entry.error {
                errorView(error)
            } else {
                emptyStateView
            }

            Spacer(minLength: 0)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var tasksList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(entry.tasks.prefix(6)) { task in
                taskRow(task)
            }
        }
    }

    private func taskRow(_ task: TaskItem) -> some View {
        HStack(spacing: 4) {
            Button(intent: MarkTaskDoneIntent(taskId: task.id)) {
                Image(systemName: "circle")
                    .font(.system(size: 10))
                    .foregroundColor(task.priorityColor)
            }
            .buttonStyle(.plain)

            Link(destination: task.url) {
                HStack(spacing: 4) {
                    Text(task.name)
                        .font(.system(size: 11))
                        .lineLimit(1)
                        .foregroundColor(.primary)

                    Spacer(minLength: 2)

                    if let dueDate = task.dueDate {
                        Text(formatDate(dueDate))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.square.fill")
                .font(.system(size: 24))
                .foregroundColor(.secondary)

            Text("No tasks")
                .font(.system(.caption, design: .default))
                .foregroundColor(.secondary)

            Text("Setup in the ClickUp app")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .multilineTextAlignment(.center)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundColor(.orange)

            Text(error)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func lastUpdatedText(_ date: Date) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.minute, .hour, .day]

        if let formatted = formatter.string(from: date, to: Date()) {
            return "Updated \(formatted) ago"
        }
        return "Just now"
    }
}

#Preview {
    TaskWidgetView(entry: TaskEntry(
        date: Date(),
        tasks: [
            TaskItem(id: "1", name: "Review PR #123", dueDate: Date().addingTimeInterval(86400), priority: 1),
            TaskItem(id: "2", name: "Update documentation", dueDate: Date().addingTimeInterval(172800), priority: 2),
            TaskItem(id: "3", name: "Fix bug in widget", dueDate: Date().addingTimeInterval(259200), priority: 3)
        ],
        error: nil,
        lastUpdated: Date()
    ))
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .previewContext(WidgetPreviewContext(family: .systemMedium))
}
