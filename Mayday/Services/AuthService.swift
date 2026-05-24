import Foundation

enum LoginStatus: String, Decodable, Sendable {
    case authenticated
    case mfaRequired = "mfa_required"
}

struct LoginResponse: Decodable, Sendable {
    let status: LoginStatus
    let user: UserResponse?
    let tokens: TokenPair?
    let mfaToken: String?
    let methods: [String]?

    enum CodingKeys: String, CodingKey {
        case status, user, tokens, methods
        case mfaToken = "mfa_token"
    }
}

struct MessageResponse: Decodable, Sendable {
    let message: String
}

actor AuthService {
    static let shared = AuthService()
    private let client = HTTPClient.shared
    private let keychain = KeychainService.shared

    private init() {}

    func login(email: String, password: String) async throws -> UserResponse {
        let response: LoginResponse = try await client.request(.login(email: email, password: password))
        switch response.status {
        case .authenticated:
            guard let user = response.user, let tokens = response.tokens else {
                throw APIError.serverError("Malformed login response")
            }
            try keychain.saveTokens(tokens)
            return user
        case .mfaRequired:
            throw APIError.mfaRequired
        }
    }

    func register(email: String, password: String) async throws -> UserResponse {
        let response: UserResponse = try await client.request(.register(email: email, password: password))
        return response
    }

    func verifyEmail(email: String, code: String) async throws {
        let _: MessageResponse = try await client.request(.verifyEmail(email: email, code: code))
    }

    func resendCode(email: String) async throws {
        let _: MessageResponse = try await client.request(.resendCode(email: email))
    }

    func logout() async throws {
        // Always clear local tokens, regardless of whether the network call succeeds,
        // to avoid leaving a stale access token in Keychain.
        defer { keychain.clearTokens() }
        guard let refreshToken = keychain.loadRefreshToken() else { return }
        let _: EmptyResponse = try await client.request(.logout(refreshToken: refreshToken))
    }

    func getMe() async throws -> UserResponse {
        try await client.request(.getMe)
    }
}

struct EmptyResponse: Decodable, Sendable {}
