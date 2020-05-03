import Combine
import SwiftUI

struct Authentication {
    // MODEL

    struct Model {
        let hostedView: HostedView

        func copy(hostedView: HostedView? = nil) -> Model {
            Model(hostedView: hostedView ?? self.hostedView)
        }
    }

    enum HostedView {
        case signUp
        case login
    }

    // UPDATE

    enum Msg {
        case replacedView(_ hostedView: HostedView)
    }

    static func update(msg: Msg, model: Model) -> Model {
        switch msg {
        case .replacedView(let hostedView):
            return (model.copy(hostedView: hostedView))
        }
    }

    // VIEW

    static func view() -> some View { AuthenticationHost() }

    // STORE

    static func createStore() -> Store<Msg, Model> {
        Store(
            model: Model(hostedView: .signUp),
            effect: Pub.none(),
            update: { (update(msg: $0, model: $1), Pub.none()) }
        )
    }
}

private struct AuthenticationHost: View {
    @ObservedObject var store = Authentication.createStore()

    var body: some View {
        AuthenticationView(model: store.model, send: store.send)
    }
}

private struct AuthenticationView: View {
    let model: Authentication.Model
    let send: (Authentication.Msg) -> Void

    var body: some View {
        VStack {
            if model.hostedView == .signUp {
                Button(action: { self.send(.replacedView(.login)) }) {
                    Text("Already have an account?")
                }
                SignUp.view()
            } else {
                Button(action: { self.send(.replacedView(.signUp)) }) {
                    Text("Need an account?")
                }
                Login.view()
            }
        }
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView(
            model: Authentication.Model(hostedView: .login),
            send: { _ in }
        )
    }
}
