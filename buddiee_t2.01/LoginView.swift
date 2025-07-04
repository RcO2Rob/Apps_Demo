//
//  LoginView.swift
//  buddiee_t2.01
//
//  Created by 欧柔成 on 03/07/2025.
//


import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showSignUp: Bool = false
    
    var onLogin: ((String, String) -> Void)?
    var onSkip: (() -> Void)?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Welcome Back")
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
                        .textContentType(.password)
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
                
                Button{
                    login()
                } label: {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Log In")
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
                
                HStack{
                    Button(action: {
                        showSignUp = true
                        
                    }) {
                        Text("Sign Up")
                            .font(.subheadline)
                            .underline()
                    }
                    
                    
                    
                    //添加一根竖线
                    Divider()
                      .frame(width: 1, height: 15)
                      .background(Color.gray)
                    
                    Button(action: {
                        onSkip?()
                    }) {
                        Text("Skip")
                            .font(.subheadline)
                            .underline()
                    }
                }
                .padding(.bottom, 20)
                
                NavigationLink(
                    destination: SignUpView(),
                    isActive: $showSignUp
                ) {
                    EmptyView()
                }
                .hidden()
                
            }
            .navigationBarHidden(true)
        }
    }
    
    
    private func login(){
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // 调用 SupabaseManager 里的异步登录
                try await SupabaseManager.shared.signIn(email: email, password: password)
            } catch {
                // 登录失败，显示错误
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private func SignUp() {
        //
    }
    
}


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(onLogin: { email, password in
            print("Logging in with \(email), \(password)")
        }, onSkip: {
            print("Skipped login")
        })
    }
}
