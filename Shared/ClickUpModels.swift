import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

// MARK: - Models

public struct ClickUpUser: Codable {
    public let id: Int
    public let username: String

    public enum CodingKeys: String, CodingKey {
        case id
        case username
    }

    public init(id: Int, username: String) {
        self.id = id
        self.username = username
    }
}

public struct ClickUpTeam: Codable {
    public let id: String
    public let name: String

    public enum CodingKeys: String, CodingKey {
        case id
        case name
    }

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct ClickUpTask: Codable, Identifiable {
    public let id: String
    public let name: String
    public let description: String?
    public let dueDate: Date?
    public let status: ClickUpTaskStatus
    public let priority: Int?
    public let assignees: [ClickUpAssignee]

    public var url: URL {
        URL(string: "https://app.clickup.com/t/\(id)")!
    }

    #if canImport(SwiftUI)
    public var priorityColor: Color {
        switch priority {
        case 1:
            return .red
        case 2:
            return .orange
        case 3:
            return .yellow
        default:
            return .gray
        }
    }
    #endif

    public enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case dueDate = "due_date"
        case status
        case priority
        case assignees
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        if let priorityObj = try container.decodeIfPresent(ClickUpPriority.self, forKey: .priority) {
            priority = priorityObj.priority
        } else {
            priority = nil
        }
        assignees = try container.decodeIfPresent([ClickUpAssignee].self, forKey: .assignees) ?? []

        // Parse ClickUp's millisecond timestamps (can be Int64 or String)
        if let dueDateMs = try? container.decodeIfPresent(Int64.self, forKey: .dueDate) {
            dueDate = Date(timeIntervalSince1970: TimeInterval(dueDateMs) / 1000)
        } else if let dueDateStr = try? container.decodeIfPresent(String.self, forKey: .dueDate),
                  let dueDateMs = Int64(dueDateStr) {
            dueDate = Date(timeIntervalSince1970: TimeInterval(dueDateMs) / 1000)
        } else {
            dueDate = nil
        }

        // Parse status
        let statusContainer = try container.nestedContainer(keyedBy: StatusCodingKeys.self, forKey: .status)
        let statusString = try statusContainer.decode(String.self, forKey: .status)
        status = ClickUpTaskStatus(rawValue: statusString) ?? .other(statusString)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        if let priority = priority {
            try container.encode(ClickUpPriority(priority: priority), forKey: .priority)
        }
        try container.encodeIfPresent(assignees, forKey: .assignees)

        // Encode millisecond timestamp
        if let dueDate = dueDate {
            let ms = Int64(dueDate.timeIntervalSince1970 * 1000)
            try container.encode(ms, forKey: .dueDate)
        }

        // Encode status
        var statusContainer = container.nestedContainer(keyedBy: StatusCodingKeys.self, forKey: .status)
        try statusContainer.encode(status.rawValue, forKey: .status)
    }

    public enum StatusCodingKeys: String, CodingKey {
        case status
    }

    // Convenience initializer for previews/testing
    public init(id: String, name: String, dueDate: Date?, priority: Int?) {
        self.id = id
        self.name = name
        self.description = nil
        self.dueDate = dueDate
        self.status = .open
        self.priority = priority
        self.assignees = []
    }
}

public enum ClickUpTaskStatus: Codable {
    case open
    case inProgress
    case closed
    case other(String)

    public var rawValue: String {
        switch self {
        case .open:
            return "open"
        case .inProgress:
            return "in progress"
        case .closed:
            return "closed"
        case .other(let value):
            return value
        }
    }

    public init?(rawValue: String) {
        switch rawValue.lowercased() {
        case "open":
            self = .open
        case "in progress":
            self = .inProgress
        case "closed":
            self = .closed
        default:
            self = .other(rawValue)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self = ClickUpTaskStatus(rawValue: value) ?? .other(value)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public struct ClickUpPriority: Codable {
    public let priority: Int?

    public init(priority: Int?) {
        self.priority = priority
    }
}

public struct ClickUpAssignee: Codable {
    public let id: Int
    public let username: String

    public enum CodingKeys: String, CodingKey {
        case id
        case username
    }

    public init(id: Int, username: String) {
        self.id = id
        self.username = username
    }
}

// MARK: - Space, Folder, List Models

public struct ClickUpSpace: Codable, Identifiable {
    public let id: String
    public let name: String
}

public struct ClickUpSpacesResponse: Codable {
    public let spaces: [ClickUpSpace]
}

public struct ClickUpList: Codable, Identifiable, Hashable {
    public let id: String
    public let name: String
}

public struct ClickUpListsResponse: Codable {
    public let lists: [ClickUpList]
}

public struct ClickUpFolder: Codable, Identifiable {
    public let id: String
    public let name: String
    public let lists: [ClickUpList]
}

public struct ClickUpFoldersResponse: Codable {
    public let folders: [ClickUpFolder]
}

public struct CreateTaskPayload: Encodable {
    public let name: String
    public let assignees: [Int]

    public init(name: String, assignees: [Int] = []) {
        self.name = name
        self.assignees = assignees
    }
}

// MARK: - API Response Wrappers

public struct ClickUpUserResponse: Codable {
    public let user: ClickUpUser

    public init(user: ClickUpUser) {
        self.user = user
    }
}

public struct ClickUpTeamResponse: Codable {
    public let teams: [ClickUpTeam]

    public init(teams: [ClickUpTeam]) {
        self.teams = teams
    }
}

public struct ClickUpTasksResponse: Codable {
    public let tasks: [ClickUpTask]

    public init(tasks: [ClickUpTask]) {
        self.tasks = tasks
    }
}
