import SwiftUI

struct MainTabView: View {
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
