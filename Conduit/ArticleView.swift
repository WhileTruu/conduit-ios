import SwiftUI

struct ArticleView: View {
    let article: Article

    var body: some View {
        VStack(alignment: .leading) {
            Text(article.title).font(.title)
            Text(article.description).font(.headline)
            Text(article.body).font(.body)
        }
        .padding()
        .frame(
            minWidth: 0, maxWidth: .infinity, minHeight: 0,
            maxHeight: .infinity, alignment: .topLeading
        )
        .navigationBarTitle("Article")
    }
}

struct ArticleView_Previews: PreviewProvider {
    static let article = Article(
        slug: Article.Slug("rocket-progress"),
        title: "Rocket progress",
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

    static var previews: some View {
        ArticleView(article: article)
    }
}
