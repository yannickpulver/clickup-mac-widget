import Foundation

public enum Secrets {
    private static let defaults = UserDefaults(suiteName: "group.com.clickup.widget")

    public static var clickUpClientId: String {
        get { defaults?.string(forKey: "clickup_client_id") ?? "" }
        set { defaults?.set(newValue, forKey: "clickup_client_id") }
    }

    public static var clickUpClientSecret: String {
        get { defaults?.string(forKey: "clickup_client_secret") ?? "" }
        set { defaults?.set(newValue, forKey: "clickup_client_secret") }
    }

    public static var hasCredentials: Bool {
        !clickUpClientId.isEmpty && !clickUpClientSecret.isEmpty
    }
}
