import Combine
import SwiftUI

// MARK: MODEL

enum Model {
    case home(Home.Model)
    case yolo(Yolo.Model)
}

// MARK: UPDATE

enum Msg {
    case homeMsg(Home.Msg)
    case yoloMsg(Yolo.Msg)
    case changedPage(Page)
}

func update(model: Model, msg: Msg) -> (Model, AnyPublisher<Msg, Never>) {
    switch (msg, model) {
    case let (.homeMsg(pageMsg), .home(pageModel)):
        return updateWith(Model.home, Msg.homeMsg, Home.update(model: pageModel, msg: pageMsg))

    case let (.yoloMsg(pageMsg), .yolo(pageModel)):
        return updateWith(Model.yolo, Msg.yoloMsg, Yolo.update(model: pageModel, msg: pageMsg))

    case let (.changedPage(route), _):
        switch route {
        case .home: return updateWith(Model.home, Msg.homeMsg, Home.start())
        case .yolo: return updateWith(Model.yolo, Msg.yoloMsg, Yolo.start())
        }

    case (_, _):
        return (model, Empty().eraseToAnyPublisher())
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

private struct ContentView: View {
    @EnvironmentObject var app: Store<Model, Msg>

    var body: some View {
        let navigateTo = { self.app.send(.changedPage($0)) }

        switch app.model {
        case let .home(pageModel):
            return AnyView(Home.view(model: pageModel, navigateTo: navigateTo))

        case let .yolo(pageModel):
            return AnyView(Yolo.view(model: pageModel, navigateTo: navigateTo))
        }
    }
}

enum Page {
    case home
    case yolo
}

// MARK: STORE

func createContent() -> some View {
    let (model, effect) = updateWith(Model.home, Msg.homeMsg, Home.start())

    let store = Store(model: model, effect: effect, update: update)

    return ContentView().environmentObject(store)
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
