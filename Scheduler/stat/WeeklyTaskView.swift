//
//  WeeklyTaskView.swift
//  Scheduler
//
//  Created by ByteDance on 6/3/25.
//
import SwiftUI

struct WeeklyTaskView: View {
    @EnvironmentObject var storage: TaskStorageManager
    @State private var showHistory = false
    @State private var thisWeek: [Date] = []
    
    private var weeklyAverageScore: String {
        let scores = thisWeek.map { date in
            storage.getRecord(for: date)?.score ?? 0
        }
        guard !scores.isEmpty else { return "0.0" }
        
        let average = Double(scores.reduce(0, +)) / Double(thisWeek.count)
        return String(format: "%.1f", average)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 标题行（带历史跳转）
                HStack {
                    Text("本周任务完成平均分：\(weeklyAverageScore)")
                        .font(.title2.bold())
                    
                    Spacer()
                    
                    Button("历史完成情况") {
                        showHistory = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding()
                }
                .padding(.horizontal)
                                
                // 按天分组显示
                ForEach(thisWeek, id: \.self) { date in
                    DayTaskSection(date: date)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationDestination(isPresented: $showHistory) {
            HistoryView().environmentObject(storage)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            refreshWeeklyData()
        }
        .onAppear {
            refreshWeeklyData()
        }
    }
    
    private func refreshWeeklyData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let cutoffDate = calendar.date(from: DateComponents(year: 2025, month: 6, day: 29))!
            
        guard let lastSunday = calendar.date(byAdding: .day,
                                             value: -calendar.component(.weekday, from: today) + 1,
                                             to: today)
        else {
            thisWeek = []
            return
        }
            
        let dates = (0 ..< 7).compactMap { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: lastSunday)!
            return date <= today && date >= cutoffDate ? date : nil
        }
            
        DispatchQueue.main.async {
            thisWeek = dates.reversed()
        }
    }
}

// 每天的任务区块
struct DayTaskSection: View {
    let date: Date
    @EnvironmentObject var storage: TaskStorageManager
    
    private var weekdayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEEE" // 星期几全称
        return formatter.string(from: date)
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 日期标题
            HStack {
                Text(weekdayName)
                    .font(.headline)
                
                Text(date.formatted(.dateTime.day().month()))
                    .foregroundColor(.gray)
                
                if isToday {
                    Text("今天")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .background(Capsule().fill(Color.blue))
                }
            }
            .padding(.horizontal)
            
            // 任务列表
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 10) {
                let name = storage.userName
                ForEach(WeeklyTasksConfig.tasks(for: date, userName: TaskStorageManager.shared.userName),
                        id: \.self)
                { task in
                    TaskStatusBadge(task: task, date: date)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

// 任务状态徽章
struct TaskStatusBadge: View {
    let task: String
    let date: Date
    @EnvironmentObject var storage: TaskStorageManager
    
    private var isCompleted: Bool {
        storage.getRecord(for: date)?.tasks[task] ?? false
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundColor(isCompleted ? .green : .red)
            
            Text(task)
                .font(.subheadline)
                .lineLimit(1)
                .foregroundColor(isCompleted ? .primary : .secondary)
        }
        .padding(8)
        .background(
            Capsule()
                .strokeBorder(isCompleted ? Color.green.opacity(0.5) : Color.gray.opacity(0.3))
        )
    }
}

// 刷新本周数据，从上周日，最多到本周六为一整周

private var thisWeek1: [Date] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    // 调试点1：设置起始日期（2025年6月28日）
    let cutoffDate = calendar.date(from: DateComponents(year: 2025, month: 6, day: 29))!
    // 找到上一个周日作为起始
    guard let lastSunday = calendar.date(byAdding: .day,
                                         value: -calendar.component(.weekday, from: today) + 1,
                                         to: today)
    else {
        return []
    }

    // 生成从周日开始的日期序列（最多7天）
    return (0 ..< 7).compactMap { dayOffset in
        let date = calendar.date(byAdding: .day, value: dayOffset, to: lastSunday)!
        return date <= today && date >= cutoffDate ? date : nil
    }.reversed()
}
