import Foundation
import SwiftUI
import Combine

struct Home {
    // MARK: MODEL

    struct Model {
        let articles: [Article]
    }

    static func create() -> (Model, AnyPublisher<Msg, Never>) {
        (Model(articles: []), fetchFeed())
    }

    // MARK: UPDATE

    enum Msg {
        case gotArticles(articles: [Article])
    }

    static func update(model: Model, msg: Msg) -> (Model, AnyPublisher<Msg, Never>) {
        switch msg {
        case .gotArticles(let articles):
            return (model.copy(articles: articles), Empty().eraseToAnyPublisher())
        }
    }

    static private func fetchFeed() -> AnyPublisher<Msg, Never> {
        Article.fetchFeed()
            .replaceError(with: [])
            .map(Msg.gotArticles)
            .eraseToAnyPublisher()
    }

    // MARK: VIEW

    struct ContainerView: View {
        @EnvironmentObject var app: Store<Conduit.Model, Conduit.Msg>

        var body: some View {
            view(model: app.model.home, send: { self.app.send(.homeMsg($0)) })
        }
    }

    private struct view: View {
        let model : Model
        let send : (Msg) -> Void

        var body: some View {
            NavigationView {
                List {
                    NavigationLink(destination: Yolo.ContainerView(), label: {
                        Text("To YOOOLO PAGE!")
                    })

                    if model.articles.isEmpty {
                        Text("Loading...")
                    } else {
                        ForEach(model.articles) {
                            ArticleRow(article: $0)
                        }
                    }
                }
                    .navigationBarTitle(Text("Home"))
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


