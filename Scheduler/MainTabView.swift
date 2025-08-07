//
//  MainTabView.swift
//  Scheduler
//
//  Created by ByteDance on 6/3/25.
//

import SwiftUI

struct MainTabView: View {
    let username: String
    @EnvironmentObject var storage: TaskStorageManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. 顶部：每日任务视图
                    DailyTaskView(username: username)
                        .environmentObject(storage)
                        .padding(.top)

                    Divider().padding(.horizontal)

                    // 2. 底部：每周任务视图
                    WeeklyTaskView()
                        .environmentObject(storage)
                        .padding(.bottom)
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}
