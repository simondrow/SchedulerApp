//
//  DailyTaskView.swift
//  Scheduler
//
//  Created by ByteDance on 6/3/25.
//

import SwiftUI

struct DailyTaskView: View {
    let username: String
    @EnvironmentObject var storage: TaskStorageManager
    @State private var lastRefreshDate: Date?

    // 今日任务名列表
    @State private var items: [String] = []
    // 今天的【任务名 : 完成情况】卡片状态map
    @State private var cardStates: [String: Bool] = [:]
    @State private var showAlert = false

    // 年月日 String类似的今天日期
    private let currentWeekday: String = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }()

    
    var scoreInfo: (total: Int, completed: Int, score: Int) {
        let total = cardStates.count
        let completed = cardStates.values.filter { $0 }.count
        let score = total > 0 ? Int(Double(completed) / Double(total) * 100) : 0
        return (total, completed, score)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text("\(username)的\(currentWeekday)任务")
                .font(.system(size: 24, weight: .bold))
                .padding(.top, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(items, id: \.self) { item in
                        CardView(
                            title: item,
                            isCompleted: Binding(
                                get: { cardStates[item, default: false] },
                                set: { cardStates[item] = $0 }
                            )
                        )
                        .frame(width: 120, height: 160)
                    }
                }
                .padding(20)
            }
            .frame(height: 180)
            
            VStack(spacing: 16) {
                HStack {
                    Text("今日进度:")
                        .font(.headline)
                    Spacer()
                    Text("\(scoreInfo.completed)/\(scoreInfo.total) 项")
                        .font(.system(size: 16, weight: .bold))
                }
                
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .frame(width: UIScreen.main.bounds.width - 40,
                               height: 10)
                        .foregroundColor(.gray.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 5)
                        .frame(
                            width: CGFloat(scoreInfo.completed) / CGFloat(scoreInfo.total) * (UIScreen.main.bounds.width - 40),
                            height: 10
                        )
                        .foregroundColor(scoreInfo.completed == scoreInfo.total ? .green : .blue)
                }
                
                Text("\(scoreInfo.score)分")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(scoreInfo.score == 100 ? .green : .primary)
                
                Button(action: {
                    showAlert = true
                    saveTodayTasks()
                }) {
                    Text("提交打卡")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(scoreInfo.score == 100 ? Color.green : Color.blue)
                        .cornerRadius(10)
                }
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
            .padding(.horizontal, 10)
        }
        .background(Color(.secondarySystemBackground))
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(scoreInfo.score == 100 ? "🎉 全部完成！" : "任务进度"),
                message: Text(
                    scoreInfo.score == 100 ?
                        "太棒了！所有任务都完成了！" :
                        "已完成 \(scoreInfo.completed) 项任务（得分：\(scoreInfo.score)）"
                ),
                dismissButton: .default(Text("好的"))
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            refreshData()
        }
        .onAppear {
            refreshData()
        }
    }
    
    private func refreshData() {
        let today = Calendar.current.startOfDay(for: Date())
        // 如果日期未变化且已有数据，则不更新
        if let lastDate = lastRefreshDate,
           Calendar.current.isDate(today, inSameDayAs: lastDate),
           !cardStates.isEmpty {
            return
        }
        
        // 更新任务列表
        items = WeeklyTasksConfig.tasks(for: today, userName: TaskStorageManager.shared.userName)
        
        // 重置任务状态
        var states = Dictionary(uniqueKeysWithValues: items.map { ($0, false) })
        
        // 从存储加载数据
        if let record = TaskStorageManager.shared.getRecord(for: today) {
            for (task, completed) in record.tasks {
                if states.keys.contains(task) {
                    states[task] = completed
                }
            }
        }
        
        // 更新状态
        DispatchQueue.main.async {
            cardStates = states
            lastRefreshDate = today 
        }
    }

    // 保存方法
    private func saveTodayTasks() {
        let today = Calendar.current.startOfDay(for: Date())
        storage.saveRecord(date: today, tasks: cardStates)
        showAlert = true
    }
}
