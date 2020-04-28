import Combine
import SwiftUI

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
