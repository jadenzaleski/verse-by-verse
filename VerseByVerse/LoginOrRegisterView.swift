import SwiftUI

struct LoginOrRegisterView: View {
    @Binding var showLogin: Bool
    @Environment(UserStore.self) private var userStore
    @State private var formEmail: String = ""
    @State private var password: String = ""
    @State private var confirmedPassword: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var isRegistering: Bool = true
    @State private var successTrigger = 0
    private let log = AppLog.category("LoginOrRegisterView")
    @State private var showValidationResults = false
    @AppStorage(StorageKeys.firstLaunch.rawValue) private var isFirstLaunch: Bool = true

    private var isPasswordValid: Bool {
        password.count >= 8
    }

    private var isConfirmedPasswordValid: Bool {
        password == confirmedPassword && !confirmedPassword.isEmpty
    }

    private var canSubmit: Bool {
        if isRegistering {
            isNameValid(firstName)
                && isNameValid(lastName)
                && isEmailValid(formEmail)
                && isPasswordValid
                && isConfirmedPasswordValid
        } else {
            isEmailValid(formEmail) && isPasswordValid
        }
    }

    private var validationError: String {
        if isRegistering {
            if !isNameValid(firstName) || !isNameValid(lastName) {
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

    private var errorText: String {
        if showValidationResults, !canSubmit {
            return validationError
        } else if let apiError = userStore.lastError {
            // Map common API errors to user-friendly messages
            let desc = apiError.localizedDescription
            if desc == "LOGIN_BAD_CREDENTIALS" {
                return "Invalid email or password."
            } else if desc == "REGISTER_USER_ALREADY_EXISTS" {
                return "User with this email already exists."
            } else if apiError.statusCode == 422 {
                return "Validation error, please ensure fields are valid."
            }
            log.error("Error: \(apiError.errorDescription ?? "")")
            return "An unexpected error occurred."
        }
        // No errors, return a space to avoid spacing issues
        return " "
    }

    init(showLogin: Binding<Bool>) {
        _showLogin = showLogin
        let key = StorageKeys.firstLaunch.rawValue
        let first = UserDefaults.standard.object(forKey: key) as? Bool ?? true
        _isRegistering = State(initialValue: first)
        if first {
            UserDefaults.standard.set(false, forKey: key)
        }
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
                TextField("First Name", text: $firstName)
                    .textContentType(.givenName)
                    .roundedInput()
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .move(edge: .leading).combined(with: .opacity)))
                    .animation(.spring(.snappy), value: isRegistering)
                    .overlay(alignment: .trailing) {
                        validationIcon(isNameValid(firstName))
                    }

                TextField("Last Name", text: $lastName)
                    .textContentType(.familyName)
                    .roundedInput()
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .move(edge: .leading).combined(with: .opacity)))
                    .animation(.spring(.snappy), value: isRegistering)
                    .overlay(alignment: .trailing) {
                        validationIcon(isNameValid(lastName))
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
                    .textContentType(.password)
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
                        do {
                            if isRegistering {
                                try await userStore.register(firstName: firstName,
                                                             lastName: lastName,
                                                             email: formEmail,
                                                             password: password)
                            } else {
                                try await userStore.login(email: formEmail, password: password)
                            }

                            successTrigger += 1
                            try? await Task.sleep(nanoseconds: 400_000_000)
                            showLogin = false

                            // Reset state after success and delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                userStore.resetStateAndError()
                            }
                        } catch {
                            // Error is handled by UserStore and displayed via errorText
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                withAnimation {
                                    userStore.resetStateAndError()
                                }
                            }
                        }
                    }
                } else {
                    log.warning("Attempted to submit Login/Register with invalid form data")
                }
            } label: {
                ZStack {
                    Text(isRegistering ? "Sign Up" : "Log In")
                        .opacity(userStore.state != .idle ? 0.0 : 1.0)

                    if case .loading = userStore.state {
                        ProgressView()
                            .transition(.opacity)
                    }

                    if case .success = userStore.state {
                        Image("lucide.circle.check.fill")
                            .scaleEffect(1.3)
                            .transition(.scale.combined(with: .opacity))
                    }

                    if case .error = userStore.state {
                        Image("lucide.circle.x.fill")
                            .scaleEffect(1.3)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity)
                .animation(.bouncy, value: userStore.state)
                .padding(.vertical, 12)
                .tint(.white)
                .sensoryFeedback(.success, trigger: successTrigger)
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.accent),
            )
            .disabled(userStore.state == .loading)

            Button {
                withAnimation(.spring(.snappy)) {
                    isRegistering.toggle()
                    showValidationResults = false
                    userStore.resetStateAndError()
                }
            } label: {
                Text(isRegistering ? "Already have an account? Log in." : "Don't have an account? Sign up.")
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

    private func isEmailValid(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,64}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func isNameValid(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        // Minimum length after trimming
        guard trimmed.count >= 2 else { return false }

        let allowed = CharacterSet.letters
            .union(.whitespaces)
            .union(.urlQueryAllowed)
            .union(CharacterSet(charactersIn: "-'"))
        return trimmed.unicodeScalars.allSatisfy { allowed.contains($0) }
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
    func roundedInput() -> some View {
        modifier(RoundedTextFieldStyle())
    }
}

#Preview {
    LoginOrRegisterView(showLogin: .constant(false))
        .environment(\.font, .app())
}
