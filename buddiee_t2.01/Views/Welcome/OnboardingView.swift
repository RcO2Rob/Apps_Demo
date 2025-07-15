//
//  OnboardingView.swift
//  buddiee_t2.01
//
//  Created by Assistant on 10/07/2025.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var isAnimating = false
    
    let onComplete: () -> Void
    
    private let pages = [
        OnboardingPage(
            title: "Safe & Secure",
            subtitle: "Third-Party Authentication",
            description: "We use industry-leading third-party authentication systems to ensure your account security. Your privacy and data safety are our top priority.",
            iconName: "shield.checkered",
            iconColor: .green
        ),
        OnboardingPage(
            title: "Smart Recommendations",
            subtitle: "Better Experience with Complete Profile",
            description: "Complete your profile to receive personalized content recommendations that match your interests, making your social experience more tailored.",
            iconName: "person.crop.circle.fill.badge.checkmark",
            iconColor: .blue
        ),
        OnboardingPage(
            title: "Start Exploring",
            subtitle: "Discover Amazing Connections",
            description: "Ready to connect with like-minded friends? Let's begin this exciting journey of social exploration together!",
            iconName: "globe.asia.australia.fill",
            iconColor: .purple
        )
    ]
    
    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // 页面指示器
                HStack(spacing: 12) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 10, height: 10)
                            .scaleEffect(index == currentPage ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 60)
                
                // 内容区域
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.5), value: currentPage)
                
                // 底部按钮区域
                VStack(spacing: 16) {
                    if currentPage < pages.count - 1 {
                        // 前两页显示"下一步"和"跳过"
                        HStack {
                            Button("Skip") {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    currentPage = pages.count - 1
                                }
                            }
                            .foregroundColor(.gray)
                            .font(.subheadline)
                            
                            Spacer()
                            
                            Button("Next") {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    currentPage += 1
                                }
                            }
                            .foregroundColor(.white)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(25)
                        }
                    } else {
                        // 最后一页显示"开始使用"
                        Button("Get Started") {
                            onComplete()
                        }
                        .foregroundColor(.white)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        .scaleEffect(isAnimating ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                        .onAppear {
                            isAnimating = true
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let description: String
    let iconName: String
    let iconColor: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 30) {
            // 图标
            Image(systemName: page.iconName)
                .font(.system(size: 80))
                .foregroundColor(page.iconColor)
                .scaleEffect(isVisible ? 1.0 : 0.5)
                .opacity(isVisible ? 1.0 : 0.0)
                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: isVisible)
            
            // 标题和副标题
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .offset(y: isVisible ? 0 : 20)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: isVisible)
                
                Text(page.subtitle)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .offset(y: isVisible ? 0 : 20)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: isVisible)
            }
            
            // 描述文本
            Text(page.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 20)
                .offset(y: isVisible ? 0 : 20)
                .opacity(isVisible ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.6).delay(0.6), value: isVisible)
        }
        .padding(.horizontal, 30)
        .onAppear {
            isVisible = true
        }
        .onDisappear {
            isVisible = false
        }
    }
}

#Preview {
    OnboardingView {
        print("Onboarding completed")
    }
}
