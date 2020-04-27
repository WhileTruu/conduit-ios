import SwiftUI

struct HomeContainerView: View {
    @EnvironmentObject var app: Store<Conduit.Model, Conduit.Msg>
    var model: Model {
        app.model
    }
    var send: (Msg) -> Void {
        app.send
    }
    
    var body: some View {
        HomeView(model: model, send: send)
    }
}

private struct HomeView: View {
    var model: Model
    var send: (Msg) -> Void

    var body: some View {
        NavigationView {
            List {
                if model.articles.isEmpty {
                    Text("Loading...")
                } else {
                    ForEach(model.articles) { article in
                        NavigationLink(
                            destination: ArticleView(article: article)
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

struct HomeView_Previews: PreviewProvider {
    static func createArticle(index: Int) -> Article {
        Article(
            slug: Article.Slug(string: "rocket-progress-\(index)"),
            title: "Rocket progress \(index)",
            description: "Space must go faster",
            body: "Harasho progress, but 18 years to launch our first comrades is a long time. Technology must advance faster or there will be no kolkhoz on the red planet in our lifetime.",
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
        HomeView(
            model: Model(articles: articles),
            send: { _ in }
        )
    }
}
