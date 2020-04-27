import Combine
import SwiftUI

// MARK: MODEL

struct Model {
    let home: Home.Model
    let yolo: ArticlePage.Model
}

// MARK: UPDATE

enum Msg {
    case homeMsg(Home.Msg)
    case yoloMsg(ArticlePage.Msg)
}

private func updateWith<SubModel, Model, SubMsg, Msg>(
    _ toModel: (SubModel) -> Model,
    _ toMsg: @escaping (SubMsg) -> Msg,
    _ result: (SubModel, AnyPublisher<SubMsg, Never>)
) -> (Model, AnyPublisher<Msg, Never>) {
    (toModel(result.0), result.1.map {
        toMsg($0)
    }.eraseToAnyPublisher())
}

func update(model: Model, msg: Msg) -> (Model, AnyPublisher<Msg, Never>) {
    switch msg {
    case let .homeMsg(pageMsg):
        return updateWith(
            { Model(home: $0, yolo: model.yolo) },
            Msg.homeMsg,
            Home.update(model: model.home, msg: pageMsg)
        )

    case let .yoloMsg(pageMsg):
        return updateWith(
            { Model(home: model.home, yolo: $0) },
            Msg.yoloMsg,
            ArticlePage.update(model: model.yolo, msg: pageMsg)
        )
    }
}

// MARK: STORE

func createStore() -> Store<Model, Msg> {
    let (home, homeEffect) = Home.create()
    let yolo = ArticlePage.create()

    let model = Model(home: home, yolo: yolo)
    let effect = homeEffect.map(Msg.homeMsg).eraseToAnyPublisher()

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
