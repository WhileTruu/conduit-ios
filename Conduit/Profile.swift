import Combine
import Foundation
import SwiftUI

struct Profile {
    // VIEW

    static func view() -> some View { ProfileViewHost() }
}

private struct ProfileViewHost: View {
    @EnvironmentObject var store: Store<Session.Msg, Session.Model>

    var body: some View {
        ProfileView(model: store.model, send: store.send)
    }
}

private struct ProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    var model: Session.Model
    var send: (Session.Msg) -> Void

    var body: some View {
        Button(
            action: {
                self.send(Session.Msg.removedUser)
                self.presentationMode.wrappedValue.dismiss()
            },
            label: { Text("Log out") }
        )
    }
}
