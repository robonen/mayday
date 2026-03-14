import Foundation

struct LoginResponse: Decodable, Sendable {
    let user: UserResponse
    let tokens: TokenPair
}

struct RegisterResponse: Decodable, Sendable {
    let user: UserResponse
    
    private enum CodingKeys: String, CodingKey {
        case id, email, status, metadata, roles
        case emailVerifiedAt = "email_verified_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from decoder: Decoder) throws {
        user = try UserResponse(from: decoder)
    }
}

struct VerifyEmailResponse: Decodable, Sendable {
    let user: UserResponse
}

actor AuthService {
    static let shared = AuthService()
    private let client = HTTPClient.shared
    private let keychain = KeychainService.shared

    private init() {}

    func login(email: String, password: String) async throws -> UserResponse {
        let response: LoginResponse = try await client.request(.login(email: email, password: password))
        try keychain.saveTokens(response.tokens)
        return response.user
    }

    func register(email: String, password: String) async throws -> UserResponse {
        let response: UserResponse = try await client.request(.register(email: email, password: password))
        return response
    }

    func verifyEmail(email: String, code: String) async throws -> UserResponse {
        let response: VerifyEmailResponse = try await client.request(.verifyEmail(email: email, code: code))
        return response.user
    }

    func resendCode(email: String) async throws {
        let _: ResendCodeResponse = try await client.request(.resendCode(email: email))
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

struct ResendCodeResponse: Decodable, Sendable {
    let message: String
}

struct EmptyResponse: Decodable, Sendable {}
