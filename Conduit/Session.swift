import Combine
import Foundation

struct Session {
    // MODEL

    struct Model {
        let user: User?
    }

    // UPDATE

    enum Msg {
        case savedUser(_ user: User)
        case removedUser
        case savedToKeychain(Result<User, KeychainError>)
        case removedFromKeychain(Result<Void, KeychainError>)
    }

    static func update(msg: Msg, model: Model) -> (Model, Pub<Msg>) {
        switch msg {
        case .savedUser(let user):
            return (model, saveToKeychain(user: user))

        case .removedUser:
            return (model, deleteFromKeychain())

        case .savedToKeychain(.success(let user)):
            return (Model(user: user), Pub.none())

        case .savedToKeychain(.failure(_)):
            return (Model(user: nil), deleteFromKeychain())

        case .removedFromKeychain(.success(_)):
            return (Model(user: nil), Pub.none())

        case .removedFromKeychain(.failure(_)):
            return (Model(user: nil), Pub.none())
        }
    }

    static func saveToKeychain(user: User) -> Pub<Msg> {
        saveToKeychainPublisher(user: user)
            .map { Msg.savedToKeychain(.success(user)) }
            .catch { Just(Msg.savedToKeychain(.failure($0))) }
            .toPub()
    }

    static func deleteFromKeychain() -> Pub<Msg> {
        deleteFromKeychainPublisher()
            .map { Msg.removedFromKeychain(.success($0)) }
            .catch { Just(Msg.removedFromKeychain(.failure($0))) }
            .toPub()
    }

    enum KeychainError: Error {
        case noItem
        case unexpectedUserData
        case unhandledError(status: OSStatus)
    }

    static func saveToKeychainPublisher(user: User) -> AnyPublisher<
        Void, KeychainError
    > {
        Future<Void, KeychainError> { promise in
            guard let userJsonData = try? JSONEncoder().encode(user) else {
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

    // STORE

    static func createStore() -> Store<Msg, Model> {
        let user: User? = {
            switch copyFromKeychain() {
            case .success(let user): return user
            case .failure: return nil
            }
        }()

        return Store(
            model: Model(user: user),
            effect: Pub.none(),
            update: update
        )
    }
}
