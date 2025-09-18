import SwiftUI

struct HomeTabsScreen: View {
    let services: ServicesProtocol
    
    @State private var selectedTab: TabItem = .photos
    
    var body: some View {
        ZStack {
            Color.contentBack
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                TabView(selection: $selectedTab, content:  {
                    switch selectedTab {
                    case .photos:
                        PhotoAlbumListScreen(
                            services: services
                        ).tag(selectedTab)
                        
                    case .settings:
                        SettingsScreen(
                            services: services
                        ).tag(selectedTab)
                    }
                })
                TabBarView(selectedTab: $selectedTab)
            }
        }
    }
}

#Preview("Light mode") {
    let services = MockedServices.standard()
    
    HomeTabsScreen(
        services: services
    ).environment(\.colorScheme, .light)
}

#Preview("Dark mode") {
    let services = MockedServices.standard()
    
    HomeTabsScreen(
        services: services
    ).environment(\.colorScheme, .dark)
}
