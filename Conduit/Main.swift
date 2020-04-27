import Combine
import SwiftUI

// MARK: MODEL

struct Model {
    let articles: [Article]
}

// MARK: UPDATE

enum Msg {
    case gotArticles(articles: [Article])
}

func update(model: Model, msg: Msg) -> (Model, AnyPublisher<Msg, Never>) {
    switch msg {
    case .gotArticles(let articles):
        return (Model(articles: articles), Empty().eraseToAnyPublisher())
    }
}

private func fetchFeed() -> AnyPublisher<Msg, Never> {
    Article.fetchFeed()
        .replaceError(with: [])
        .map(Msg.gotArticles)
        .eraseToAnyPublisher()
}

// MARK: STORE

func createStore() -> Store<Model, Msg> {
    let model = Model(articles: [])
    let effect = fetchFeed()

    return Store(model: model, effect: effect, update: update)
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
