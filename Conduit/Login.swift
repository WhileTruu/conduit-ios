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
        case enteredEmail(_ email: String)
        case enteredPassword(_ password: String)
        case submittedForm
        case completedLogin(_ result: Result<User, Http.Error>)
        case savedToKeychainSuccess(_ user: User)
        case failedSaveToKeychain(_ user: User)
        case noOp
    }

    static func update(msg: Msg, model: Model) -> (Model, Pub<Msg>) {
        switch msg {
        case .enteredEmail(let email):
            return (model.copy(email: email), Pub.none())

        case .enteredPassword(let password):
            return (model.copy(password: password), Pub.none())

        case .submittedForm:
            return (model, login(email: model.email, password: model.password))

        case .completedLogin(.success(let user)):
            return (
                model,
                user.saveToKeychainPublisher()
                    .map { Msg.savedToKeychainSuccess(user) }
                    .catch { _ in Just(Msg.failedSaveToKeychain(user)) }
                    .toPub()
            )

        case .completedLogin(.failure(let error)):
            return (model.copy(loginResult: .failure(error)), Pub.none())

        case .savedToKeychainSuccess(let user):
            return (model.copy(loginResult: .success(user)), Pub.none())

        case .failedSaveToKeychain(let user):
            return (
                model.copy(loginResult: .success(user)),
                User.deleteFromKeychainPublisher()
                    .map { Msg.noOp }
                    .catch { _ in Just(Msg.noOp) }
                    .toPub()
            )

        case .noOp:
            return (model, Pub.none())
        }
    }

    // VIEW

    static func view() -> some View { LoginViewHost() }

    // STORE

    static func createStore() -> Store<Msg, Model> {
        Store(
            model: Login.Model(email: "", password: "", loginResult: nil),
            effect: Pub.none(),
            update: Login.update
        )
    }
}

private func login(email: String, password: String) -> Pub<Login.Msg> {
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
    .map(Login.Msg.completedLogin)
    .toPub()
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
            set: { self.send(.enteredEmail($0)) }
        )

        let password = Binding<String>(
            get: { self.model.password },
            set: { self.send(.enteredPassword($0)) }
        )

        return VStack(spacing: 8) {
            TextField("Username", text: email)
                .textFieldStyle(LoginTextFieldStyle())
                .autocapitalization(.none)
            SecureField("Password", text: password)
                .autocapitalization(.none)
                .textFieldStyle(LoginTextFieldStyle())

            Button(action: { self.send(.submittedForm) }) {
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
