import Foundation

public enum OAuthError: LocalizedError {
    case invalidURL
    case invalidResponse
    case missingToken
    case networkError(Error)
    case decodingError(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid OAuth URL"
        case .invalidResponse:
            return "Invalid OAuth response"
        case .missingToken:
            return "No access token in response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

public actor OAuthService {
    public static let shared = OAuthService()

    private let clientId = Secrets.clickUpClientId
    private let clientSecret = Secrets.clickUpClientSecret
    private let redirectUri = "clickupwidget://oauth/callback"
    private let timeout: TimeInterval = 10.0

    private init() {}

    public var authorizationURL: URL {
        var components = URLComponents(string: "https://app.clickup.com/api")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri)
        ]
        return components.url!
    }

    public func exchangeCodeForToken(_ code: String) async throws -> String {
        guard let url = URL(string: "https://api.clickup.com/api/v2/oauth/token") else {
            throw OAuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeout

        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "client_secret", value: clientSecret),
            URLQueryItem(name: "code", value: code)
        ]

        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OAuthError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw OAuthError.invalidResponse
        }

        do {
            let decoder = JSONDecoder()
            let tokenResponse = try decoder.decode(OAuthTokenResponse.self, from: data)
            guard let accessToken = tokenResponse.accessToken else {
                throw OAuthError.missingToken
            }
            return accessToken
        } catch is DecodingError {
            throw OAuthError.decodingError(NSError(domain: "OAuthService", code: -1))
        }
    }
}

private struct OAuthTokenResponse: Decodable {
    let accessToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}
