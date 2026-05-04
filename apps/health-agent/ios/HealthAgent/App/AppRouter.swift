import SwiftUI

struct AppRouter: View {
    var body: some View {
        TabView {
            NavigationView {
                TodayView()
            }
            .tabItem {
                Label("今日", systemImage: "house.fill")
            }

            NavigationView {
                ExploreView()
            }
            .tabItem {
                Label("探索", systemImage: "safari.fill")
            }

            NavigationView {
                HeartView()
            }
            .tabItem {
                Label("心脏", systemImage: "heart.text.square.fill")
            }

            NavigationView {
                ReportsView()
            }
            .tabItem {
                Label("报告", systemImage: "doc.text.fill")
            }

            NavigationView {
                MeView()
            }
            .tabItem {
                Label("我的", systemImage: "person.fill")
            }
        }
        .tint(HAColor.primaryGreen)
    }
}
