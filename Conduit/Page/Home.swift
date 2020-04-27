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
        let model: Model
        let send: (Msg) -> Void

        var body: some View {
            NavigationView {
                List {
                    if model.articles.isEmpty {
                        Text("Loading...")
                    } else {
                        ForEach(model.articles) { article in
                            NavigationLink(
                                destination: ArticlePage.ContainerView(article: article)
                            ) {
                                ArticleRow(article: article)
                            }
                                .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
                        }
                    }
                }
                    .navigationBarTitle(Text("Home"))
            }
        }
    }

    private struct ArticleRow: View {
        let article: Article

        static let articleDateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            return formatter
        }()

        var body: some View {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Text(article.title)
                        .font(.headline)
                    Text(article.description)
                        .font(.subheadline)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }.padding(.bottom, 20)

                VStack(alignment: .leading) {
                    Text(article.author.username).font(Font.bold(.subheadline)())
                    Text("\(article.updatedAt, formatter: Self.articleDateFormatter)")
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


