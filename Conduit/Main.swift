import Combine
import SwiftUI

// MARK: MODEL

struct Model {
    let articles: [Article]
}

extension Model {
    func copy(articles: [Article]? = nil) -> Model {
        Model(
            articles: articles ?? self.articles
        )
    }
}

func start() -> (Model, AnyPublisher<Msg, Never>) {
    (Model(articles: [])
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

func update(model: Model, msg: Msg) -> (Model, AnyPublisher<Msg, Never>) {
    switch msg {
    case let .gotArticles(articles):
        return (
            model.copy(articles: articles),
            Empty().eraseToAnyPublisher()
        )
    }
}

// MARK: VIEW

struct MainView: View {
    @EnvironmentObject var app: Store<Model, Msg>

    var body: some View {
        let articles = app.model.articles

        return NavigationView {
            List {
                if articles.isEmpty {
                    Text("Loading...")
                } else {
                    ForEach(articles) {
                        ArticleRow(article: $0)
                    }
                }
            }
                .navigationBarTitle(Text("Conduit"))
        }
    }
}

struct ArticleRow: View {
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

// MARK: STORE

func createStore() -> Store<Model, Msg> {
    let model = Model(articles: [])
    let effect = Article.fetchFeed()
        .replaceError(with: [])
        .map { articles in
            Msg.gotArticles(articles: articles)
        }
        .eraseToAnyPublisher()

    return Store(
        model: model,
        effect: effect,
        update: update
    )
}

final class Store<Model, Msg>: ObservableObject {
    @Published private(set) var model: Model

    private let update: (Model, Msg) -> (Model, AnyPublisher<Msg, Never>)
    private var effectCancellables: Set<AnyCancellable> = []

    init(
        model: Model,
        effect: AnyPublisher<Msg, Never>,
        update: @escaping (Model, Msg) -> (Model, AnyPublisher<Msg, Never>)
    ) {
        self.update = update

        self.model = model
        effect
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: send)
            .store(in: &effectCancellables)
    }

    func send(_ msg: Msg) {
        let (model, effect) = update(self.model, msg)

        self.model = model
        effect
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: send)
            .store(in: &effectCancellables)
    }
}
