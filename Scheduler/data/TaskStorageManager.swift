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
    // 远程用户 -> (周几 -> 任务数组)
    @Published private(set) var remoteUserTasks: [String: [Int: [String]]] = [:]
    // 使用 @AppStorage 自动同步 UserDefaults，序列化数据
    @AppStorage("savedTaskRecords") private var storedData: Data = .init()
    // 本地缓存的远程任务数据
    @AppStorage("cachedRemoteTasks") private var cachedRemoteTasksData: Data = .init()
    
    init() {
        loadRecords()
        loadCachedRemoteTasks()
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
        cachedRemoteTasksData = Data()
        remoteUserTasks.removeAll()
        saveAllRecords()
    }
    
    // 私有方法：保存远程任务到本地缓存
    private func saveCachedRemoteTasks() {
        if let encoded = try? JSONEncoder().encode(remoteUserTasks) {
            cachedRemoteTasksData = encoded
        }
    }
    
    // 私有方法：从本地缓存加载远程任务
    private func loadCachedRemoteTasks() {
        if let decoded = try? JSONDecoder().decode([String: [Int: [String]]].self, from: cachedRemoteTasksData) {
            remoteUserTasks = decoded
        }
    }

    // MARK: - 远程任务
    private struct RemoteUserWrapper: Decodable {
        let tasksByWeekday: [String: [String]]
        enum CodingKeys: String, CodingKey { case tasksByWeekday = "任务" }
    }

    // 将本地输入的用户名映射为服务端用户键
    private func serverUserName(for name: String?) -> String? {
        guard let n = name, !n.isEmpty else { return nil }
        return n.contains("莞") ? "Waner" : "John"
    }

    // 从服务器加载所有用户任务
    func loadRemoteTasks(completion: ((Bool) -> Void)? = nil) {
        guard let url = URL(string: API.usersEndpoint) else {
            completion?(false)
            return
        }
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 15)
        print("[Remote] 请求 URL: \(request.url?.absoluteString ?? "-")")
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { completion?(false); return }
            if let error = error {
                print("加载远程任务失败: \(error)")
                DispatchQueue.main.async { completion?(false) }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { completion?(false) }
                return
            }
            do {
                let decoded = try JSONDecoder().decode([String: RemoteUserWrapper].self, from: data)
                let keys = Array(decoded.keys)
                print("[Remote] 返回用户键: \(keys)")
                var result: [String: [Int: [String]]] = [:]
                for (userName, wrapper) in decoded {
                    var weekMap: [Int: [String]] = [:]
                    for (dayString, tasks) in wrapper.tasksByWeekday {
                        if let dayInt = Int(dayString) {
                            weekMap[dayInt] = tasks
                        }
                    }
                    result[userName] = weekMap
                }
                DispatchQueue.main.async {
                    self.remoteUserTasks = result
                    self.saveCachedRemoteTasks() // 保存到本地缓存
                    let mapped = self.serverUserName(for: self.userName)
                    let todayCount = self.tasks(for: Date(), userName: mapped).count
                    print("[Remote] 设置缓存完成，本地名=\(self.userName)，映射名=\(mapped ?? "nil")，今日任务数=\(todayCount)")
                    completion?(true)
                }
            } catch {
                print("远程任务解析失败: \(error)")
                DispatchQueue.main.async { completion?(false) }
            }
        }.resume()
    }

    // 基于 async/await 的下拉刷新便捷方法
    @MainActor
    func loadRemoteTasksAsync() async -> Bool {
        guard let url = URL(string: API.usersEndpoint) else {
            return false
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            print("[Remote] 请求 URL: \(url.absoluteString)")
            let decoded = try JSONDecoder().decode([String: RemoteUserWrapper].self, from: data)
            let keys = Array(decoded.keys)
            print("[Remote] 返回用户键: \(keys)")
            var result: [String: [Int: [String]]] = [:]
            for (userName, wrapper) in decoded {
                var weekMap: [Int: [String]] = [:]
                for (dayString, tasks) in wrapper.tasksByWeekday {
                    if let dayInt = Int(dayString) {
                        weekMap[dayInt] = tasks
                    }
                }
                result[userName] = weekMap
            }
            self.remoteUserTasks = result
            self.saveCachedRemoteTasks() // 保存到本地缓存
            let mapped = serverUserName(for: userName)
            let todayCount = tasks(for: Date(), userName: mapped).count
            print("[Remote] 拉取成功，用户数=\(result.count)，本地名=\(userName)，映射名=\(mapped ?? "nil")，今日任务数=\(todayCount)")
            return true
        } catch {
            print("[Remote] 拉取失败: \(error)")
            return false
        }
    }

    // 获取指定日期任务（优先使用远程数据，失败时回退本地默认配置）
    func tasks(for date: Date, userName name: String?) -> [String] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date) // 1-7
        let mappedName = serverUserName(for: name)
        if let serverName = mappedName, let userTask = remoteUserTasks[serverName] {
            return userTask[weekday] ?? []
        }
        // 回退逻辑
        return WeeklyTasksConfig.tasks(for: date, userName: name)
    }
}
