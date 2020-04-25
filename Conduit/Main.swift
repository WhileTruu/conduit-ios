import Combine
import SwiftUI

// MARK: MODEL

enum Model {
    case home(Home.Model)
}

// MARK: UPDATE

enum Msg {
    case home(Home.Msg)
}

func update(model: Model, msg: Msg) -> (Model, AnyPublisher<Msg, Never>) {
    switch (msg, model) {
    case let (.home(pageMsg), .home(pageModel)):
        return updateWith(Model.home, Msg.home, Home.update(model: pageModel, msg: pageMsg))
    }
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

// MARK: VIEW

private struct view: View {
    @EnvironmentObject var app: Store<Model, Msg>

    var body: some View {
        switch app.model {
        case let .home(pageModel):
            return Home.view(model: pageModel)
        }
    }
}

// MARK: STORE

func createContent() -> some View {
    let (model, effect) = updateWith(Model.home, Msg.home, Home.start())

    let store = Store(model: model, effect: effect, update: update)

    return view().environmentObject(store)
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
