import Combine
import SwiftUI

struct Login {
    let dismissView: Cmd<Msg>
    let storeUser: (User) -> AnyPublisher<Void, Error>

    // MODEL

    struct Model {
        let user: User?
        let email: String
        let password: String

        func copy(
            user: User? = nil,
            email: String? = nil,
            password: String? = nil
        ) -> Model {
            Model(
                user: user ?? self.user,
                email: email ?? self.email,
                password: password ?? self.password
            )
        }
    }

    // UPDATE

    enum Msg {
        case enteredEmail(_ email: String)
        case enteredPassword(_ password: String)
        case submittedForm
        case completedLogin(_ result: Result<User, Http.Error>)
        case storedUser(_ result: Result<Void, Error>)
    }

    func update(_ msg: Msg, _ model: Model) -> (Model, Cmd<Msg>) {
        switch msg {
        case .enteredEmail(let email):
            return (model.copy(email: email), Cmd.none())

        case .enteredPassword(let password):
            return (model.copy(password: password), Cmd.none())

        case .submittedForm:
            return (model, login(email: model.email, password: model.password))

        case .completedLogin(.success(let user)):
            return (
                model.copy(user: user),
                storeUser(user)
                    .map { Msg.storedUser(.success($0)) }
                    .catch { Just(Msg.storedUser(.failure($0))) }
                    .toCmd()
            )

        case .completedLogin(.failure(_)):
            return (model, Cmd.none())

        case .storedUser(.success()):
            return (model, dismissView)

        case .storedUser(.failure(_)):
            return (model, Cmd.none())
        }
    }

    // VIEW

    static func view() -> some View { LoginViewEnvProvider() }

    // STORE

    func createStore(
        _ session: Session,
        _ presentationMode: Binding<PresentationMode>
    )
        -> Store<Msg, Model>
    {
        let model = Model(user: nil, email: "", password: "")

        return Store(
            model: model,
            effect: Cmd.none(),
            update: update
        )
    }
}

private func login(email: String, password: String) -> Cmd<Login.Msg> {
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
    .toCmd()
}

private func createLoginRequestBody(email: String, password: String) -> Data? {
    let json: [String: Any] = ["user": ["email": email, "password": password]]

    do {
        return try JSONSerialization.data(withJSONObject: json, options: [])
    } catch {
        return nil
    }
}

struct LoginViewEnvProvider: View {
    @EnvironmentObject var session: Session
    @Environment(\.presentationMode) var presentationMode

    var body: some View { LoginViewHost(session, presentationMode) }
}

struct LoginViewHost: View {
    @ObservedObject var store: Store<Login.Msg, Login.Model>

    init(
        _ session: Session,
        _ presentationMode: Binding<PresentationMode>
    ) {
        let dismissView = Cmd<Login.Msg>.fromFunc {
            presentationMode.wrappedValue.dismiss()
        }

        self.store = Login(
            dismissView: dismissView,
            storeUser: session.storeUser
        )
        .createStore(session, presentationMode)
    }

    var body: some View {
        LoginView(model: store.model, send: store.send)
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
                user: nil,
                email: "email@email.io",
                password: "password"
            ),
            send: { _ in }
        )
    }
}
