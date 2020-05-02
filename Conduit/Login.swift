import Combine
import SwiftUI

struct Login {
    // MODEL

    struct Model {
        let email: String
        let password: String
        let loginResult: Result<User, Http.Error>?

        func copy(
            email: String? = nil,
            password: String? = nil,
            loginResult: Result<User, Http.Error>? = nil
        ) -> Model {
            Model(
                email: email ?? self.email,
                password: password ?? self.password,
                loginResult: loginResult ?? self.loginResult
            )
        }
    }

    // UPDATE

    enum Msg {
        case EnteredEmail(_ email: String)
        case EnteredPassword(_ password: String)
        case SubmittedForm
        case CompletedLogin(_ result: Result<User, Http.Error>)
        case SavedToKeychainSuccess(_ user: User)
        case FailedSaveToKeychain(_ user: User)
        case NoOp
    }

    static func update(msg: Msg, model: Model) -> (
        Model, AnyPublisher<Msg, Never>
    ) {
        switch msg {
        case .EnteredEmail(let email):
            return (model.copy(email: email), Empty().eraseToAnyPublisher())

        case .EnteredPassword(let password):
            return (
                model.copy(password: password),
                Empty().eraseToAnyPublisher()
            )

        case .SubmittedForm:
            return (
                model,
                login(email: model.email, password: model.password)
                    .map(Msg.CompletedLogin)
                    .eraseToAnyPublisher()
            )

        case .CompletedLogin(.success(let user)):
            return (
                model,
                user.saveToKeychainPublisher()
                    .map { Msg.SavedToKeychainSuccess(user) }
                    .catch { _ in Just(Msg.FailedSaveToKeychain(user)) }
                    .eraseToAnyPublisher()
            )

        case .CompletedLogin(.failure(let error)):
            return (
                model.copy(loginResult: .failure(error)),
                Empty().eraseToAnyPublisher()
            )

        case .SavedToKeychainSuccess(let user):
            return (
                model.copy(loginResult: .success(user)),
                Empty().eraseToAnyPublisher()
            )

        case .FailedSaveToKeychain(let user):
            return (
                model.copy(loginResult: .success(user)),
                User.deleteFromKeychainPublisher()
                    .map { Msg.NoOp }
                    .catch { _ in Just(Msg.NoOp) }
                    .eraseToAnyPublisher()
            )

        case .NoOp:
            return (model, Empty().eraseToAnyPublisher())
        }
    }

    // VIEW

    static func view() -> some View { LoginViewHost() }

    // STORE

    static func createStore() -> Store<Msg, Model> {
        Store(
            model: Login.Model(email: "", password: "", loginResult: nil),
            effect: Empty().eraseToAnyPublisher(),
            update: Login.update
        )
    }
}

private func login(email: String, password: String) -> AnyPublisher<
    Result<User, Http.Error>, Never
> {
    guard
        let url = URL(
            string: "https://conduit.productionready.io/api/users/login"
        )
    else { preconditionFailure() }

    return Http.post(
        url: url,
        body: createLoginRequestBody(email: email, password: password),
        decoder: JSONDecoder()
    )
    .map(Result.success)
    .catch { Just(Result.failure($0)) }
    .eraseToAnyPublisher()
}

private func createLoginRequestBody(email: String, password: String) -> Data? {
    let json: [String: Any] = ["user": ["email": email, "password": password]]

    do {
        return try JSONSerialization.data(withJSONObject: json, options: [])
    } catch {
        return nil
    }
}

private struct LoginViewHost: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var store: Store = Login.createStore()

    var body: some View {
        if case .success = store.model.loginResult {
            self.presentationMode.wrappedValue.dismiss()
        }

        return LoginView(model: store.model, send: store.send)
    }
}

private struct LoginView: View {
    let model: Login.Model
    let send: (Login.Msg) -> Void

    var body: some View {
        let email = Binding<String>(
            get: { self.model.email },
            set: { self.send(.EnteredEmail($0)) }
        )

        let password = Binding<String>(
            get: { self.model.password },
            set: { self.send(.EnteredPassword($0)) }
        )

        return VStack(spacing: 8) {
            TextField("Username", text: email)
                .textFieldStyle(LoginTextFieldStyle())
                .autocapitalization(.none)
            SecureField("Password", text: password)
                .autocapitalization(.none)
                .textFieldStyle(LoginTextFieldStyle())

            Button(action: { self.send(.SubmittedForm) }) {
                Text("Button")
            }
            .buttonStyle(LoginButtonStyle())
        }
        .padding()
        .navigationBarTitle("Log in")
    }
}

private struct LoginTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.gray, lineWidth: 1)
            )
    }
}

private struct LoginButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(8)
            .foregroundColor(Color.white)
            .background(Color.green)
            .cornerRadius(8)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(
            model: Login.Model(
                email: "email@email.io",
                password: "password",
                loginResult: nil
            ),
            send: { _ in }
        )
    }
}
