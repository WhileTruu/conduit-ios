import Combine
import Foundation
import SwiftUI

struct Profile {
    let dismissView: Cmd<Msg>
    let removeUser: () -> AnyPublisher<Void, Error>

    // MODEL
    struct Model {}

    // UPDATE

    enum Msg {
        case loggedOut
        case removedUser(_ result: Result<Void, Error>)
    }

    func update(_ msg: Msg, _ model: Model) -> (Model, Cmd<Msg>) {
        switch msg {
        case .loggedOut:
            return (
                model,
                removeUser()
                    .map { Msg.removedUser(.success($0)) }
                    .catch { Just(Msg.removedUser(.failure($0))) }
                    .toCmd()
            )
        case .removedUser(.success()):
            return (model, dismissView)

        case .removedUser(.failure(_)):
            return (model, Cmd.none())
        }
    }

    // VIEW

    static func view() -> some View { ProfileViewEnvProvider() }

    // STORE

    func createStore() -> Store<Msg, Model> {
        Store(model: Model(), effect: Cmd.none(), update: update)
    }
}

private struct ProfileViewEnvProvider: View {
    @EnvironmentObject var session: Session
    @Environment(\.presentationMode) var presentationMode

    var body: some View { ProfileViewHost(session, presentationMode) }
}

struct ProfileViewHost: View {
    @ObservedObject var store: Store<Profile.Msg, Profile.Model>

    init(_ session: Session, _ presentationMode: Binding<PresentationMode>) {
        let dismissView = Cmd<Profile.Msg>.fromFunc {
            presentationMode.wrappedValue.dismiss()
        }

        self.store = Profile(
            dismissView: dismissView,
            removeUser: session.removeUser
        ).createStore()
    }

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
