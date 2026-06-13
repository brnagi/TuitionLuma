import SwiftUI

struct MainTabView: View {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor.white.withAlphaComponent(0.92)
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.10)

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().isTranslucent = true
    }

    var body: some View {
        TabView {
            ExploreView()
                .tabItem {
                    Label("Explore", systemImage: "magnifyingglass")
                }

            CompareView()
                .tabItem {
                    Label("Compare", systemImage: "rectangle.split.3x1")
                }

            CalculatorView()
                .tabItem {
                    Label("Calculator", systemImage: "function")
                }

            SavedSchoolsView()
                .tabItem {
                    Label("Saved", systemImage: "bookmark")
                }
        }
        .tint(LumaTheme.coral)
    }
}
