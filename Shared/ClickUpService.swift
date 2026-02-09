import Foundation
import os.log

private let logger = Logger(subsystem: "com.yannickpulver.clickupwidget", category: "Service")

// MARK: - Errors

public enum ClickUpServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case rateLimited
    case unauthorized
    case notFound
    case serverError
    case timeout
    case decodingError(Error)
    case networkError(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid API response"
        case .rateLimited:
            return "Rate limited by ClickUp API"
        case .unauthorized:
            return "Unauthorized. Check your API key"
        case .notFound:
            return "Resource not found"
        case .serverError:
            return "ClickUp server error"
        case .timeout:
            return "Request timeout"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Service

public actor ClickUpService {
    public static let shared = ClickUpService()

    private let baseURL = "https://api.clickup.com/api/v2"
    private let timeout: TimeInterval = 15.0
    private let minRequestInterval: TimeInterval = 0.6 // 100 req/min

    private var lastRequestTime: Date = .distantPast
    private var rateLimitRemaining: Int = 100

    private init() {}

    // MARK: - Public Methods

    public func getUser(apiKey: String) async throws -> ClickUpUser {
        let endpoint = "/user"
        let response = try await request(
            endpoint: endpoint,
            apiKey: apiKey,
            responseType: ClickUpUserResponse.self
        )
        return response.user
    }

    public func getTeams(apiKey: String) async throws -> [ClickUpTeam] {
        let endpoint = "/team"
        let response = try await request(
            endpoint: endpoint,
            apiKey: apiKey,
            responseType: ClickUpTeamResponse.self
        )
        return response.teams
    }

    public func getTasks(apiKey: String, teamId: String, userId: Int) async throws -> [ClickUpTask] {
        let endpoint = "/team/\(teamId)/task"
        let queryParams = [
            "assignees[]=\(userId)",
            "statuses[]=open",
            "subtasks=true"
        ]

        let response = try await request(
            endpoint: endpoint,
            apiKey: apiKey,
            queryParams: queryParams,
            responseType: ClickUpTasksResponse.self
        )

        // Sort tasks: overdue first, then by due date (soonest first)
        return response.tasks.sorted { task1, task2 in
            let now = Date()

            let task1IsOverdue = task1.dueDate.map { $0 < now } ?? false
            let task2IsOverdue = task2.dueDate.map { $0 < now } ?? false

            if task1IsOverdue != task2IsOverdue {
                return task1IsOverdue
            }

            // Both overdue or both not overdue, sort by due date
            switch (task1.dueDate, task2.dueDate) {
            case let (date1?, date2?):
                return date1 < date2
            case (.some, nil):
                return true
            case (nil, .some):
                return false
            case (nil, nil):
                return false
            }
        }
    }

    public func updateTaskStatus(apiKey: String, taskId: String, status: String) async throws {
        let body = try JSONEncoder().encode(["status": status])
        try await requestNoResponse(
            endpoint: "/task/\(taskId)",
            apiKey: apiKey,
            httpMethod: "PUT",
            body: body
        )
    }

    public func createTask(apiKey: String, listId: String, name: String, assigneeIds: [Int] = []) async throws {
        let payload = CreateTaskPayload(name: name, assignees: assigneeIds)
        let body = try JSONEncoder().encode(payload)
        try await requestNoResponse(
            endpoint: "/list/\(listId)/task",
            apiKey: apiKey,
            httpMethod: "POST",
            body: body
        )
    }

    public func getSpaces(apiKey: String, teamId: String) async throws -> [ClickUpSpace] {
        let response = try await request(
            endpoint: "/team/\(teamId)/space",
            apiKey: apiKey,
            responseType: ClickUpSpacesResponse.self
        )
        return response.spaces
    }

    public func getFolderlessLists(apiKey: String, spaceId: String) async throws -> [ClickUpList] {
        let response = try await request(
            endpoint: "/space/\(spaceId)/list",
            apiKey: apiKey,
            responseType: ClickUpListsResponse.self
        )
        return response.lists
    }

    public func getFolders(apiKey: String, spaceId: String) async throws -> [ClickUpFolder] {
        let response = try await request(
            endpoint: "/space/\(spaceId)/folder",
            apiKey: apiKey,
            responseType: ClickUpFoldersResponse.self
        )
        return response.folders
    }

    // MARK: - Private Methods

    private func request<T: Decodable>(
        endpoint: String,
        apiKey: String,
        queryParams: [String] = [],
        httpMethod: String = "GET",
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        let (data, _) = try await executeRequest(endpoint: endpoint, apiKey: apiKey, queryParams: queryParams, httpMethod: httpMethod, body: body)

        // Decode response
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch let DecodingError.keyNotFound(key, context) {
            throw ClickUpServiceError.decodingError(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing key: \(key.stringValue) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"]))
        } catch let DecodingError.typeMismatch(type, context) {
            throw ClickUpServiceError.decodingError(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Type mismatch: expected \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"]))
        } catch let DecodingError.valueNotFound(type, context) {
            throw ClickUpServiceError.decodingError(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Value not found: \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"]))
        } catch let DecodingError.dataCorrupted(context) {
            throw ClickUpServiceError.decodingError(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Data corrupted at \(context.codingPath.map { $0.stringValue }.joined(separator: ".")): \(context.debugDescription)"]))
        } catch {
            throw ClickUpServiceError.decodingError(error)
        }
    }

    private func requestNoResponse(
        endpoint: String,
        apiKey: String,
        httpMethod: String = "PUT",
        body: Data? = nil
    ) async throws {
        _ = try await executeRequest(endpoint: endpoint, apiKey: apiKey, httpMethod: httpMethod, body: body)
    }

    private func executeRequest(
        endpoint: String,
        apiKey: String,
        queryParams: [String] = [],
        httpMethod: String = "GET",
        body: Data? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        // Rate limiting
        try await enforceRateLimit()

        // Build URL
        var urlString = baseURL + endpoint
        if !queryParams.isEmpty {
            urlString += "?" + queryParams.joined(separator: "&")
        }

        guard let url = URL(string: urlString) else {
            throw ClickUpServiceError.invalidURL
        }

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeout
        request.httpBody = body

        // Execute request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Handle response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClickUpServiceError.invalidResponse
        }

        // Update rate limit info
        if let remaining = httpResponse.value(forHTTPHeaderField: "X-RateLimit-Remaining"),
           let count = Int(remaining) {
            rateLimitRemaining = count
        }

        // Handle HTTP status
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw ClickUpServiceError.unauthorized
        case 404:
            throw ClickUpServiceError.notFound
        case 429:
            throw ClickUpServiceError.rateLimited
        case 500...599:
            throw ClickUpServiceError.serverError
        default:
            throw ClickUpServiceError.invalidResponse
        }

        return (data, httpResponse)
    }

    private func enforceRateLimit() async throws {
        let timeSinceLastRequest = Date().timeIntervalSince(lastRequestTime)

        if timeSinceLastRequest < minRequestInterval {
            let delayTime = minRequestInterval - timeSinceLastRequest
            try await Task.sleep(nanoseconds: UInt64(delayTime * 1_000_000_000))
        }

        lastRequestTime = Date()
    }
}
