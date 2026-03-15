import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case unauthorized
    case validationError([String: [String]])
    case serverError(String)
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return String(localized: "error_invalid_url")
        case .unauthorized: return String(localized: "error_invalid_credentials")
        case .validationError(let errors):
            return errors.values.flatMap { $0 }.joined(separator: ", ")
        case .serverError(let message): return message
        case .networkError(let error): return error.localizedDescription
        case .decodingError(let error): return error.localizedDescription
        }
    }
}

struct APIResponse<T: Decodable>: Decodable {
    let data: T
}

struct APIErrorResponse: Decodable {
    let message: String
    let errors: [String: [String]]?
}

enum APIService {
    case sso
    case notification
}

enum Endpoint {
    // Auth
    case login(email: String, password: String)
    case register(email: String, password: String)
    case verifyEmail(email: String, code: String)
    case resendCode(email: String)
    case refresh(refreshToken: String)
    case logout(refreshToken: String)
    // Users
    case getMe
    case getSessions
    case deleteSession(id: UUID)
    case logoutAll
    case changePassword(current: String, new: String)
    // Notifications
    case getNotifications(limit: Int, offset: Int, unreadOnly: Bool, scope: String?)
    case markAsRead(id: UUID)
    case markAllAsRead(scope: String?)
    // Devices
    case listDevices
    case registerDevice(token: String, platform: String)
    case unregisterDevice(id: UUID)
    // Preferences
    case getPreferences
    case upsertPreference(channel: String, enabled: Bool, config: [String: String]?)

    var service: APIService {
        switch self {
        case .login, .register, .verifyEmail, .resendCode, .refresh, .logout,
             .getMe, .getSessions, .deleteSession, .logoutAll, .changePassword:
            return .sso
        case .getNotifications, .markAsRead, .markAllAsRead,
             .listDevices, .registerDevice, .unregisterDevice,
             .getPreferences, .upsertPreference:
            return .notification
        }
    }

    var path: String {
        switch self {
        case .login: return "/auth/login"
        case .register: return "/auth/register"
        case .verifyEmail: return "/auth/verify-email"
        case .resendCode: return "/auth/resend-code"
        case .refresh: return "/auth/refresh"
        case .logout: return "/auth/logout"
        case .getMe: return "/users/me"
        case .getSessions: return "/users/me/sessions"
        case .deleteSession(let id): return "/users/me/sessions/\(id.uuidString)"
        case .logoutAll: return "/users/me/logout-all"
        case .changePassword: return "/users/me/change-password"
        case .getNotifications: return "/notifications"
        case .markAsRead(let id): return "/notifications/\(id.uuidString)/read"
        case .markAllAsRead: return "/notifications/read-all"
        case .listDevices: return "/devices"
        case .registerDevice: return "/devices"
        case .unregisterDevice(let id): return "/devices/\(id.uuidString)"
        case .getPreferences: return "/preferences"
        case .upsertPreference: return "/preferences"
        }
    }

    var method: String {
        switch self {
        case .getMe, .getSessions, .getNotifications, .listDevices, .getPreferences:
            return "GET"
        case .deleteSession, .unregisterDevice:
            return "DELETE"
        case .upsertPreference:
            return "PUT"
        default:
            return "POST"
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .login, .register, .verifyEmail, .resendCode, .refresh, .logout:
            return false
        default:
            return true
        }
    }

    var body: [String: Any]? {
        switch self {
        case .login(let email, let password):
            return ["email": email, "password": password]
        case .register(let email, let password):
            return ["email": email, "password": password]
        case .verifyEmail(let email, let code):
            return ["email": email, "code": code]
        case .resendCode(let email):
            return ["email": email]
        case .refresh(let token):
            return ["refresh_token": token]
        case .logout(let token):
            return ["refresh_token": token]
        case .changePassword(let current, let new):
            return ["current_password": current, "new_password": new]
        case .registerDevice(let token, let platform):
            return ["token": token, "platform": platform]
        case .getNotifications(let limit, let offset, let unreadOnly, let scope):
            var params: [String: Any] = ["limit": limit, "offset": offset]
            if unreadOnly { params["unread_only"] = true }
            if let scope { params["scope"] = scope }
            return params
        case .markAllAsRead(let scope):
            if let scope { return ["scope": scope] }
            return nil
        case .upsertPreference(let channel, let enabled, let config):
            var params: [String: Any] = ["channel": channel, "enabled": enabled]
            if let config { params["config"] = config }
            return params
        default:
            return nil
        }
    }
}

actor HTTPClient {
    static let shared = HTTPClient()

    private let ssoBaseURL: String
    private let notificationBaseURL: String
    private let keychain = KeychainService.shared
    // Single in-flight refresh task; concurrent 401s await this rather than racing.
    private var refreshTask: Task<Void, Error>?

    private init() {
        #if DEBUG
        ssoBaseURL = "http://192.168.3.7:8081"
        notificationBaseURL = "http://192.168.3.7:8092"
        #else
        ssoBaseURL = "https://id.robonen.ru"
        notificationBaseURL = "https://notify.robonen.ru"
        #endif
    }

    private func baseURL(for service: APIService) -> String {
        switch service {
        case .sso: return ssoBaseURL
        case .notification: return notificationBaseURL
        }
    }

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        try await performRequest(endpoint, retryOnUnauthorized: endpoint.requiresAuth)
    }

    private func performRequest<T: Decodable>(_ endpoint: Endpoint, retryOnUnauthorized: Bool) async throws -> T {
        guard let url = URL(string: baseURL(for: endpoint.service) + endpoint.path) else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if endpoint.requiresAuth, let token = keychain.loadAccessToken() {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = endpoint.body {
            if endpoint.method == "GET" {
                // Append query parameters to URL for GET requests
                if var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                    components.queryItems = body.map { key, value in
                        URLQueryItem(name: key, value: "\(value)")
                    }
                    urlRequest.url = components.url
                }
            } else {
                do {
                    urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
                } catch {
                    throw APIError.networkError(error)
                }
            }
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        if httpResponse.statusCode == 401 && retryOnUnauthorized {
            do {
                try await ensureTokenRefreshed()
            } catch {
                throw APIError.unauthorized
            }
            return try await performRequest(endpoint, retryOnUnauthorized: false)
        }

        if httpResponse.statusCode == 401 {
            keychain.clearTokens()
            throw APIError.unauthorized
        }

        if httpResponse.statusCode == 422 {
            if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw APIError.validationError(errorResponse.errors ?? [:])
            }
        }

        if !(200..<300).contains(httpResponse.statusCode) {
            if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.message)
            }
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        }

        // 204 No Content — return empty decodable if possible
        if httpResponse.statusCode == 204 || data.isEmpty {
            if let empty = EmptyResponse() as? T {
                return empty
            }
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let wrapped = try decoder.decode(APIResponse<T>.self, from: data)
            return wrapped.data
        } catch {
            throw APIError.decodingError(error)
        }
    }

    /// Ensures tokens are refreshed exactly once even when multiple requests receive 401
    /// concurrently. All callers await the same Task; only one network request is made.
    private func ensureTokenRefreshed() async throws {
        if let existing = refreshTask {
            try await existing.value
            return
        }

        guard let refreshToken = keychain.loadRefreshToken() else {
            keychain.clearTokens()
            throw APIError.unauthorized
        }

        let task = Task<Void, Error> {
            let response: TokenRefreshResponse = try await self.performRequest(
                .refresh(refreshToken: refreshToken),
                retryOnUnauthorized: false
            )
            try self.keychain.saveTokens(response.tokens)
        }
        refreshTask = task
        do {
            try await task.value
            refreshTask = nil
        } catch {
            refreshTask = nil
            keychain.clearTokens()
            throw error
        }
    }
}

struct TokenRefreshResponse: Decodable {
    let tokens: TokenPair
}
