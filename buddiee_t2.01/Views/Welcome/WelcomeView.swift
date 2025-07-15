

import SwiftUI

struct WelcomeView: View {
    @State private var showAppName = false
    @State private var showNextButton = false
    @State private var animationCompleted = false
    
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            // 蓝色背景
            Color.blue
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // 应用名称动画
                if showAppName {
                    Text("Buddiee")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .scaleEffect(animationCompleted ? 1.0 : 0.5)
                        .opacity(animationCompleted ? 1.0 : 0.0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0), value: animationCompleted)
                }
                
                Spacer()
                
                // 右下角的下一步按钮
                HStack {
                    Spacer()
                    
                    if showNextButton {
                        Button(action: {
                            onContinue()
                        }) {
                            HStack(spacing: 8) {
                                Text("Next")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title2)
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(25)
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                }
                .padding(.trailing, 30)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // 延迟 0.5 秒后显示应用名称
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                showAppName = true
            }
            
            // 再延迟 0.3 秒开始名称的弹跳动画
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animationCompleted = true
                
                // 名称动画完成后显示下一步按钮
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        showNextButton = true
                    }
                }
            }
        }
    }
}

#Preview {
    WelcomeView {
        print("继续到下一步")
    }
}
