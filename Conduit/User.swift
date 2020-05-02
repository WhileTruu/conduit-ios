import Combine
import Foundation

struct User {
    let token: String
    let username: String
    let image: String?
}

extension User: Codable {
    enum CodingKeys: CodingKey {
        case user
        case token
        case username
        case image
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let user = try container.nestedContainer(
            keyedBy: CodingKeys.self,
            forKey: .user
        )
        token = try user.decode(String.self, forKey: .token)
        username = try user.decode(String.self, forKey: .username)
        image = try user.decodeIfPresent(String.self, forKey: .image)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var user = container.nestedContainer(
            keyedBy: CodingKeys.self,
            forKey: .user
        )
        try user.encode(token, forKey: .token)
        try user.encode(username, forKey: .username)
        try user.encode(image, forKey: .image)
    }
}

extension User {
    enum KeychainError: Error {
        case noItem
        case unexpectedUserData
        case unhandledError(status: OSStatus)
    }

    func saveToKeychainPublisher() -> AnyPublisher<Void, KeychainError> {
        Future<Void, KeychainError> { promise in
            guard let userJsonData = try? JSONEncoder().encode(self) else {
                return promise(.failure(KeychainError.unexpectedUserData))
            }

            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrLabel as String: "user",
                kSecValueData as String: userJsonData,
            ]

            let status = SecItemAdd(query as CFDictionary, nil)
            guard status == errSecSuccess else {
                return promise(
                    .failure(KeychainError.unhandledError(status: status))
                )
            }
            return promise(.success(Void()))
        }
        .eraseToAnyPublisher()
    }

    static func copyFromKeychainPublisher() -> AnyPublisher<User, KeychainError>
    {
        Future<User, KeychainError> { promise in
            switch copyFromKeychain() {
            case .failure(let error): promise(.failure(error))
            case .success(let user): promise(.success(user))
            }
        }
        .eraseToAnyPublisher()
    }

    static func deleteFromKeychainPublisher() -> AnyPublisher<
        Void, KeychainError
    > {
        Future<Void, KeychainError> { promise in
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrLabel as String: "user",
            ]
            let status = SecItemDelete(query as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                return promise(
                    .failure(KeychainError.unhandledError(status: status))
                )
            }
            return promise(.success(Void()))
        }
        .eraseToAnyPublisher()
    }

    static func copyFromKeychain() -> Result<User, KeychainError> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrLabel as String: "user",
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true,
        ]

        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else {
            return .failure(KeychainError.noItem)

        }
        guard status == errSecSuccess else {
            return
                .failure(KeychainError.unhandledError(status: status))
        }

        guard
            let userData = item as? Data,
            let user: User = try? JSONDecoder().decode(
                User.self,
                from: userData
            )
        else {
            return .failure(KeychainError.unexpectedUserData)
        }
        return .success(user)
    }
}
