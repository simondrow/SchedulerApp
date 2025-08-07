//
//  DailyTaskRecord.swift
//  Scheduler
//
//  Created by ByteDance on 6/3/25.
//

import Foundation

// 可编码的每日任务记录
struct DailyTaskRecord: Codable, Identifiable {
    let id = UUID()
    let date: Date
    var tasks: [String: Bool] // 任务名称 -> 是否完成

    // 计算属性
    var completedCount: Int {
        tasks.values.filter { $0 }.count
    }
    
    var totalCount: Int {
        tasks.count
    }
    
    var score: Int {
        totalCount > 0 ? Int(Double(completedCount) / Double(totalCount) * 100) : 0
    }
    
    // 格式化日期
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
