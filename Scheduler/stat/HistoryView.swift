import Charts
import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var storage: TaskStorageManager
    
    // 按周分组的历史数据
    private var weeklyData: [WeeklyData] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: storage.allRecords) { record in
            calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: record.date)
        }
        
        return grouped.compactMap { components, records -> WeeklyData? in
            guard let startDate = calendar.date(from: components),
                  !records.isEmpty else { return nil }
            
            // 计算该周所有日期（从周一开始，共7天）
            let weekDates = (0..<7).compactMap { dayOffset in
                calendar.date(byAdding: .day, value: dayOffset, to: startDate)
            }
            
            // 计算平均分（包含0分日期）
            let allScores = weekDates.map { date in
                storage.getRecord(for: date)?.score ?? 0
            }
            let totalScore = allScores.reduce(0, +)
            let averageScore = Int((Double(totalScore) / Double(weekDates.count)).rounded())
            
            // 统计未完成任务次数
            let top3Tasks = calculateTopUncompletedTasks(for: weekDates)
            
            return WeeklyData(
                weekStart: startDate,
                averageScore: averageScore,
                dailyScores: records.sorted { $0.date < $1.date },
                top3UncompletedTasks: top3Tasks
            )
        }.sorted { $0.weekStart > $1.weekStart }
    }
        
    // 统计指定周的未完成任务次数
    private func calculateTopUncompletedTasks(for weekDates: [Date]) -> [(task: String, count: Int)] {
        // 获取该周所有任务配置
        let allTasks = unique(weekDates.flatMap { date in
            // 从storage获取当天记录的任务名称
            storage.getRecord(for: date)?.tasks.keys.map { $0 } ?? []
        })

        // 统计每个任务的未完成次数
        var taskCounts: [String: Int] = [:]
        for task in allTasks {
            let uncompletedDays = weekDates.filter { date in
                guard let record = storage.getRecord(for: date) else { return true } // 无记录视为未完成
                return !record.tasks[task, default: false]
            }
            taskCounts[task] = uncompletedDays.count
        }
        
        // 按次数降序排序，取前3名
        return taskCounts.sorted(by: { $0.value > $1.value })
            .prefix(3)
            .map { ($0.key, $0.value) }
    }
    
    // 辅助函数：数组去重
    private func unique<S: Sequence, T: Hashable>(_ sequence: S) -> [T] where S.Iterator.Element == T {
        var seen = Set<T>()
        return sequence.filter { seen.insert($0).inserted }
    }
    
    var body: some View {
        List {
            // 图表展示
            Chart {
                ForEach(weeklyData.prefix(8)) { week in
                    BarMark(
                        x: .value("Week", week.weekLabel),
                        y: .value("Score", week.averageScore)
                    )
                    .annotation(position: .top) {
                        Text("\(week.averageScore)")
                            .font(.caption2)
                    }
                }
            }
            .frame(height: 200)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            
            // 详细数据列表
            ForEach(weeklyData) { week in
                Section(header: Text(week.weekLabel).font(.headline)) {
                    // 每日数据
                    ForEach(week.dailyScores, id: \.date) { record in
                        HStack {
                            Text(record.date.formatted(.dateTime.day().month()))
                            Spacer()
                            Text("\(record.score)分")
                                .foregroundColor(scoreColor(record.score))
                        }
                    }
                    
                    // 未完成任务统计
                    if !week.top3UncompletedTasks.isEmpty {
                        Section(header: Text("未完成任务 TOP3").font(.headline).foregroundColor(.red)) {
                            ForEach(week.top3UncompletedTasks, id: \.task) { task in
                                HStack {
                                    Text(task.task)
                                    Spacer()
                                    Text("\(task.count)天未完成")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("历史记录")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80 ... 100: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }
}

// 数据结构
struct WeeklyData: Identifiable {
    let weekStart: Date
    let averageScore: Int
    let dailyScores: [DailyTaskRecord]
    let top3UncompletedTasks: [(task: String, count: Int)]
    
    var id: Date { weekStart }
    
    var weekLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MMMdd周"
        return formatter.string(from: weekStart)
    }
}
