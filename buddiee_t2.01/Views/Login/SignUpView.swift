//
//  SignUpView.swift
//  buddiee_t2.01
//
//  Created by 欧柔成 on 04/07/2025.
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showProfileSetup = false
    @StateObject private var supabase = SupabaseManager.shared

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // 动画状态
    @State private var showUI = false

    var body: some View {
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
                    Image(systemName: "person.crop.circle.fill.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Create Account")
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
                    .textContentType(.newPassword)
                    
                    CustomTextField(
                        iconName: "lock.fill",
                        placeholder: "Confirm Password",
                        text: $confirmPassword,
                        isSecure: true
                    )
                    .textContentType(.newPassword)
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
                Button(action: register) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Sign Up")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(isLoading || email.isEmpty || password.isEmpty || password != confirmPassword)
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
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
        }
        .onAppear {
            showUI = true
        }
        .fullScreenCover(isPresented: $showProfileSetup) {
            ProfileSetupView() {
                // This closure will be called when profile setup is complete
                self.showProfileSetup = false
                // Here you might want to trigger the login completion logic
                // For example, by calling a method on a shared app state object
                // that switches the main view to ContentView.
            }
        }
    }

    private func register() {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await SupabaseManager.shared.signUp(email: email, password: password)
                // 注册成功后，显示资料设置页面
                await MainActor.run {
                    showProfileSetup = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SignUpView()
        }
    }
}
