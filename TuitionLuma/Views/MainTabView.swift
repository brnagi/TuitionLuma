import SwiftUI

struct MainTabView: View {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(red: 0.045, green: 0.065, blue: 0.12, alpha: 0.96)
        appearance.shadowColor = UIColor.white.withAlphaComponent(0.14)

        let normalColor = UIColor.white.withAlphaComponent(0.72)
        let selectedColor = UIColor(LumaTheme.coral)
        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]

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
