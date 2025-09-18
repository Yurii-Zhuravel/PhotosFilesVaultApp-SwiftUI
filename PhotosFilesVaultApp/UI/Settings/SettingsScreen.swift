import SwiftUI

struct SettingsScreen: View {
    let services: ServicesProtocol
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color.contentBack
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    // TODO: Settings content
                    
                    Text("Settings page")
                }.ignoresSafeArea()
                
            }.navigationTitle("settings")
                .navigationBarTitleDisplayMode(.inline)
//                .navigationDestination(for: HomeTabsNavigationRoutes.self) { route in
//                    switch route {
//                    case .photoAlbumList:
//                        PhotoAlbumListScreen(services: services)
//                    case .settings:
//                        SettingsScreen(services: services)
//                    }
//                }
        }
    }
}

#Preview {
    let services = MockedServices.standard()
    
    SettingsScreen(
        services: services
    )
}
