import Combine
import SwiftUI

struct Login {
    // MODEL

    struct Model {
        let email: String
        let password: String

        func copy(email: String? = nil, password: String? = nil) -> Model {
            Model(
                email: email ?? self.email,
                password: password ?? self.password
            )
        }
    }

    // UPDATE

    enum Msg {
        case EnteredEmail(_ email: String)
        case EnteredPassword(_ password: String)
        case SubmittedForm
        case CompletedLogin
    }

    static func update(
        model: Model,
        msg: Msg
    ) -> (Model, AnyPublisher<Msg, Never>) {
        switch msg {
        case .EnteredEmail(let email):
            return (model.copy(email: email), Empty().eraseToAnyPublisher())

        case .EnteredPassword(let password):
            return (
                model.copy(password: password), Empty().eraseToAnyPublisher()
            )

        case _:
            return (model, Empty().eraseToAnyPublisher())
        }
    }

    // VIEW

    static func view() -> some View { LoginViewHost() }

    // STORE

    static func createStore() -> Store<Model, Msg> {
        Store(
            model: Login.Model(email: "", password: ""),
            effect: Empty().eraseToAnyPublisher(),
            update: Login.update
        )
    }
}

private struct LoginViewHost: View {
    @ObservedObject var store = Login.createStore()

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
            set: { self.send(.EnteredEmail($0)) }
        )

        let password = Binding<String>(
            get: { self.model.password },
            set: { self.send(.EnteredPassword($0)) }
        )

        return VStack {
            TextField("Username", text: email)
            TextField("Password", text: password)
            Button(action: {}) {
                Text("Button")
            }
        }.navigationBarTitle("Log in")

    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(
            model: Login.Model(email: "butt@dragon.io", password: "dragonbutt"),
            send: { _ in }
        )
    }
}
