import SwiftUI
import Combine
import SwiftUI

struct HomeTabsScreen: View {
    let disablePasscodeOnStartOnce: Bool
    let services: ServicesProtocol
    
    @State private var selectedTab: TabItem = .photos
    @State private var didEnteredBackgroundState = false
    @State private var showedPasscodeOnStartOnce = false
    
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var keyboard = KeyboardResponder()
    
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
                let bottomTabBarHeight: CGFloat = 60.0
                
                TabView(selection: $selectedTab) {
                    PhotoAlbumListScreen(
                        services: services,
                        bottomTabBarHeight: bottomTabBarHeight
                    ).tag(TabItem.photos)
                    
                    SettingsScreen(
                        services: services,
                        bottomTabBarHeight: bottomTabBarHeight
                    ).tag(TabItem.settings)
                }.safeAreaInset(edge: .bottom) {
                    TabBarView(
                        selectedTab: $selectedTab,
                        bottomTabBarHeight: keyboard.currentHeight > 0 ? 0 : bottomTabBarHeight
                    ).if(keyboard.currentHeight > 0) { tabView in
                        tabView.clipped()
                    }
                }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            //print("PhotosFilesVaultAppApp: scenePhase changed = \(newPhase)")
            
            switch newPhase {
            case .background:
                self.didEnteredBackgroundState = true
                
            case .active:
                break
            default:
                break
            }
        }
        .onAppear {
            if !self.showedPasscodeOnStartOnce {
                self.showedPasscodeOnStartOnce = true
                
                if !self.disablePasscodeOnStartOnce {
                    DispatchQueue.main.async {
                        self.didEnteredBackgroundState = true
                    }
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
