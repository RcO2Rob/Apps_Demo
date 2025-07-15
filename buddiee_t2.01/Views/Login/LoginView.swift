//
//  LoginView.swift
//  buddiee_t2.01
//
//  Created by 欧柔成 on 03/07/2025.
//

import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSignUp = false
    
    // 动画状态
    @State private var showUI = false
    
    var onLogin: ((String, String) -> Void)?
    var onSkip: (() -> Void)?
    
    var body: some View {
        NavigationView {
            ZStack {
                // 1. 渐变背景
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.3),
                        Color.purple.opacity(0.2),
                        .white
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Spacer()
                    
                    // 2. 美化标题
                    VStack(spacing: 10) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Welcome")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary.opacity(0.8))
                    }
                    .opacity(showUI ? 1 : 0)
                    .offset(y: showUI ? 0 : -30)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: showUI)
                    
                    VStack(spacing: 16) {
                        // 3. 重新设计输入框
                        CustomTextField(
                            iconName: "envelope.fill",
                            placeholder: "Email",
                            text: $email
                        )
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        
                        CustomTextField(
                            iconName: "lock.fill",
                            placeholder: "Password",
                            text: $password,
                            isSecure: true
                        )
                        .textContentType(.password)
                    }
                    .padding(.horizontal, 30)
                    .opacity(showUI ? 1 : 0)
                    .offset(y: showUI ? 0 : -30)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: showUI)
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    
                    // 4. 更新按钮样式
                    Button(action: login) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Log In")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: .blue.opacity(0.4), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 30)
                    .opacity(showUI ? 1 : 0)
                    .offset(y: showUI ? 0 : -30)
                    .animation(.easeOut(duration: 0.6).delay(0.6), value: showUI)
                    
                    Spacer()
                    
                    // 5. 调整底部按钮
                    HStack(spacing: 20) {
                        Button("Sign Up") {
                            showSignUp = true
                        }
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                        
                        Divider().frame(height: 15)
                        
                        Button("Skip") {
                            onSkip?()
                        }
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                    }
                    .padding(.bottom, 40)
                    .opacity(showUI ? 1 : 0)
                    .offset(y: showUI ? 0 : -30)
                    .animation(.easeOut(duration: 0.6).delay(0.8), value: showUI)
                    
                    NavigationLink(
                        destination: SignUpView(),
                        isActive: $showSignUp
                    ) {
                        EmptyView()
                    }
                    .hidden()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // 启动入场动画
                showUI = true
            }
        }
    }
    
    private func login() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await SupabaseManager.shared.signIn(email: email, password: password)
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

// 自定义输入框组件
struct CustomTextField: View {
    let iconName: String
    let placeholder: String
    @Binding var text: String
    var isSecure = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(onLogin: { _, _ in }, onSkip: {})
    }
}
