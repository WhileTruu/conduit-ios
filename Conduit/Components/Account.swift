import Combine
import SwiftUI

struct Account {
    // ENV

    struct Env {
        let removeUser: () -> AnyPublisher<Void, Error>
    }

    // MODEL

    struct Model {
        let sheetView: SheetView

        func copy(sheetView: SheetView? = nil) -> Model {
            Model(sheetView: sheetView ?? self.sheetView)
        }
    }

    enum SheetView {
        case signIn
        case signUp
        case none
    }

    // UPDATE

    enum Msg {
        case changedSheetView(_ sheetView: SheetView)
        case signedOut
        case removedUser(_ result: Result<Void, Error>)

    }

    static func update(_ env: Env, _ msg: Msg, _ model: Model)
        -> (Model, Cmd<Msg>)
    {
        switch msg {
        case .changedSheetView(let value):
            return (model.copy(sheetView: value), Cmd.none())

        case .signedOut:
            return (
                model,
                env.removeUser()
                    .map { Msg.removedUser(.success($0)) }
                    .catch { Just(Msg.removedUser(.failure($0))) }
                    .toCmd()
            )
        case .removedUser(.success()):
            return (model, Cmd.none())

        case .removedUser(.failure(_)):
            return (model, Cmd.none())
        }
    }

    // VIEW

    static func view() -> some View { AccountViewEnvProvider() }

    // STORE

    static func createStore(_ env: Env) -> Store<Msg, Model> {
        Store(
            model: Model(sheetView: .none),
            effect: Cmd.none(),
            update: {
                let x = update(env, $0, $1)
                print($0, x.0)
                return x
            }
        )
    }
}

private struct AccountViewEnvProvider: View {
    @EnvironmentObject var session: Session

    var body: some View { AccountViewHost(session: session) }
}

struct AccountViewHost: View {
    let session: Session
    @ObservedObject var store: Store<Account.Msg, Account.Model>

    init(session: Session) {
        self.store = Account.createStore(
            Account.Env(removeUser: session.removeUser)
        )
        self.session = session
    }

    var body: some View {
        AccountView(session: session, model: store.model, send: store.send)
    }
}

struct AccountView: View {
    let session: Session
    let model: Account.Model
    let send: (Account.Msg) -> Void

    var body: some View {
        let isShowingSignInSheet = Binding<Bool>(
            get: { self.model.sheetView == .signIn },
            set: { self.send(.changedSheetView($0 ? .signIn : .none)) }
        )

        let isShowingSignUpSheet = Binding<Bool>(
            get: { self.model.sheetView == .signUp },
            set: { self.send(.changedSheetView($0 ? .signUp : .none)) }
        )

        return ZStack(alignment: .top) {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)

            VStack(alignment: .leading, spacing: 30) {
                if session.user == nil {
                    Button(action: { self.send(.changedSheetView(.signIn)) }) {
                        HStack {
                            Text("Sign In").foregroundColor(Color(UIColor.link))
                            Spacer()
                        }
                    }
                    .buttonStyle(ConduitButtonStyle())
                    .sheet(isPresented: isShowingSignInSheet) {
                        SignIn.view().environmentObject(self.session)
                    }

                    Button(action: { self.send(.changedSheetView(.signUp)) }) {
                        HStack {
                            Text("Sign Up").foregroundColor(Color(UIColor.link))
                            Spacer()
                        }
                    }
                    .buttonStyle(ConduitButtonStyle())
                    .sheet(isPresented: isShowingSignUpSheet) {
                        SignUp.view()
                    }

                } else {
                    Button(action: { self.send(.signedOut) }) {
                        Text("Sign Out")
                    }
                    .buttonStyle(ConduitButtonStyle())
                    .foregroundColor(Color(UIColor.red))
                }

            }.padding()

        }
        .navigationBarTitle("Account")
    }
}

struct ConduitButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(
                configuration.isPressed
                    ? Color(UIColor.systemGray4)
                    : Color(UIColor.secondarySystemGroupedBackground)
            )
            .cornerRadius(10)
    }

}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        let session = Session(user: nil)
        let model = Account.Model(sheetView: .none)

        let accountView = AccountView(
            session: session,
            model: model,
            send: { _ in }
        )

        return Group {
            NavigationView {
                accountView
            }
            .environment(\.colorScheme, .light)

            NavigationView {
                accountView
            }
            .environment(\.colorScheme, .dark)
        }
    }
}
