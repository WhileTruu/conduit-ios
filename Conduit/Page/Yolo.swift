import Foundation

import Foundation
import SwiftUI
import Combine

struct Yolo {
    // MARK: MODEL

    static func create() -> Model {
        Model(messageText: "Wassup")
    }

    struct Model {
        let messageText: String
    }

    // MARK: UPDATE

    enum Msg {
    }

    static func update(model: Model, msg: Msg) -> (Model, AnyPublisher<Msg, Never>) {
        (model, Empty().eraseToAnyPublisher())
    }

    // MARK: VIEW

    struct ContainerView: View {
        @EnvironmentObject var app: Store<Conduit.Model, Conduit.Msg>

        var body: some View {
            view(model: app.model.yolo)
        }
    }

    private struct view: View {
        let model: Model

        var body: some View {
            List {
                Text(model.messageText)
            }
                .navigationBarTitle(Text("Yolo"))
        }
    }
}
