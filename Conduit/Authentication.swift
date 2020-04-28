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
        case SignUp
        case Login
    }

    // UPDATE

    enum Msg {
        case ReplacedView(_ hostedView: HostedView)
    }

    static func update(model: Model, msg: Msg) -> Model {
        switch msg {
        case .ReplacedView(let hostedView):
            return (model.copy(hostedView: hostedView))

        case _:
            return model
        }
    }

    // VIEW

    static func view() -> some View { AuthenticationHost() }

    // STORE

    static func createStore() -> Store<Model, Msg> {
        Store<Model, Msg>(
            model: Model(hostedView: .SignUp),
            effect: Empty().eraseToAnyPublisher(),
            update: { model, msg in
                (update(model: model, msg: msg), Empty().eraseToAnyPublisher())
            }
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
            if model.hostedView == .SignUp {
                Button(action: { self.send(.ReplacedView(.Login)) }) {
                    Text("Already have an account?")
                }
                SignUp.view()
            } else {
                Button(action: { self.send(.ReplacedView(.SignUp)) }) {
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
            model: Authentication.Model(hostedView: .Login),
            send: { _ in }
        )
    }
}
