import Combine
import SwiftUI

final class Store<Msg, Model>: ObservableObject {
    @Published private(set) var model: Model

    private let update: (Msg, Model) -> (Model, Cmd<Msg>)
    private var effectCancellables: Set<AnyCancellable> = []

    init(
        model: Model,
        effect: Cmd<Msg>,
        update: @escaping (Msg, Model) -> (Model, Cmd<Msg>)
    ) {
        self.update = update
        self.model = model

        handleCmd(effect)
    }

    func send(_ msg: Msg) {
        let (model, effect) = update(msg, self.model)

        self.model = model
        handleCmd(effect)
    }

    func handleCmd(_ cmd: Cmd<Msg>) {
        switch cmd.value {
        case .publisher(let pub):
            pub.receive(on: DispatchQueue.main)
                .sink(receiveValue: send)
                .store(in: &effectCancellables)
        case .effect(let effect): effect()
        case .list(let list): list.forEach(handleCmd)
        case .none: break
        }
    }
}

struct Cmd<Msg> {
    fileprivate let value: CmdType<Msg>

    fileprivate enum CmdType<Msg> {
        case publisher(_ pub: AnyPublisher<Msg, Never>)
        case effect(_ effect: () -> Void)
        case list(_ list: [Cmd])
        case none
    }

    static func none() -> Cmd { Cmd(value: CmdType.none) }

    static func fromFunc(_ effect: @escaping () -> Void) -> Cmd {
        Cmd(value: .effect(effect))
    }

    static func batch(_ list: [Cmd]) -> Cmd {
        Cmd(value: .list(list))
    }
}

extension Publisher where Failure == Never {
    func toCmd() -> Cmd<Output> {
        Cmd<Output>(value: .publisher(self.eraseToAnyPublisher()))
    }
}
