import SwiftUI

struct HomeView: View {
    @EnvironmentObject var app: Store<Conduit.Model, Conduit.Msg>
    var model: Model {
        app.model
    }
    var send: (Msg) -> Void {
        app.send
    }

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
