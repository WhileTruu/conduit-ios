import Combine
import SwiftUI

final class Store<Msg, Model>: ObservableObject {
    @Published private(set) var model: Model

    private let update: (Msg, Model) -> (Model, Pub<Msg>)
    private var effectCancellables: Set<AnyCancellable> = []

    init(
        model: Model,
        effect: Pub<Msg>,
        update: @escaping (Msg, Model) -> (Model, Pub<Msg>)
    ) {
        self.update = update

        self.model = model
        effect
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: send)
            .store(in: &effectCancellables)
    }

    func send(_ msg: Msg) {
        let (model, effect) = update(msg, self.model)

        self.model = model
        effect
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: send)
            .store(in: &effectCancellables)
    }
}

typealias Pub<Msg> = AnyPublisher<Msg, Never>

extension Pub {
    static func none() -> Pub<Self.Output> { Empty().eraseToAnyPublisher() }
}

extension Publisher where Failure == Never {
    func toPub() -> Pub<Output> {
        self.eraseToAnyPublisher()
    }
}
