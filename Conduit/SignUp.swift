import SwiftUI

struct SignUp {
    // VIEW

    static func view() -> some View { ViewHost() }
}

private struct ViewHost: View {
    var body: some View { SignUpView() }
}

private struct SignUpView: View {
    var body: some View {
        VStack {
            Text("YOLO")
        }
        .navigationBarTitle("Sign up")
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
