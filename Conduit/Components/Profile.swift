import Combine
import Foundation
import SwiftUI

struct Profile {
    // ENV

    struct Env {
        let dismissView: Cmd<Msg>
        let removeUser: () -> AnyPublisher<Void, Error>
    }

    // MODEL

    struct Model {}

    // UPDATE

    enum Msg {
        case loggedOut
        case removedUser(_ result: Result<Void, Error>)
    }

    static func update(_ env: Env, _ msg: Msg, _ model: Model)
        -> (Model, Cmd<Msg>)
    {
        switch msg {
        case .loggedOut:
            return (
                model,
                env.removeUser()
                    .map { Msg.removedUser(.success($0)) }
                    .catch { Just(Msg.removedUser(.failure($0))) }
                    .toCmd()
            )
        case .removedUser(.success()):
            return (model, env.dismissView)

        case .removedUser(.failure(_)):
            return (model, Cmd.none())
        }
    }

    // VIEW

    static func view() -> some View { ProfileViewEnvProvider() }

    // STORE

    static func createStore(_ env: Env) -> Store<Msg, Model> {
        Store(
            model: Model(),
            effect: Cmd.none(),
            update: { update(env, $0, $1) }
        )
    }
}

private struct ProfileViewEnvProvider: View {
    @EnvironmentObject var session: Session
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ProfileViewHost(
            Profile.Env(
                dismissView: Cmd<Profile.Msg>.fromFunc {
                    self.presentationMode.wrappedValue.dismiss()
                },
                removeUser: session.removeUser
            )
        )
    }
}

struct ProfileViewHost: View {
    @ObservedObject var store: Store<Profile.Msg, Profile.Model>

    init(_ env: Profile.Env) { self.store = Profile.createStore(env) }

    var body: some View { ProfileView(send: store.send) }
}

private struct ProfileView: View {
    let send: (Profile.Msg) -> Void

    var body: some View {
        Button(
            action: { self.send(Profile.Msg.loggedOut) },
            label: { Text("Log out") }
        )
    }
}
