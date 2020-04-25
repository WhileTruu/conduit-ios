import Foundation
import SwiftUI
import Combine

struct Home {
    // MARK: MODEL

    struct Model {
        let articles: [Article]
    }

    static func start() -> (Model, AnyPublisher<Msg, Never>) {
        (
            Model(articles: [])
            , Article.fetchFeed()
            .mapError { (error: Error) -> Error in
                print("Error: \(error.localizedDescription))")
                return error
            }
            .replaceError(with: [])
            .map { articles in
                Msg.gotArticles(articles: articles)
            }
            .eraseToAnyPublisher()
        )
    }

    // MARK: UPDATE

    enum Msg {
        case gotArticles(articles: [Article])
    }

    static func update(model: Model, msg: Home.Msg) -> (Model, AnyPublisher<Msg, Never>) {
        switch msg {
        case let .gotArticles(articles):
            return (model.copy(articles: articles), Empty().eraseToAnyPublisher())
        }
    }

    // MARK: VIEW

    struct view: View {
        let model: Model

        var body: some View {

            NavigationView {
                List {
                    if model.articles.isEmpty {
                        Text("Loading...")
                    } else {
                        ForEach(model.articles) {
                            ArticleRow(article: $0)
                        }
                    }
                }
                    .navigationBarTitle(Text("Conduit"))
            }
        }
    }

    private struct ArticleRow: View {
        let article: Article

        var body: some View {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(article.title)
                        .font(.headline)
                    Text(article.description)
                        .font(.subheadline)
                }
            }
        }
    }
}


private extension Home.Model {
    func copy(articles: [Article]? = nil) -> Home.Model {
        Home.Model(
            articles: articles ?? self.articles
        )
    }
}


