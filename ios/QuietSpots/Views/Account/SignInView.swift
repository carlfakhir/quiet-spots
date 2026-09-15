/*
Abstract:
Form for signing in or creating an account.
*/

import SwiftUI

struct SignInView: View {
    @Environment(AuthStore.self) var auth
    @State private var mode = Mode.signIn
    @State private var username = ""
    @State private var password = ""
    @State private var isWorking = false
    @State private var error: String?

    enum Mode: Hashable { case signIn, createAccount }

    private let isUITesting = ProcessInfo.processInfo.arguments.contains("-uiTesting")

    var body: some View {
        Form {
            Section {
                Picker("Mode", selection: $mode) {
                    Text("Sign in").tag(Mode.signIn)
                    Text("Create account").tag(Mode.createAccount)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
            } footer: {
                Text("You need an account to post noise reports. Anyone can browse spots.")
            }

            Section {
                TextField("Username", text: $username)
                    .textContentType(isUITesting ? nil : .username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("Password", text: $password)
                    // UI tests skip content types: iOS's strong-password suggestion swallows typed keys.
                    .textContentType(isUITesting ? nil : (mode == .signIn ? .password : .newPassword))
            } footer: {
                if mode == .createAccount {
                    Text("3–24 letters, numbers, or underscores. Password at least 8 characters.")
                }
            }

            if let error {
                Section { Text(error).foregroundStyle(.red) }
            }

            Section {
                Button {
                    Task { await submit() }
                } label: {
                    HStack {
                        Text(mode == .signIn ? "Sign in" : "Create account")
                        if isWorking { Spacer(); ProgressView() }
                    }
                }
                .disabled(username.isEmpty || password.isEmpty || isWorking)
                .accessibilityIdentifier("auth.submit")
            }
        }
        .onChange(of: mode) { error = nil }
    }

    private func submit() async {
        isWorking = true
        defer { isWorking = false }
        do {
            switch mode {
            case .signIn: try await auth.signIn(username: username, password: password)
            case .createAccount: try await auth.createAccount(username: username, password: password)
            }
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}

#Preview {
    SignInView()
        .environment(AuthStore())
}
