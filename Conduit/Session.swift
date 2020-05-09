import Combine
import Foundation

class Session: ObservableObject {
    @Published private(set) var user: User?

    init() {
        self.user = {
            switch Keychain.copyFromKeychain() {
            case .success(let user): return user
            case .failure: return nil
            }
        }()
    }

    init(user: User?) {
        self.user = user
    }

    func storeUser(_ user: User) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { promise in
            let replaceUserInKeychain = Keychain.deleteFromKeychain()
                .flatMap({ _ in Keychain.saveToKeychain(user: user) })

            switch replaceUserInKeychain {
            case .success:
                self.user = user
                promise(.success(Void()))
            case .failure(let error): promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }

    func removeUser() -> AnyPublisher<Void, Error> {
        Future<Void, Error> { promise in
            switch Keychain.deleteFromKeychain() {
            case .success:
                self.user = nil
                promise(.success(Void()))
            case .failure(let error): promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
}

struct Keychain {
    enum Error: Swift.Error {
        case noItem
        case unexpectedUserData
        case unhandledError(status: OSStatus)
    }

    static func saveToKeychain(user: User) -> Result<Void, Error> {
        guard let userJsonData = try? JSONEncoder().encode(user) else {
            return (.failure(.unexpectedUserData))
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrLabel as String: "user",
            kSecValueData as String: userJsonData,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            return (.failure(.unhandledError(status: status)))
        }
        return (.success(Void()))
    }

    static func deleteFromKeychain() -> Result<Void, Error> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrLabel as String: "user",
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            return .failure(.unhandledError(status: status))
        }
        return .success(Void())
    }

    static func copyFromKeychain() -> Result<User, Error> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrLabel as String: "user",
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true,
        ]

        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else {
            return .failure(.noItem)

        }
        guard status == errSecSuccess else {
            return
                .failure(.unhandledError(status: status))
        }

        guard
            let userData = item as? Data,
            let user: User = try? JSONDecoder().decode(
                User.self,
                from: userData
            )
        else {
            return .failure(.unexpectedUserData)
        }
        return .success(user)
    }
}
