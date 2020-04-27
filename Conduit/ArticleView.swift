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
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
            .navigationBarTitle("Article")
    }
}
