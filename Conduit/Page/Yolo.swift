import Foundation

import Foundation
import SwiftUI
import Combine

struct Yolo {
    // MARK: MODEL

    struct Model {
    }

    static func start() -> (Model, AnyPublisher<Msg, Never>) {
        (
            Model()
            , Empty().eraseToAnyPublisher()
        )
    }

    // MARK: UPDATE

    enum Msg {
    }

    static func update(model: Model, msg: Msg) -> (Model, AnyPublisher<Msg, Never>) {
        (model, Empty().eraseToAnyPublisher())
    }

    // MARK: VIEW

    struct view: View {
        let model: Model
        let navigateTo: (Page) -> Void

        var body: some View {
            HStack {
                Text("Wassup")

                Button("Go to yolo page.") {
                    self.navigateTo(Page.home)
                }
            }
        }
    }
}
