import SwiftUI

struct LoginOrRegisterView: View {
    @AppStorage(.id) private var id: String?
    @AppStorage(.name) private var name: String?
    @AppStorage(.email) private var email: String?
    @Binding var showLogin: Bool
    @State private var formEmail: String = ""
    @State private var password: String = ""
    @State private var confirmedPassword: String = ""
    @State private var formName: String = ""
    @State private var isRegistering: Bool = true
    @State private var isAttemptingLogin: Bool = false
    @State private var isAttemptingRegistration: Bool = false
    @State private var submitState: SubmitState = .idle
    @State private var successTrigger = 0
    private let log = AppLog.category("LoginOrRegisterView")
    @State private var showValidationResults = false
    private var isNameValid: Bool {
        let trimmed = formName.trimmingCharacters(in: .whitespacesAndNewlines)
        // Minimum length after trimming
        guard trimmed.count >= 2 else { return false }

        let allowed = CharacterSet.letters
            .union(.whitespaces)
            .union(.urlQueryAllowed)
            .union(CharacterSet(charactersIn: "-'"))
        return trimmed.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    private var isPasswordValid: Bool {
        password.count >= 8
    }

    private var isConfirmedPasswordValid: Bool {
        password == confirmedPassword && !confirmedPassword.isEmpty
    }

    private var canSubmit: Bool {
        if isRegistering {
            isNameValid && isEmailValid(formEmail) && isPasswordValid && isConfirmedPasswordValid
        } else {
            isEmailValid(formEmail) && isPasswordValid
        }
    }

    private var validationError: String {
        if isRegistering {
            if !isNameValid {
                return "You must enter a valid name without special characters."
            }
            if !isConfirmedPasswordValid {
                return "Your passwords do not match."
            }
        }

        if !isEmailValid(formEmail) {
            return "You must enter a valid email."
        }
        // Last one is the passoword
        return "Your password must be at least 8 characters long."
    }

    @State private var loginRegisterError: String = ""

    private var errorText: String {
        if showValidationResults, !canSubmit {
            return validationError
        } else if !loginRegisterError.isEmpty {
            return loginRegisterError
        }
        // No errors, return a space to avoid spacing issues
        return " "
    }

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
                TextField("Name", text: $formName)
                    .textContentType(.name)
                    .roundedInput()
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .move(edge: .leading).combined(with: .opacity)))
                    .animation(.spring(.snappy), value: isRegistering)
                    .overlay(alignment: .trailing) {
                        validationIcon(isNameValid)
                    }
            }

            TextField("Email", text: $formEmail)
                .keyboardType(.emailAddress)
                .textContentType(.username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .roundedInput()
                .overlay(alignment: .trailing) {
                    validationIcon(isEmailValid(formEmail))
                }

            SecureField("Password", text: $password)
                .textContentType(isRegistering ? .newPassword : .password)
                .roundedInput()
                .overlay(alignment: .trailing) {
                    validationIcon(isPasswordValid)
                }

            if isRegistering {
                SecureField("Confirm Password", text: $confirmedPassword)
                    .textContentType(.newPassword)
                    .roundedInput()
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .move(edge: .leading).combined(with: .opacity)))
                    .animation(.spring(.snappy), value: isRegistering)
                    .overlay(alignment: .trailing) {
                        validationIcon(isConfirmedPasswordValid)
                    }
            }

            Button {
                withAnimation(.spring(.bouncy(duration: 0.25))) {
                    showValidationResults = true
                }
                if canSubmit {
                    Task {
                        if isRegistering {
                            await register()
                        } else {
                            await login()
                        }
                    }
                } else {
                    log.warning("Attempted to submit Login/Register with invalid form data")
                }
            } label: {
                ZStack {
                    Text(isRegistering ? "Sign Up" : "Log In")
                        .opacity(submitState == .idle ? 1 : 0)

                    if submitState == .loading {
                        ProgressView()
                            .transition(.opacity)
                    }

                    if submitState == .success {
                        Image("lucide.circle.check.fill")
                            .scaleEffect(1.3)
                            .transition(.scale.combined(with: .opacity))
                    }

                    if submitState == .error {
                        Image("lucide.circle.x.fill")
                            .scaleEffect(1.3)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity)
                .animation(.bouncy, value: submitState)
                .padding(.vertical, 12)
                .tint(.white)
                .sensoryFeedback(.success, trigger: successTrigger)
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.accent),
            )
            .disabled(submitState == .loading)

            Button {
                withAnimation(.spring(.snappy)) {
                    isRegistering.toggle()
                    showValidationResults = false
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

            Text("\(errorText)")
                .font(.app(.footnote))
                .foregroundStyle(.red)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func validationIcon(_ isValid: Bool) -> some View {
        if showValidationResults {
            Image(isValid ? "lucide.circle.check" : "lucide.circle.x")
                .scaleEffect(1.3)
                .foregroundStyle(isValid ? .green : .red)
                .transition(.scale.combined(with: .opacity))
                .padding(.horizontal, 12)
        }
    }

    private func login() async {
        submitState = .loading
        do {
            let result = try await APIService.shared.postLogin(email: formEmail, password: password)
            // save the tokens
            try KeychainManager.saveAccessToken(result.accessToken)
            try KeychainManager.saveRefreshToken(result.refreshToken)
            // if we get here, loging was a success, so react to that
            successTrigger += 1
            loginRegisterError = ""
            submitState = .success
            try? await Task.sleep(nanoseconds: 400_000_000)
            showLogin = false
        } catch let apiError as APIError {
            log.error("API Error: \(apiError)")
            submitState = .error
            if apiError.localizedDescription == "LOGIN_BAD_CREDENTIALS" {
                loginRegisterError = "Invalid email or password."
            } else if apiError.statusCode == 422 {
                loginRegisterError = "Validation error, pleasure ensure proper credentials."
            } else {
                loginRegisterError = apiError.localizedDescription
            }
        } catch {
            log.error("Unexpected Error: \(error)")
            loginRegisterError = "Unknown error, please try again."
            submitState = .error
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                submitState = .idle
            }
        }
    }

    private func register() async {
        submitState = .loading

        do {
            let registerResult = try await APIService.shared.postRegister(name: formName,
                                                                          email: formEmail,
                                                                          password: password)

            id = registerResult.id
            name = registerResult.firstName
            email = registerResult.email
            // Now attempt to login to get the tokens
            let loginResult = try await APIService.shared.postLogin(email: formEmail, password: password)
            // save the tokens
            try KeychainManager.saveAccessToken(loginResult.accessToken)
            try KeychainManager.saveRefreshToken(loginResult.refreshToken)
            // if we get here, registering was a success, so react to that
            successTrigger += 1
            loginRegisterError = ""
            submitState = .success
            try? await Task.sleep(nanoseconds: 400_000_000)
            showLogin = false
        } catch let apiError as APIError {
            log.error("API Error: \(apiError)")
            submitState = .error
            if apiError.localizedDescription == "REGISTER_USER_ALREADY_EXISTS" {
                loginRegisterError = "User with this email already exists."
            } else if apiError.localizedDescription == "REGISTER_INVALID_PASSWORD" {
                loginRegisterError = "Password should beat least 3 characters"
            } else if apiError.statusCode == 422 {
                loginRegisterError = "Validation error, please ensure fields are valid."
            } else {
                loginRegisterError = apiError.localizedDescription
            }
        } catch {
            log.error("Unexpected Error: \(error)")
            loginRegisterError = "Unknown error, please try again."
            submitState = .error
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                submitState = .idle
            }
        }
    }

    private func isEmailValid(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,64}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
        return emailPredicate.evaluate(with: email)
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

enum SubmitState {
    case idle, loading, success, error
}

#Preview {
    LoginOrRegisterView(showLogin: .constant(false))
        .environment(\.font, .app())
}
