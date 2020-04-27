import Foundation

import Foundation
import SwiftUI
import Combine

struct ArticlePage {
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
        let article: Article

        var body: some View {
            view(model: app.model.yolo, article: article)
        }
    }

    private struct view: View {
        let model: Model
        let article: Article

        var body: some View {
            VStack(alignment: .leading) {
                Text(article.title).font(.title)
                Text(article.description).font(.headline)
                Text(article.body).font(.body)
            }
                .padding()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                .navigationBarTitle("Article")
        }
    }
}
