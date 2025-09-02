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
        loadConfig()
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
    
    // 定义服务端响应模型
    private struct RPCResponse: Decodable {
        let rpcResp: RPCResult
    }
    
    private struct RPCResult: Decodable {
        let id: Int
        let title: String
        let content: String
    }
    
    // 定义一个与服务端返回的 JSON 结构完全匹配的 Decodable 结构体
    struct ServerResponse: Decodable {
        let scheduler: [[String]]
    }

    private func loadConfig() {
        Task {
            do {
                // fetchServerData 现在会直接返回 [[String]] 数组
                let scheduleData = try await fetchServerData()
                print("成功获取服务端数据: \(scheduleData)")
                // 可在此处处理返回结果，如更新UI或存储数据
            } catch {
                print("获取服务端数据失败: \(error)")
            }
        }
    }

    // 异步获取服务端数据，并使其返回 [[String]]
    private func fetchServerData() async throws -> [[String]] {
        guard let url = URL(string: "http://127.0.0.1:6789/get-schedule?name=John") else {
            throw URLError(.badURL)
        }
        
        print("正在请求 URL: \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            // 在出错时打印服务器返回的具体信息，方便调试
            let serverError = String(data: data, encoding: .utf8) ?? "无法解析错误信息"
            print("服务器返回错误。状态码: \((response as? HTTPURLResponse)?.statusCode ?? -1)，内容: \(serverError)")
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        // 直接将返回的 JSON 解码为我们新定义的 ServerResponse 类型
        let serverResponse = try decoder.decode(ServerResponse.self, from: data)
        
        // 返回解码后的 schedule 数组
        return serverResponse.scheduler
    }
}
