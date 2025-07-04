//
//  SignUpView.swift
//  buddiee_t2.01
//
//  Created by 欧柔成 on 04/07/2025.
//


import SwiftUI

struct SignUpView: View {
    @EnvironmentObject private var supabase: SupabaseManager

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Email")
                        .font(.headline)
                    TextField("you@example.com", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 8).strokeBorder())

                    Text("Password")
                        .font(.headline)
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 8).strokeBorder())
                }
                .padding(.horizontal)

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button(action: register) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Sign Up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                .padding(.horizontal)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                // 添加一个“返回”按钮
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Cancel") {
//                        // 假设你在 login 页面里是 push，这里用 pop
//                        // 如果是 sheet，则调用 dismiss()
//                        UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true)
//                    }
//                }
//            }
        }
    }

    private func register() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await SupabaseManager.shared.signUp(email: email, password: password)
                // 成功后 supabase.currentUser 已被设置，根视图会自动切换
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .environmentObject(SupabaseManager.shared)
    }
}
