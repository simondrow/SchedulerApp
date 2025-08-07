//
//  TaskStorageManager.swift
//  Scheduler
//
//  Created by ByteDance on 6/3/25.
//

import SwiftUI

final class TaskStorageManager: ObservableObject {
    static let shared = TaskStorageManager()

    // 存储用户名
    @AppStorage("userName") var userName: String = ""
    // 发布数据变化，结构化数据
    @Published private(set) var allRecords: [DailyTaskRecord] = []
    // 使用 @AppStorage 自动同步 UserDefaults，序列化数据
    @AppStorage("savedTaskRecords") private var storedData: Data = .init()
    
    init() {
        loadRecords()
    }
    
    // 检查用户名是否存在
    func hasUserName() -> Bool {
        print(userName)
        return !userName.isEmpty
    }
    
    // 更新用户名
    func setUserName(_ name: String) {
        userName = name
    }
    
    // 获取用户名
    func getUserName() -> String {
        userName
    }
    
    // 保存记录（自动去重）
    func saveRecord(date: Date, tasks: [String: Bool]) {
        print("saveRecord tasks: \(tasks)")
        let newRecord = DailyTaskRecord(date: date, tasks: tasks)
        
        // 移除同一天的旧记录
        allRecords.removeAll {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
        
        allRecords.append(newRecord)
        saveAllRecords()
    }
    
    // 私有方法：保存到持久化存储
    private func saveAllRecords() {
        if let encoded = try? JSONEncoder().encode(allRecords) {
            storedData = encoded
        }
    }
        
    // 获取指定日期的记录。仅当日数据从Config中取任务，历史数据都从存储中取任务列表及完成情况
    func getRecord(for date: Date) -> DailyTaskRecord? {
        let targetDate = Calendar.current.startOfDay(for: date)
        return allRecords.first {
            Calendar.current.isDate($0.date, inSameDayAs: targetDate)
        }
    }
    
    // 私有方法：从持久化存储加载
    private func loadRecords() {
        if let decoded = try? JSONDecoder().decode([DailyTaskRecord].self, from: storedData) {
            allRecords = decoded.sorted { $0.date > $1.date } // 按日期降序
        }
    }
    
    // 清空所有存储数据
    func clearAllData() {
//        userName = ""
        allRecords.removeAll()
        storedData = Data()
        saveAllRecords()
    }
}
