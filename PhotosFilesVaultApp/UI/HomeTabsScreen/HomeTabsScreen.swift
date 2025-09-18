import SwiftUI

struct HomeTabsScreen: View {
    let disablePasscodeOnStartOnce: Bool
    let services: ServicesProtocol
    
    @State private var selectedTab: TabItem = .photos
    @State private var didEnteredBackgroundState = false
    @State private var showedPasscodeOnStartOnce = false
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        ZStack {
            Color.contentBack
                .ignoresSafeArea()
            
            if self.didEnteredBackgroundState {
                EnterPasscodeScreen(
                    didEnteredBackgroundState: $didEnteredBackgroundState,
                    services: services
                )
            } else {
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
        }.onChange(of: scenePhase) { newPhase in
            print("PhotosFilesVaultAppApp: scenePhase changed = \(newPhase)")
            
            switch newPhase {
            case .background:
                self.didEnteredBackgroundState = true
                
            case .active:
                break
            default:
                break
            }
        }.onAppear {
            if !self.showedPasscodeOnStartOnce {
                self.showedPasscodeOnStartOnce = true
                
                if !self.disablePasscodeOnStartOnce {
                    self.didEnteredBackgroundState = true
                }
            }
        }
    }
}

#Preview("Light mode") {
    let services = MockedServices.standard()
    
    HomeTabsScreen(
        disablePasscodeOnStartOnce: true,
        services: services
    ).environment(\.colorScheme, .light)
}

#Preview("Dark mode") {
    let services = MockedServices.standard()
    
    HomeTabsScreen(
        disablePasscodeOnStartOnce: true,
        services: services
    ).environment(\.colorScheme, .dark)
}
