import Combine
import SwiftUI

struct Login {
    // ENV

    struct Env {
        let dismissView: Cmd<Msg>
        let storeUser: (User) -> AnyPublisher<Void, Error>
    }

    // MODEL

    struct Model {
        let user: User?
        let username: String
        let password: String

        func copy(
            user: User? = nil,
            username: String? = nil,
            password: String? = nil
        ) -> Model {
            Model(
                user: user ?? self.user,
                username: username ?? self.username,
                password: password ?? self.password
            )
        }
    }

    // UPDATE

    enum Msg {
        case enteredUsername(_ email: String)
        case enteredPassword(_ password: String)
        case submittedForm
        case completedLogin(_ result: Result<User, Http.Error>)
        case storedUser(_ result: Result<Void, Error>)
        case clickedCancel
    }

    static func update(_ env: Env, _ msg: Msg, _ model: Model)
        -> (Model, Cmd<Msg>)
    {
        switch msg {
        case .enteredUsername(let username):
            return (model.copy(username: username), Cmd.none())

        case .enteredPassword(let password):
            return (model.copy(password: password), Cmd.none())

        case .submittedForm:
            return (
                model, login(email: model.username, password: model.password)
            )

        case .completedLogin(.success(let user)):
            return (
                model.copy(user: user),
                env.storeUser(user)
                    .map { Msg.storedUser(.success($0)) }
                    .catch { Just(Msg.storedUser(.failure($0))) }
                    .toCmd()
            )

        case .completedLogin(.failure(_)):
            return (model, Cmd.none())

        case .storedUser(.success()):
            return (model, env.dismissView)

        case .storedUser(.failure(_)):
            return (model, Cmd.none())

        case .clickedCancel:
            return (model, env.dismissView)
        }
    }

    // VIEW

    static func view() -> some View { LoginViewEnvProvider() }

    // STORE

    static func createStore(_ env: Env) -> Store<Msg, Model> {
        let model = Model(user: nil, username: "", password: "")

        return Store(
            model: model,
            effect: Cmd.none(),
            update: { update(env, $0, $1) }
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

    var body: some View {
        LoginViewHost(
            Login.Env(
                dismissView: Cmd<Login.Msg>.fromFunc {
                    self.presentationMode.wrappedValue.dismiss()
                },
                storeUser: session.storeUser
            )
        )
    }
}

struct LoginViewHost: View {
    @ObservedObject var store: Store<Login.Msg, Login.Model>

    init(_ env: Login.Env) { self.store = Login.createStore(env) }

    var body: some View {
        LoginView(model: store.model, send: store.send)
    }
}

private struct LoginView: View {
    let model: Login.Model
    let send: (Login.Msg) -> Void

    var body: some View {
        let username = Binding<String>(
            get: { self.model.username },
            set: { self.send(.enteredUsername($0)) }
        )

        let password = Binding<String>(
            get: { self.model.password },
            set: { self.send(.enteredPassword($0)) }
        )

        return VStack(alignment: .center, spacing: 36) {
            HStack {
                Button(action: { self.send(.clickedCancel) }) {
                    Text("Cancel").foregroundColor(Color(UIColor.link))
                }
                Spacer()
                Button(action: { self.send(.submittedForm) }) {
                    Text("Sign In").foregroundColor(Color(UIColor.link))
                }
            }

            Text("Sign In Requested").fontWeight(.bold).font(.largeTitle)

            LoginFormView(username: username, password: password)
                .padding(
                    EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 10)
                )
            Spacer()
        }
        .padding()
    }
}

private struct LoginFormView: View {
    @Binding var username: String
    @Binding var password: String
    @State private var maxLabelWidth: CGFloat? = nil

    var body: some View {
        Group {
            VStack(spacing: 0) {
                HStack {
                    Text("Username")
                        .frame(width: maxLabelWidth, alignment: .leading)
                        .lineLimit(1)
                        .background(WidthPreferenceGeometryView())
                    TextField("Username", text: $username)
                        .textFieldStyle(LoginTextFieldStyle())
                }
                Divider()
                HStack {
                    Text("Password")
                        .frame(width: maxLabelWidth, alignment: .leading)
                        .lineLimit(1)
                        .background(WidthPreferenceGeometryView())
                    SecureField("Password", text: $password)
                        .textFieldStyle(LoginTextFieldStyle())
                }
                Divider()
            }.onPreferenceChange(WidthPreferenceKey.self) { preferences in
                for p in preferences {
                    if p.width > (self.maxLabelWidth ?? CGFloat.zero) {
                        self.maxLabelWidth = p.width
                    }
                }
            }
        }
    }
}

private struct LoginTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .padding(EdgeInsets(top: 10, leading: 25, bottom: 10, trailing: 0))
            .autocapitalization(.none)
            .frame(maxWidth: .infinity)
    }
}

private struct WidthPreferenceKey: PreferenceKey {
    typealias Value = [WidthPreference]

    static var defaultValue: [WidthPreference] = []

    static func reduce(
        value: inout [WidthPreference],
        nextValue: () -> [WidthPreference]
    ) {
        value.append(contentsOf: nextValue())
    }
}

private struct WidthPreference: Equatable {
    let width: CGFloat
}

private struct WidthPreferenceGeometryView: View {
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Color.clear)
                .preference(
                    key: WidthPreferenceKey.self,
                    value: [
                        WidthPreference(
                            width: geometry.frame(in: CoordinateSpace.global)
                                .width
                        )
                    ]
                )
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        let loginView = LoginView(
            model: Login.Model(
                user: nil,
                username: "email@email.io",
                password: "password"
            ),
            send: { _ in }
        )
        return Group {
            NavigationView { loginView }.environment(\.colorScheme, .light)
            NavigationView { loginView }.environment(\.colorScheme, .dark)
        }
    }
}
