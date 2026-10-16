import SwiftUI

struct MainTabView: View {
    var body: some View {
        NavigationStack {
            TabView {
                // Utforsk-fane (Geoapify API)
                ExploreView(vm: .init(client: .init(apiKey: "8cf03762f7b740bea9f1802f59e297ea")))
                    .tabItem {
                        Label("Utforsk", systemImage: "map")
                    }

                // Mine steder-fane
                MineStederView()
                    .tabItem {
                        Label("Mine steder", systemImage: "star")
                    }
            }
            .tint(Color(hex: "#FF9B52")) // Beacon Orange
        }
    }
}

