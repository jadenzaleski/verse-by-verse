import SwiftUI

struct LoginOrRegisterView: View {
    @Binding var showLogin: Bool
    @State var email: String = ""
    @State var password: String = ""
    @State var confirmedPassword: String = ""
    @State var name: String = ""
    @State var isRegistering: Bool = false
    @State var isAttemptingLogin: Bool = false
    @State var isAttemptingRegistration: Bool = false

    private let log = AppLog.category("LoginOrRegisterView")

    var body: some View {
        VStack(spacing: 15) {
            Image("lucide.book.open.text")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [Color("CustomPurple"), Color("CustomGreen")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing,
                    ),
                )
                .shadow(color: .black.opacity(0.15), radius: 2, x: 2, y: 2)
            HStack {
                Text(isRegistering ? "Hey there!" : "Welcome back!")
                    .font(.app(.title2, weight: .semibold))
                Spacer()
            }

            if isRegistering {
                TextField("Name", text: $name)
                    .textContentType(.name)
                    .roundedInput()
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .move(edge: .leading).combined(with: .opacity)))
                    .animation(.spring(.snappy), value: isRegistering)
            }
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .roundedInput()

            SecureField("Password", text: $password)
                .textContentType(isRegistering ? .newPassword : .password)
                .roundedInput()

            if isRegistering {
                SecureField("Confirm Password", text: $confirmedPassword)
                    .textContentType(.newPassword)
                    .roundedInput()
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .move(edge: .leading).combined(with: .opacity)))
                    .animation(.spring(.snappy), value: isRegistering)
            }

            Button {
                loginOrRegister()
            } label: {
                ZStack {
                    Text(isRegistering ? "Sign Up" : "Log In")
                        .opacity(0) // invisible but participates in layout
                        .frame(maxWidth: .infinity)

                    if isAttemptingLogin || isAttemptingRegistration {
                        ProgressView()
                    } else {
                        Text(isRegistering ? "Sign Up" : "Log In")
                    }
                }
                .padding(.vertical, 12)
                .tint(.white)
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.accent),
            )

            Button {
                withAnimation(.spring(.snappy)) {
                    isRegistering.toggle()
                }
            } label: {
                Text(isRegistering ? "Already have an account? Log in!" : "Don't have an account? Sign up!")
            }
            .transition(.opacity)
            .animation(.spring(response: 0.35, dampingFraction: 0.9, blendDuration: 0.1), value: isRegistering)

            if isRegistering {
                Text("You will never receive marketing or promotional emails.")
                    .font(.app(.caption2))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
    }

    private func loginOrRegister() {
        log.info("Logging in or registering...")
        if isRegistering {
            isAttemptingRegistration = true
        } else {
            isAttemptingLogin = true
        }
        // Simulate a delay before login
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isAttemptingLogin = false
            isAttemptingRegistration = false
            showLogin = false
        }
    }
}

private struct RoundedTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemBackground)),
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1),
            )
    }
}

private extension View {
    func roundedInput() -> some View { modifier(RoundedTextFieldStyle()) }
}

#Preview {
    LoginOrRegisterView(showLogin: .constant(false))
        .environment(\.font, .app())
}
