//
//  NameInputView.swift
//  Scheduler
//
//  Created by ByteDance on 6/3/25.
//

import SwiftUI

struct NameInputView: View {
    @EnvironmentObject var storage: TaskStorageManager

    @State private var name: String = ""
    @State private var isNameSubmitted = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // 标题
                Text("欢迎使用任务管理器")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                
                // 输入框容器
                VStack(spacing: 10) {
                    Text("请输入你的名字")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    TextField("", text: $name)
                        .focused($isInputFocused)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .padding(15)
                        .frame(width: 280)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isInputFocused ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        .onAppear {
                            // 自动聚焦输入框
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isInputFocused = true
                            }
                        }
                }
                
                // 确认按钮
                Button("开始使用") {
                    storage.setUserName(name)
                    isNameSubmitted = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(name.isEmpty)
                .opacity(name.isEmpty ? 0.6 : 1)
                .animation(.easeInOut, value: name.isEmpty)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationDestination(isPresented: $isNameSubmitted) {
                MainTabView(username: name)
            }
        }
    }
    
    private func submit() {
        isNameSubmitted = true
    }
}

// 预览
struct NameInputView_Previews: PreviewProvider {
    static var previews: some View {
        NameInputView()
    }
}
