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
        case .invalidURL: return "Invalid URL"
        case .unauthorized: return "Неверный email или пароль"
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
    case getNotifications(page: Int, perPage: Int)
    case markAsRead(id: UUID)
    // Devices
    case registerDevice(token: String)
    case unregisterDevice(token: String)

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
        case .registerDevice: return "/devices/register"
        case .unregisterDevice: return "/devices/unregister"
        }
    }

    var method: String {
        switch self {
        case .getMe, .getSessions, .getNotifications: return "GET"
        case .deleteSession: return "DELETE"
        case .markAsRead: return "PATCH"
        default: return "POST"
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
        case .registerDevice(let token):
            return ["token": token, "platform": "ios"]
        case .unregisterDevice(let token):
            return ["token": token]
        case .getNotifications(let page, let perPage):
            return ["page": page, "per_page": perPage]
        default:
            return nil
        }
    }
}

actor HTTPClient {
    static let shared = HTTPClient()

    private let baseURL: String
    private let keychain = KeychainService.shared
    private var isRefreshing = false

    private init() {
        #if DEBUG
        baseURL = "http://localhost:8081"
        #else
        baseURL = "https://api.chemodan.example/sso"
        #endif
    }

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let response: T = try await performRequest(endpoint, retryOnUnauthorized: endpoint.requiresAuth)
        return response
    }

    private func performRequest<T: Decodable>(_ endpoint: Endpoint, retryOnUnauthorized: Bool) async throws -> T {
        guard let url = URL(string: baseURL + endpoint.path) else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if endpoint.requiresAuth, let token = keychain.loadAccessToken() {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = endpoint.body, endpoint.method != "GET" {
            urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: body)
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

        if httpResponse.statusCode == 401 && retryOnUnauthorized && !isRefreshing {
            isRefreshing = true
            defer { isRefreshing = false }
            try await refreshTokens()
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

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let wrapped = try decoder.decode(APIResponse<T>.self, from: data)
            return wrapped.data
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func refreshTokens() async throws {
        guard let refreshToken = keychain.loadRefreshToken() else {
            throw APIError.unauthorized
        }
        let response: TokenRefreshResponse = try await performRequest(
            .refresh(refreshToken: refreshToken),
            retryOnUnauthorized: false
        )
        try keychain.saveTokens(response.tokens)
    }
}

struct TokenRefreshResponse: Decodable {
    let tokens: TokenPair
}
