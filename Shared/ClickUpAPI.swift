import Foundation

public class ClickUpAPI {
    public static let shared = ClickUpAPI()

    public private(set) var apiKey: String?
    public private(set) var oauthToken: String?

    public init() {}

    public func setAPIKey(_ key: String) {
        self.apiKey = key
        try? KeychainHelper.shared.save(key: "clickup_api_key", value: key)
    }

    public func setOAuthToken(_ token: String) {
        self.oauthToken = token
        try? KeychainHelper.shared.save(key: "clickup_oauth_token", value: token)
    }

    public func loadAPIKey() {
        self.apiKey = try? KeychainHelper.shared.get(key: "clickup_api_key")
    }

    public func loadOAuthToken() {
        self.oauthToken = try? KeychainHelper.shared.get(key: "clickup_oauth_token")
    }

    public func clearOAuthToken() throws {
        self.oauthToken = nil
        try KeychainHelper.shared.delete(key: "clickup_oauth_token")
    }

    public var isAuthenticated: Bool {
        oauthToken != nil || apiKey != nil
    }

    public var currentAuthToken: String? {
        oauthToken ?? apiKey
    }

    public func testConnection(completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let token = currentAuthToken else {
            completion(.failure(NSError(domain: "ClickUpAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authentication method set"])))
            return
        }

        var request = URLRequest(url: URL(string: "https://api.clickup.com/api/v2/team")!)
        request.setValue(token, forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                completion(.success(true))
            } else {
                completion(.failure(NSError(domain: "ClickUpAPI", code: -2, userInfo: [NSLocalizedDescriptionKey: "Authentication failed"])))
            }
        }.resume()
    }
}
