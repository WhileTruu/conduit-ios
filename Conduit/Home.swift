import Combine
import SwiftUI

struct Home {
    // MODEL

    struct Model {
        let articles: [Article]
    }

    // UPDATE

    enum Msg {
        case gotArticles(articles: [Article])
    }

    static func update(msg: Msg, model: Model) -> (
        Model, AnyPublisher<Msg, Never>
    ) {
        switch msg {
        case .gotArticles(let articles):
            return (Model(articles: articles), Empty().eraseToAnyPublisher())
        }
    }

    static func fetchFeed() -> AnyPublisher<Msg, Never> {
        Article.fetchFeed()
            .replaceError(with: [])
            .map(Msg.gotArticles)
            .eraseToAnyPublisher()
    }

    // VIEW

    static func view() -> some View { HomeViewHost() }

    // STORE

    static func createStore() -> Store<Msg, Model> {
        let model = Model(articles: [])
        let effect = fetchFeed()

        return Store(model: model, effect: effect, update: update)
    }
}

private struct HomeViewHost: View {
    @ObservedObject var store = Home.createStore()

    var body: some View { HomeView(model: store.model, send: store.send) }
}

private struct HomeView: View {
    var model: Home.Model
    var send: (Home.Msg) -> Void

    var body: some View {
        NavigationView {
            List {
                if model.articles.isEmpty {
                    Text("Loading...")
                } else {
                    articles
                }
            }
            .navigationBarTitle(Text("Home"))
            .navigationBarItems(trailing: profileButton)
        }
    }

    let articleDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()

    var articles: some View {
        ForEach(model.articles) { article in
            NavigationLink(destination: ArticleView(article: article)) {
                self.articleRow(article: article)
            }
            .listRowInsets(
                EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
            )
        }
    }

    func articleRow(article: Article) -> some View {
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
                Text(article.author.username).font(
                    Font.bold(.subheadline)()
                )
                Text(
                    "\(article.updatedAt, formatter: articleDateFormatter)"
                )
                .font(.subheadline)
            }
        }
    }

    var profileButton: some View {
        NavigationLink(destination: Authentication.view()) {
            Image(systemName: "person.crop.circle")
                .imageScale(.large)
                .accessibility(label: Text("User Profile"))
                .padding()
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static func createArticle(index: Int) -> Article {
        Article(
            slug: Article.Slug(string: "rocket-progress-\(index)"),
            title: "Rocket progress \(index)",
            description: "Space must go faster",
            body:
                "Harasho progress, but 18 years to launch our first comrades is a long time. Technology must advance faster or there will be no kolkhoz on the red planet in our lifetime.",
            tagList: [""],
            createdAt: Date(timeIntervalSinceNow: -7200),
            updatedAt: Date(timeIntervalSinceNow: -3600),
            favorited: true,
            favoritesCount: 69,
            author: Article.Author(
                username: "Leon Umsk",
                bio: "🐓 🐂 ☀️ 🚛 🧠 🦠",
                image: "",
                following: true
            )
        )
    }

    static let articles = Array(0...20).map(createArticle)

    static var previews: some View {
        HomeView(model: Home.Model(articles: articles), send: { _ in })
    }
}
