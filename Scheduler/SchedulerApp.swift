//
//  SchedulerApp.swift
//  Scheduler
//
//  Created by ByteDance on 5/30/25.
//

import SwiftUI

@main
struct SchedulerApp: App {
    @StateObject var storage = TaskStorageManager()
    
    init() {
//        generateTestData()
//        storage.clearAllData()
    }
    
    var body: some Scene {
        WindowGroup {
            if storage.hasUserName() {
                MainTabView(username: storage.userName)
                    .environmentObject(storage)
                    .task {
                        storage.loadRemoteTasks()
                    }
            } else {
                NameInputView()
                    .environmentObject(storage)
                    .task {
                        storage.loadRemoteTasks()
                    }
            }
        }
    }
    
    private func generateTestData() {
        // 1. 清空现有数据
        storage.clearAllData()
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 2. 生成测试日期（过去N天）
        let testDates = (0 ..< 16).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: -dayOffset, to: today)
        }.filter { $0 != nil }.map { $0! }
        
        // 3. 为每天生成任务数据
        for date in testDates {
            // 获取当天任务（userName为空）
            let tasks = WeeklyTasksConfig.tasks(for: date, userName: nil)
            
            // 生成完整任务状态（每个任务都有true/false）
            let taskStatus: [String: Bool] = Dictionary(
                uniqueKeysWithValues: tasks.map { taskName in
                    (taskName, Bool.random())
                }
            )
            
            // 保存记录
            storage.saveRecord(date: date, tasks: taskStatus)
        }
        print("共已生成测试数据：\(testDates.count)天，所有任务均标注是否完成")
    }
}
